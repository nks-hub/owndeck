import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';

class CloudFilesScreen extends StatefulWidget {
  const CloudFilesScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<CloudFilesScreen> createState() => _CloudFilesScreenState();
}

class _CloudFilesScreenState extends State<CloudFilesScreen> {
  List<String> _path = [];
  late Future<List<CloudFile>> _listing = widget.session.cloudFiles(_path);

  void _open(List<String> path) => setState(() {
    _path = List.of(path);
    _listing = widget.session.cloudFiles(_path);
  });

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.chooseCloudFile),
        actions: [
          IconButton(
            tooltip: text.refresh,
            onPressed: () => _open(_path),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: IconButton(
              tooltip: text.parentFolder,
              onPressed: _path.isEmpty
                  ? null
                  : () => _open(_path.sublist(0, _path.length - 1)),
              icon: const Icon(Icons.drive_folder_upload_outlined),
            ),
            title: Text('/${_path.join('/')}'),
          ),
          Expanded(
            child: FutureBuilder<List<CloudFile>>(
              future: _listing,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(errorMessage(snapshot.error!, text)),
                          TextButton(
                            onPressed: () => _open(_path),
                            child: Text(text.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final files = snapshot.data ?? [];
                if (files.isEmpty) {
                  return Center(child: Text(text.noCloudFiles));
                }
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final enabled =
                        file.readable && (file.directory || file.shareable);
                    return ListTile(
                      leading: Icon(
                        file.directory
                            ? Icons.folder_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(file.name),
                      subtitle: enabled || file.directory
                          ? null
                          : Text(text.fileNotShareable),
                      enabled: enabled,
                      onTap: () => file.directory
                          ? _open(file.segments)
                          : Navigator.pop(context, file),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
