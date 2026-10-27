import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'src/models/adb_device_info.dart';
import 'src/models/android_file_entry.dart';
import 'src/models/transfer_stats.dart';

/// Core DroidMount engine. Orchestrates ADB device discovery, browsing,
/// and file transfers via the ADB sync protocol over adb push/pull.
class DroidMountEngine {
  /// Path to adb binary. Resolved at runtime from ANDROID_HOME env or default SDK location.
  static String get adbPath {
    final env = Platform.environment['ANDROID_HOME'];
    if (env != null && env.isNotEmpty) {
      return path.join(env, 'platform-tools', 'adb');
    }
    return path.join(
      Platform.environment['HOME'] ?? '',
      'Library',
      'Android',
      'sdk',
      'platform-tools',
      'adb',
    );
  }

  // --- Device Discovery ---

  /// Discover and enumerate connected devices (USB and wireless TLS).
  /// Returns a sorted list with USB devices first, then wireless.
  Future<List<AdbDeviceInfo>> discoverDevices() async {
    final adb = await _runAdb(['devices', '-l']);
    if (adb.exitCode != 0) {
      throw Exception('Failed to run adb devices: ${adb.stderr}');
    }

    final lines = adb.stdout.toString().split('\n').skip(1).where((l) => l.trim().isNotEmpty);
    final usbDevices = <AdbDeviceInfo>[];
    final wirelessDevices = <AdbDeviceInfo>[];

    for (final line in lines) {
      try {
        final device = AdbDeviceInfo.fromAdbLine(line);
        if (device.state == 'device') {
          if (device.connectionType == 'usb') {
            usbDevices.add(device);
          } else {
            wirelessDevices.add(device);
          }
        }
      } catch (e) {
        // Skip unparseable lines
      }
    }

    usbDevices.sort((a, b) => a.serial.compareTo(b.serial));
    wirelessDevices.sort((a, b) => a.serial.compareTo(b.serial));
    return [...usbDevices, ...wirelessDevices];
  }

  /// Connect to a wireless device via mdns name.
  Future<bool> connectWireless(String mdnsName) async {
    final result = await _runAdb(['connect', mdnsName]);
    if (result.exitCode != 0) {
      return false;
    }
    final output = result.stdout.toString().trim();
    return !output.contains('failed') && !output.contains('refused');
  }

  /// Disconnect a wireless device.
  Future<bool> disconnectWireless(String mdnsName) async {
    final result = await _runAdb(['disconnect', mdnsName]);
    return result.exitCode == 0;
  }

  // --- Browsing ---

