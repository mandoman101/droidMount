import 'package:meta/meta.dart';

@immutable
class AndroidFileEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int sizeBytes;
  final int modifiedEpochSec;

  const AndroidFileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.sizeBytes,
    required this.modifiedEpochSec,
  });

  factory AndroidFileEntry.fromStatLine(String line) {
    final parts = line.split('|');
    final fileType = parts[0].trim();
    final size = int.tryParse(parts[1]) ?? 0;
    final mtime = int.tryParse(parts[2]) ?? 0;
    final path = parts[3].trim();
    final name = path.split('/').last;
    return AndroidFileEntry(
      name: name,
      path: path,
      isDirectory: fileType == 'directory',
      sizeBytes: size,
      modifiedEpochSec: mtime,
    );
  }
}