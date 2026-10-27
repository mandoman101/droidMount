import 'package:test/test.dart';
import 'package:droidmount/src/models/adb_device_info.dart';
import 'package:droidmount/src/models/android_file_entry.dart';
import 'package:droidmount/src/models/transfer_stats.dart';

void main() {
  group('AdbDeviceInfo Parsing', () {
    test('parses wireless TLS device correctly', () {
      const input =
          'adb-R5CX73K4QQJ-lfvkFq._adb-tls-connect._tcp device product:e2qsqw model:SM_S926U device:e2q transport_id:3262';
      final device = AdbDeviceInfo.fromAdbLine(input);

      expect(device.serial, 'adb-R5CX73K4QQJ-lfvkFq._adb-tls-connect._tcp');
      expect(device.state, 'device');
      expect(device.model, 'SM_S926U');
      expect(device.product, 'e2qsqw');
      expect(device.transportId, 3262);
      expect(device.connectionType, 'wireless_tls');
    });

    test('parses USB device correctly', () {
      const input =
          'R5CX73K4QQJ device usb:1-1 product:e2qsqw model:SM_S926U device:e2q transport_id:3263';
      final device = AdbDeviceInfo.fromAdbLine(input);

      expect(device.serial, 'R5CX73K4QQJ');
      expect(device.state, 'device');
      expect(device.model, 'SM_S926U');
      expect(device.product, 'e2qsqw');
      expect(device.transportId, 3263);
      expect(device.connectionType, 'usb');
    });

    test('equality considers serial and connectionType', () {
      final a = AdbDeviceInfo(
        serial: 'test-serial',
        state: 'device',
        model: 'Test',
        product: 'test',
        transportId: 1,
        connectionType: 'usb',
      );
      final b = AdbDeviceInfo(
        serial: 'test-serial',
        state: 'device',
        model: 'Test',
        product: 'test',
        transportId: 999,
        connectionType: 'usb',
      );
      final c = AdbDeviceInfo(
        serial: 'test-serial',
        state: 'device',
        model: 'Test',
        product: 'test',
        transportId: 1,
        connectionType: 'wireless_tls',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('AndroidFileEntry Parsing', () {
    test('parses directory entry correctly', () {
      const input = 'directory|20480|1793068604|/sdcard/Download';
      final entry = AndroidFileEntry.fromStatLine(input);

      expect(entry.name, 'Download');
      expect(entry.path, '/sdcard/Download');
      expect(entry.isDirectory, true);
      expect(entry.sizeBytes, 20480);
      expect(entry.modifiedEpochSec, 1793068604);
    });

    test('parses file entry correctly', () {
      const input = 'regular file|4194304|1793069000|/sdcard/DCIM/Camera/IMG_001.jpg';
      final entry = AndroidFileEntry.fromStatLine(input);

      expect(entry.name, 'IMG_001.jpg');
      expect(entry.path, '/sdcard/DCIM/Camera/IMG_001.jpg');
      expect(entry.isDirectory, false);
      expect(entry.sizeBytes, 4194304);
      expect(entry.modifiedEpochSec, 1793069000);
    });

    test('handles paths with multiple slashes', () {
      const input = 'regular file|1024|1793000000|/sdcard/Downloads/Very/Nested/Path/file.txt';
      final entry = AndroidFileEntry.fromStatLine(input);

      expect(entry.name, 'file.txt');
      expect(entry.path, '/sdcard/Downloads/Very/Nested/Path/file.txt');
    });
  });

  group('TransferStats Calculations', () {
    test('100% completion at 16.0 MB/s for 4MB in 250ms', () {
      const stats = TransferStats(
        progressBytes: 4 * 1024 * 1024,
        totalBytes: 4 * 1024 * 1024,
        elapsed: Duration(milliseconds: 250),
      );

      expect(stats.percent, 100.0);
      expect(stats.throughputMBps, 16.0);
    });

    test('20% progress for 2MB of 10MB in 500ms', () {
      const stats = TransferStats(
        progressBytes: 2 * 1024 * 1024,
        totalBytes: 10 * 1024 * 1024,
        elapsed: Duration(milliseconds: 500),
      );

      expect(stats.percent, 20.0);
      expect(stats.throughputMBps, 4.0);
    });

    test('handles zero total bytes without division by zero', () {
      const stats = TransferStats(
        progressBytes: 0,
        totalBytes: 0,
        elapsed: Duration.zero,
      );

      expect(stats.percent, 0.0);
      expect(stats.throughputMBps, 0.0);
    });

    test('handles zero elapsed time without division by zero', () {
      const stats = TransferStats(
        progressBytes: 1024,
        totalBytes: 1024,
        elapsed: Duration.zero,
      );

      expect(stats.percent, 100.0);
      expect(stats.throughputMBps, 0.0);
    });
  });
}
