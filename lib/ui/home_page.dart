import 'package:flutter/material.dart';
import '../droidmount_engine.dart';
import '../src/models/adb_device_info.dart';
import '../src/models/android_file_entry.dart';
import '../src/models/transfer_stats.dart';
import '../services/macos_permission_service.dart';
import 'file_browser_pane.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _engine = DroidMountEngine();
  final _perms = MacosPermissionService();
  List<AdbDeviceInfo> _devices = [];
  AdbDeviceInfo? _selectedDevice;
  String _currentPath = '/sdcard';
  List<AndroidFileEntry> _entries = [];
  TransferStats? _stats;
  bool _loading = false;
  String _status = 'Ready';
  bool _axGranted = false;
  bool _srGranted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final perms = await _perms.getPermissionStatus();
      if (!mounted) return;
      setState(() {
        _axGranted = perms['accessibilityGranted'] == true;
        _srGranted = perms['screenRecordingGranted'] == true;
      });
    } catch (_) {}
    await _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _loading = true;
      _status = 'Refreshing devices...';
    });
    try {
      _devices = await _engine.discoverDevices();
      if (_devices.isNotEmpty && _selectedDevice == null) {
        _selectedDevice = _devices.first;
      }
      if (_selectedDevice != null) {
        await _loadPath(_currentPath);
      } else {
        _status = 'No ADB devices connected';
      }
    } catch (e) {
      _status = 'Error refreshing devices: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPath(String path) async {
    setState(() {
      _loading = true;
      _status = 'Loading $path...';
    });
    try {
      _entries = await _engine.browsePath(path, serial: _selectedDevice?.serial);
      _currentPath = path;
      _status = 'Loaded ${_entries.length} items in $path';
    } catch (e) {
      _status = 'Error loading directory: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateUp() async {
    if (_currentPath == '/' || _currentPath == '/sdcard') return;
    final parts = _currentPath.split('/')..removeLast();
    final parentPath = parts.join('/');
    await _loadPath(parentPath.isEmpty ? '/' : parentPath);
  }

  Future<void> _downloadEntry(AndroidFileEntry e) async {
    setState(() => _status = 'Downloading ${e.name}...');
    try {
      await for (final stats in _engine.downloadFile(e.path, '/tmp/${e.name}', serial: _selectedDevice?.serial)) {
        if (mounted) setState(() => _stats = stats);
      }
      if (mounted) setState(() => _status = 'Downloaded ${e.name} to /tmp/${e.name}');
    } catch (err) {
      if (mounted) setState(() => _status = 'Download failed: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DroidMount — Android File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: _navigateUp,
            tooltip: 'Up directory',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: 'Refresh devices',
          ),
          IconButton(
            icon: Icon(Icons.accessibility, color: _axGranted ? Colors.greenAccent : Colors.orangeAccent),
            onPressed: () => _perms.openAccessibilitySettings(),
            tooltip: _axGranted ? 'Accessibility Granted' : 'Grant Accessibility',
          ),
          IconButton(
            icon: Icon(Icons.screen_share, color: _srGranted ? Colors.greenAccent : Colors.orangeAccent),
            onPressed: () => _perms.openScreenRecordingSettings(),
            tooltip: _srGranted ? 'Screen Recording Granted' : 'Grant Screen Recording',
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  leading: Icon(device.connectionType == 'usb' ? Icons.usb : Icons.wifi),
                  title: Text(device.model.isNotEmpty ? device.model : device.serial),
                  subtitle: Text(device.connectionType),
                  selected: _selectedDevice?.serial == device.serial,
                  onTap: () {
                    setState(() => _selectedDevice = device);
                    _loadPath('/sdcard');
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: FileBrowserPane(
              currentPath: _currentPath,
              loading: _loading,
              entries: _entries,
              onOpenDirectory: _loadPath,
              onDownloadFile: _downloadEntry,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.black26,
        child: Row(
          children: [
            Expanded(child: Text(_status)),
            if (_stats != null) ...[
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(value: _stats!.percent / 100),
              ),
              const SizedBox(width: 12),
              Text('${_stats!.percent.toStringAsFixed(1)}% • ${_stats!.throughputMBps.toStringAsFixed(1)} MB/s'),
            ],
          ],
        ),
      ),
    );
  }
}
