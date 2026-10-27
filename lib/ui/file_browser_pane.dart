import 'package:flutter/material.dart';
import '../src/models/android_file_entry.dart';

class FileBrowserPane extends StatelessWidget {
  final String currentPath;
  final bool loading;
  final List<AndroidFileEntry> entries;
  final ValueChanged<String> onOpenDirectory;
  final ValueChanged<AndroidFileEntry> onDownloadFile;

  const FileBrowserPane({
    super.key,
    required this.currentPath,
    required this.loading,
    required this.entries,
    required this.onOpenDirectory,
    required this.onDownloadFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentPath,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              return ListTile(
                leading: Icon(e.isDirectory ? Icons.folder : Icons.insert_drive_file),
                title: Text(e.name),
                subtitle: Text('${(e.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                onTap: e.isDirectory ? () => onOpenDirectory(e.path) : null,
                trailing: e.isDirectory
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => onDownloadFile(e),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}