  /// Browse files at a path on the connected device.
  /// Uses `stat -c` for typed entries. Default target is `/sdcard`.
  Future<List<AndroidFileEntry>> browsePath(
    String androidPath, {
    String? serial,
  }) async {
    final adbCmd = ['-s', serial ?? '', 'shell', 'stat', '-c', r'%F|%s|%Y|%n', androidPath];
    final adb = await _runAdb(adbCmd);
    if (adb.exitCode != 0) {
      throw Exception('Failed to browse $androidPath: ${adb.stderr}');
    }

    final lines = adb.stdout.toString().split('\n').where((l) => l.trim().isNotEmpty);
    final entries = <AndroidFileEntry>[];
    for (final line in lines) {
      try {
        entries.add(AndroidFileEntry.fromStatLine(line));
      } catch (e) {
        // Silently skip invalid entries
      }
    }

    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });

    return entries;
  }

  /// Recursively list all entries under [androidPath].
  Future<List<AndroidFileEntry>> listRecursively(
    String androidPath, {
    String? serial,
    int maxDepth = 10,
  }) async {
    final allEntries = <AndroidFileEntry>[];
    await _listRecursive(androidPath, serial, allEntries, 0, maxDepth);
    return allEntries;
  }

  Future<void> _listRecursive(
    String dirPath,
    String? serial,
    List<AndroidFileEntry> out,
    int depth,
    int maxDepth,
  ) async {
    if (depth > maxDepth) return;

    final entries = await browsePath(dirPath, serial: serial);
    for (final entry in entries) {
      out.add(entry);
      if (entry.isDirectory) {
        await _listRecursive(entry.path, serial, out, depth + 1, maxDepth);
      }
    }
  }

  // --- File Transfer ---

  /// Download a file from Android to the local machine.
  /// Yields [TransferStats] during transfer for progress tracking.
  Stream<TransferStats> downloadFile(
    String androidPath,
    String localDestPath, {
    String? serial,
  }) async* {
    // Get file size first via stat
    final statOutput = await _runAdb([
      '-s', serial ?? '',
      'shell', 'stat', '-c', r'%s', androidPath,
    ]);
    if (statOutput.exitCode != 0) {
      throw Exception('Cannot stat $androidPath: ${statOutput.stderr}');
    }
    final fileSize = int.tryParse(statOutput.stdout.toString().trim()) ?? 0;

    final startTime = DateTime.now();
    int bytesTransferred = 0;

    try {
      // Use adb pull with progress tracking
      final process = await Process.start(
        adbPath,
        ['-s', serial ?? '', 'pull', androidPath, localDestPath],
        runInShell: true,
      );

      final stdoutLines = <String>[];
      await for (final chunk in process.stdout.transform(utf8.decoder)) {
        stdoutLines.add(chunk);
        // adb pull prints "copying: <path> [<size> bytes]" lines
        for (final line in chunk.split('\n')) {
          final bytesMatch = RegExp(r'\[(\d+)\s*bytes\]').firstMatch(line);
          if (bytesMatch != null) {
            bytesTransferred = int.tryParse(bytesMatch.group(1) ?? '0') ?? 0;
            final elapsed = DateTime.now().difference(startTime);
            yield TransferStats(
              progressBytes: bytesTransferred,
              totalBytes: fileSize,
              elapsed: elapsed,
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Upload a local file to Android.
  /// Yields [TransferStats] during transfer for progress tracking.
  Stream<TransferStats> uploadFile(
    String localPath,
    String remotePath, {
    String? serial,
  }) async* {
    final file = File(localPath);
    final fileSize = await file.length();
    final startTime = DateTime.now();
    int bytesTransferred = 0;

    try {
      final process = await Process.start(
        adbPath,
        ['-s', serial ?? '', 'push', localPath, remotePath],
        runInShell: true,
      );

      await for (final chunk in process.stdout.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          final bytesMatch = RegExp(r'\[(\d+)\s*bytes\]').firstMatch(line);
          if (bytesMatch != null) {
            bytesTransferred = int.tryParse(bytesMatch.group(1) ?? '0') ?? 0;
            final elapsed = DateTime.now().difference(startTime);
            yield TransferStats(
              progressBytes: bytesTransferred,
              totalBytes: fileSize,
              elapsed: elapsed,
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Download an entire directory from Android.
  Stream<TransferStats> downloadDirectory(
    String androidDirPath,
    String localDestDir, {
    String? serial,
  }) async* {
    final entries = await browsePath(androidDirPath, serial: serial);
    for (final entry in entries) {
      if (entry.isDirectory) {
        final remoteSub = '$androidDirPath/${entry.name}';
        final localSub = path.join(localDestDir, entry.name);
        Directory(localSub).createSync(recursive: true);
        yield* downloadDirectory(remoteSub, localSub, serial: serial);
      } else {
        final localFile = path.join(localDestDir, entry.name);
        yield* downloadFile(entry.path, localFile, serial: serial);
      }
    }
  }

  // --- Utility ---

  /// Get the home directory on the connected device.
  Future<String> getHomeDirectory({String? serial}) async {
    return '/sdcard';
  }

  /// Execute a raw ADB shell command.
  Future<ProcessResult> runShellCommand(
    String command, {
    String? serial,
  }) async {
    final adbCmd = ['-s', serial ?? '', 'shell', command];
    return _runAdb(adbCmd);
  }

  /// Get device properties.
  Future<Map<String, String>> getDeviceProperties({String? serial}) async {
    final props = [
      'ro.product.model',
      'ro.product.name',
      'ro.build.version.release',
      'ro.build.version.sdk',
      'ro.build.fingerprint',
    ];
    final result = <String, String>{};
    for (final prop in props) {
      final adb = await _runAdb([
        '-s', serial ?? '',
        'shell', 'getprop', prop,
      ]);
      if (adb.exitCode == 0) {
        result[prop] = adb.stdout.toString().trim();
      }
    }
    return result;
  }

  void dispose() {
    // No persistent resources to clean up
  }

  /// Internal helper: run adb with the configured binary.
  Future<ProcessResult> _runAdb(List<String> args) async {
    final adbBin = adbPath;
    if (!File(adbBin).existsSync()) {
      throw Exception('ADB not found at $adbBin. Set ANDROID_HOME env var.');
    }
    return Process.run(adbBin, args);
  }
}
