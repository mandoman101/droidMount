import 'package:flutter/services.dart';

class MacosPermissionService {
 static const MethodChannel _channel =
 MethodChannel('com.mandoman.openclawdesktop/permissions');

 Future<Map<String, dynamic>> getPermissionStatus() async {
 final result = await _channel.invokeMethod<dynamic>('getPermissionStatus');
 return Map<String, dynamic>.from(result as Map);
 }

 Future<bool> requestAccessibility() async {
 final result = await _channel.invokeMethod<bool>('requestAccessibility');
 return result ?? false;
 }

 Future<bool> requestScreenRecording() async {
 final result = await _channel.invokeMethod<bool>('requestScreenRecording');
 return result ?? false;
 }

 Future<void> openAccessibilitySettings() async {
 await _channel.invokeMethod('openAccessibilitySettings');
 }

 Future<void> openScreenRecordingSettings() async {
 await _channel.invokeMethod('openScreenRecordingSettings');
 }
}
