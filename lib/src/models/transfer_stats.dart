import 'package:meta/meta.dart';

@immutable
class TransferStats {
  final int progressBytes;
  final int totalBytes;
  final Duration elapsed;

  const TransferStats({required this.progressBytes, required this.totalBytes, required this.elapsed});

  double get percent => totalBytes == 0 ? 0.0 : (progressBytes / totalBytes * 100);
  double get throughputMBps => elapsed.inMilliseconds == 0
      ? 0.0
      : (progressBytes / (1024 * 1024)) / (elapsed.inMilliseconds / 1000);
}