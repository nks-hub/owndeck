import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:uuid/uuid.dart';

final class AttachmentTooLarge implements Exception {
  const AttachmentTooLarge();
}

final class StagedAttachmentFile {
  const StagedAttachmentFile(this.id, this.name, this.mime, this.length);
  final String id;
  final String name;
  final String mime;
  final int length;
}

String safeAttachmentName(String name) {
  final clean = name
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f\x7f]'), '_')
      .trim();
  var result = '';
  for (final rune in clean.runes) {
    final next = '$result${String.fromCharCode(rune)}';
    if (utf8.encode(next).length > 120) break;
    result = next;
  }
  return result.isEmpty || result == '.' || result == '..'
      ? 'attachment.bin'
      : result;
}

final class AttachmentFiles {
  AttachmentFiles(this.root);
  final Directory root;
  final _removed = <String>{};
  final _staging = <(String, String)>{};
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String _id(String value) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value)) {
      throw ArgumentError('invalid_storage_id');
    }
    return value;
  }

  Directory _account(String accountId) =>
      Directory('${root.path}/${_id(accountId)}');
  Directory _upload(String accountId, String id) =>
      Directory('${_account(accountId).path}/uploads/${_id(id)}');
  void _available(String accountId) {
    if (_removed.contains(accountId)) throw StateError('account_unavailable');
  }

  Future<StagedAttachmentFile> stage(
    String accountId,
    String name,
    String mime,
    Stream<List<int>> bytes,
  ) => _serial(() async {
    _available(accountId);
    final id = const Uuid().v4();
    _staging.add((accountId, id));
    final folder = _upload(accountId, id);
    final file = File('${folder.path}/data');
    RandomAccessFile? handle;
    var length = 0;
    try {
      await folder.create(recursive: true);
      handle = await file.open(mode: FileMode.write);
      await for (final chunk in bytes.timeout(const Duration(seconds: 30))) {
        _available(accountId);
        length += chunk.length;
        if (length > attachmentMaxBytes) throw const AttachmentTooLarge();
        await handle.writeFrom(chunk);
      }
      await handle.flush();
      await handle.close();
      handle = null;
      _available(accountId);
      final staged = StagedAttachmentFile(
        id,
        safeAttachmentName(name),
        mime,
        length,
      );
      await File('${folder.path}/meta.json').writeAsString(
        jsonEncode({'name': staged.name, 'mime': mime, 'length': length}),
        flush: true,
      );
      return staged;
    } catch (_) {
      _staging.remove((accountId, id));
      await handle?.close();
      if (await folder.exists()) await folder.delete(recursive: true);
      rethrow;
    }
  });

  void releaseStage(String accountId, String id) =>
      _staging.remove((accountId, id));

  Future<AttachmentUploadSource> readUpload(String accountId, String id) =>
      _serial(() async {
        _available(accountId);
        final folder = _upload(accountId, id);
        final metadata = object(
          jsonDecode(await File('${folder.path}/meta.json').readAsString()),
        );
        final file = File('${folder.path}/data');
        final length = await file.length();
        if (length != intField(metadata, 'length') ||
            length > attachmentMaxBytes) {
          throw StateError('staged_file_changed');
        }
        return AttachmentUploadSource(
          filename: stringField(metadata, 'name'),
          mime: stringField(metadata, 'mime'),
          length: length,
          bytes: file.openRead(),
        );
      });

  Future<void> discardUpload(String accountId, String id) => _serial(() async {
    final folder = _upload(accountId, id);
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  Future<void> pruneUploads(
    String accountId,
    Future<Set<String>> Function() retained,
  ) => _serial(() async {
    _available(accountId);
    final staging = _staging
        .where((entry) => entry.$1 == accountId)
        .map((entry) => entry.$2)
        .toSet();
    final keep = await retained();
    final folder = Directory('${_account(accountId).path}/uploads');
    if (!await folder.exists()) return;
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final id = entry.uri.pathSegments.where((part) => part.isNotEmpty).last;
      if (!keep.contains(id) && !staging.contains(id)) {
        await entry.delete(recursive: true);
      }
    }
  });

  Directory _cache(String accountId, int boardId, DeckAttachment attachment) {
    if (boardId <= 0 ||
        attachment.id <= 0 ||
        attachment.cardId <= 0 ||
        !attachment.supported) {
      throw ArgumentError('invalid_cache_identity');
    }
    return Directory(
      '${_account(accountId).path}/downloads/$boardId/${attachment.cardId}/${attachment.type}-${attachment.id}-${attachment.modified}',
    );
  }

  Future<File?> cached(
    String accountId,
    int boardId,
    DeckAttachment attachment,
  ) => _serial(() async {
    _available(accountId);
    final folder = _cache(accountId, boardId, attachment);
    if (!await folder.exists()) return null;
    final candidates = <(File, DateTime)>[];
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is! Directory || entry.path.endsWith('.partial')) continue;
      final file = File('${entry.path}/${safeAttachmentName(attachment.name)}');
      if (await file.exists()) {
        candidates.add((file, await file.lastModified()));
      }
    }
    candidates.sort((a, b) => b.$2.compareTo(a.$2));
    final file = candidates.firstOrNull?.$1;
    await file?.setLastModified(DateTime.now());
    return file;
  });

  Future<File> cache(
    String accountId,
    int boardId,
    DeckAttachment attachment,
    List<int> bytes,
  ) => _serial(() async {
    _available(accountId);
    if (bytes.length > attachmentMaxBytes) throw const AttachmentTooLarge();
    final parent = _cache(accountId, boardId, attachment);
    final id = const Uuid().v4();
    final temporary = Directory('${parent.path}/$id.partial');
    final destination = Directory('${parent.path}/$id');
    await temporary.create(recursive: true);
    final name = safeAttachmentName(attachment.name);
    try {
      await File('${temporary.path}/$name').writeAsBytes(bytes, flush: true);
      _available(accountId);
      // Each version has its own directory; open viewers never hold a file we replace.
      await temporary.rename(destination.path);
      final result = File('${destination.path}/$name');
      await _trim(accountId, result.path);
      return result;
    } finally {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    }
  });

  Future<void> _trim(String accountId, String keep) async {
    final downloads = Directory('${_account(accountId).path}/downloads');
    final files = <(File, FileStat)>[];
    var total = 0;
    await for (final entry in downloads.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entry is! File) continue;
      final stat = await entry.stat();
      total += stat.size;
      files.add((entry, stat));
    }
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    var count = files.length;
    for (final (file, stat) in files) {
      if (total <= 200 * 1024 * 1024 && count <= 1000) break;
      if (file.path == keep) continue;
      await file.delete();
      total -= stat.size;
      count--;
    }
  }

  Future<void> forgetCached(
    String accountId,
    int boardId,
    DeckAttachment attachment,
  ) => _serial(() async {
    final folder = _cache(accountId, boardId, attachment);
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  Future<void> pruneCard(
    String accountId,
    int boardId,
    int cardId,
    Future<List<DeckAttachment>> Function() retained,
  ) => _serial(() async {
    _available(accountId);
    if (boardId <= 0 || cardId <= 0) {
      throw ArgumentError('invalid_cache_identity');
    }
    final attachments = await retained();
    final keep = {
      for (final item in attachments)
        if (item.deletedAt == 0) '${item.type}-${item.id}-${item.modified}',
    };
    final folder = Directory(
      '${_account(accountId).path}/downloads/$boardId/$cardId',
    );
    if (!await folder.exists()) return;
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final key = entry.uri.pathSegments.where((part) => part.isNotEmpty).last;
      if (!keep.contains(key)) await entry.delete(recursive: true);
    }
  });

  Future<void> pruneBoards(
    String accountId,
    Future<Set<int>> Function() retained,
  ) => _serial(() async {
    _available(accountId);
    final keep = await retained();
    final folder = Directory('${_account(accountId).path}/downloads');
    if (!await folder.exists()) return;
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final id = int.tryParse(
        entry.uri.pathSegments.where((part) => part.isNotEmpty).last,
      );
      if (!keep.contains(id)) await entry.delete(recursive: true);
    }
  });

  Future<void> removeAccount(String accountId) {
    _removed.add(accountId);
    return _serial(() async {
      final folder = _account(accountId);
      if (await folder.exists()) await folder.delete(recursive: true);
    });
  }

  Future<void> pruneAccounts(Set<String> keep) => _serial(() async {
    if (!await root.exists()) return;
    await for (final entry in root.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final id = entry.uri.pathSegments.where((part) => part.isNotEmpty).last;
      if (!keep.contains(id)) {
        _removed.add(id);
        await entry.delete(recursive: true);
      }
    }
  });
}
