import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_state.dart';

class OpenClawProcessService {
 Process? _process;

 final _statusController = StreamController<OpenClawStatus>.broadcast();
 final _logController = StreamController<String>.broadcast();

 Stream<OpenClawStatus> get statusStream => _statusController.stream;
 Stream<String> get logStream => _logController.stream;

 bool get isRunning => _process != null;

 Future<void> start({
 required String executable,
 required List<String> arguments,
 String? workingDirectory,
 Map<String, String>? environment,
 }) async {
 if (_process != null) {
 _logController.add('⚠️ Process already running');
 return;
 }

 _statusController.add(OpenClawStatus.starting);
 _logController.add('🚀 Launching...');
 _logController.add('   Executable: $executable');
 _logController.add('   Arguments: ${arguments.join(' ')}');
 _logController.add('   Work Dir: ${workingDirectory ?? "(none)"}');

 try {
 final process = await Process.start(
 executable,
 arguments,
 workingDirectory: workingDirectory,
 environment: environment,
 runInShell: false,
 );

 _process = process;
 _statusController.add(OpenClawStatus.running);

 _logController.add('✅ OpenClaw started');

 process.stdout
 .transform(utf8.decoder)
 .transform(const LineSplitter())
 .listen((line) {
 _logController.add('[OUT] $line');
 });

 process.stderr
 .transform(utf8.decoder)
 .transform(const LineSplitter())
 .listen((line) {
 _logController.add('[ERR] $line');
 });

 process.exitCode.then((code) {
 _logController.add('❌ Process exited with code $code');
 _process = null;

 if (code == 0) {
 _statusController.add(OpenClawStatus.stopped);
 } else {
 _statusController.add(OpenClawStatus.error);
 }
 });
 } catch (e) {
 _logController.add('🔥 Failed to start process: $e');
 _process = null;
 _statusController.add(OpenClawStatus.error);
 }
 }

 Future<void> stop() async {
 final process = _process;
 if (process == null) {
 _logController.add('⚠️ No process to stop');
 return;
 }

 _statusController.add(OpenClawStatus.stopping);
 _logController.add('🛑 Stopping OpenClaw...');

 process.kill(ProcessSignal.sigterm);

 try {
 await process.exitCode.timeout(const Duration(seconds: 5));
 } catch (_) {
 _logController.add('⚠️ Force killing process...');
 process.kill(ProcessSignal.sigkill);
 }

 _process = null;
 _statusController.add(OpenClawStatus.stopped);
 }

 Future<void> restart({
 required String executable,
 required List<String> arguments,
 String? workingDirectory,
 Map<String, String>? environment,
 }) async {
 _logController.add('🔄 Restarting OpenClaw...');
 await stop();

 await start(
 executable: executable,
 arguments: arguments,
 workingDirectory: workingDirectory,
 environment: environment,
 );
 }

 Future<void> dispose() async {
 await stop();
 await _statusController.close();
 await _logController.close();
 }
}