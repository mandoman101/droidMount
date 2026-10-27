import 'package:meta/meta.dart';

@immutable
class AdbDeviceInfo {
  final String serial;
  final String state;
  final String model;
  final String product;
  final int transportId;
  final String connectionType;

  const AdbDeviceInfo({
    required this.serial,
    required this.state,
    required this.model,
    required this.product,
    required this.transportId,
    required this.connectionType,
  });

  factory AdbDeviceInfo.fromAdbLine(String line) {
    final parts = line.split(RegExp(r'\s+'));
    final serial = parts[0];
    final state = parts[1];
    final kv = <String, String>{};
    for (final p in parts.skip(2)) {
      final idx = p.indexOf(':');
      if (idx > 0) kv[p.substring(0, idx)] = p.substring(idx + 1);
    }
    return AdbDeviceInfo(
      serial: serial,
      state: state,
      model: kv['model'] ?? '',
      product: kv['product'] ?? '',
      transportId: int.tryParse(kv['transport_id'] ?? '0') ?? 0,
      connectionType: line.contains('usb:') ? 'usb' : 'wireless_tls',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdbDeviceInfo && serial == other.serial && connectionType == other.connectionType;
  @override
  int get hashCode => Object.hash(serial, connectionType);
}