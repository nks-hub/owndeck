import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/data/attachment_files.dart';

DeckAttachment attachment({int modified = 10, String name = 'report.txt'}) =>
    DeckAttachment.fromJson({
      'id': 7,
      'cardId': 8,
      'type': 'file',
      'data': name,
      'lastModified': modified,
      'deletedAt': 0,
    });

void main() {
  late Directory root;
  late AttachmentFiles files;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('owndeck-files-test-');
    files = AttachmentFiles(root);
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<List<int>> stagedBytes(
    AttachmentFiles store,
    String account,
    String id,
  ) async {
    final source = await store.readUpload(account, id);
    return source.bytes.expand((chunk) => chunk).toList();
  }

  test('revoked access during a cache write never exposes the file', () async {
    var readable = true;
    await expectLater(
      files.cache(
        'account-a',
        1,
        attachment(),
        [1, 2, 3],
        ensureAccess: () async {
          if (!readable) throw StateError('permission_denied');
          readable = false;
        },
      ),
      throwsStateError,
    );
    expect(await files.cached('account-a', 1, attachment()), isNull);
    final persisted = await root
        .list(recursive: true)
        .where((entry) => entry is File)
        .toList();
    expect(persisted, isEmpty);
  });

  test('staged bytes and metadata survive reopening storage', () async {
    final staged = await files.stage(
      'account-a',
      'report.txt',
      'text/plain',
      Stream.fromIterable([
        [1, 2],
        [3, 4],
      ]),
    );
    files.releaseStage('account-a', staged.id);
    final restarted = AttachmentFiles(root);
    final source = await restarted.readUpload('account-a', staged.id);
    expect(source.filename, 'report.txt');
    expect(source.mime, 'text/plain');
    expect(source.length, 4);
    expect(await source.bytes.expand((chunk) => chunk).toList(), [1, 2, 3, 4]);
  });

  test(
    'identical attachment ids cannot read another account storage',
    () async {
      final staged = await files.stage(
        'account-a',
        'report.txt',
        'text/plain',
        Stream.value([1, 2]),
      );
      await expectLater(
        files.readUpload('account-b', staged.id),
        throwsA(isA<FileSystemException>()),
      );
      await files.cache('account-a', 1, attachment(), [3, 4]);
      expect(await files.cached('account-b', 1, attachment()), isNull);
      final other = await files.cache('account-b', 1, attachment(), [5, 6]);
      expect(await other.readAsBytes(), [5, 6]);
      expect(
        await (await files.cached('account-a', 1, attachment()))!.readAsBytes(),
        [3, 4],
      );
    },
  );

  test(
    'storage rejects traversal ids and keeps server filenames inside its root',
    () async {
      await expectLater(
        files.stage('../escape', 'file.txt', 'text/plain', Stream.value([1])),
        throwsArgumentError,
      );
      await expectLater(
        files.discardUpload('account-a', '../escape'),
        throwsArgumentError,
      );
      expect(await root.list().toList(), isEmpty);
      final cached = await files.cache(
        'account-a',
        1,
        attachment(name: '../../outside.txt'),
        [1],
      );
      final canonicalRoot = (await root.resolveSymbolicLinks()).replaceAll(
        '\\',
        '/',
      );
      final canonicalFile = (await cached.resolveSymbolicLinks()).replaceAll(
        '\\',
        '/',
      );
      expect(canonicalFile.startsWith('$canonicalRoot/'), isTrue);
      expect(await cached.readAsBytes(), [1]);
    },
  );

  test(
    'pruning keeps a stage committed while the retained-id query was pending',
    () async {
      final staged = await files.stage(
        'account-a',
        'report.txt',
        'text/plain',
        Stream.value([1, 2, 3]),
      );
      final querying = Completer<void>();
      final retained = Completer<Set<String>>();
      final pruning = files.pruneUploads('account-a', () {
        querying.complete();
        return retained.future;
      });
      await querying.future;
      files.releaseStage('account-a', staged.id);
      retained.complete({});
      await pruning;
      expect(await stagedBytes(files, 'account-a', staged.id), [1, 2, 3]);
      await files.pruneUploads('account-a', () async => {staged.id});
      expect(await stagedBytes(files, 'account-a', staged.id), [1, 2, 3]);
      await files.pruneUploads('account-a', () async => {});
      await expectLater(
        files.readUpload('account-a', staged.id),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'a failed source leaves no partial upload and does not poison later writes',
    () async {
      Stream<List<int>> broken() async* {
        yield [1, 2];
        throw const FileSystemException('source_unavailable');
      }

      await expectLater(
        files.stage('account-a', 'broken.txt', 'text/plain', broken()),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await Directory('${root.path}/account-a/uploads').list().toList(),
        isEmpty,
      );
      final staged = await files.stage(
        'account-a',
        'ready.txt',
        'text/plain',
        Stream.value([3]),
      );
      expect(await stagedBytes(files, 'account-a', staged.id), [3]);
    },
  );

  test(
    'a file over the upload limit is removed without retaining partial data',
    () async {
      final chunk = Uint8List(1024 * 1024);
      await expectLater(
        files.stage(
          'account-a',
          'large.bin',
          'application/octet-stream',
          Stream.fromIterable(List.generate(65, (_) => chunk)),
        ),
        throwsA(isA<AttachmentTooLarge>()),
      );
      expect(
        await Directory('${root.path}/account-a/uploads').list().toList(),
        isEmpty,
      );
    },
  );

  test(
    'cache versions never overwrite a file held by an existing viewer',
    () async {
      final first = await files.cache('account-a', 1, attachment(), [1, 2]);
      await first.setLastModified(DateTime.utc(2000));
      final reader = await first.open();
      try {
        final second = await AttachmentFiles(
          root,
        ).cache('account-a', 1, attachment(), [3, 4]);
        expect(second.path, isNot(first.path));
        expect(await reader.read(2), [1, 2]);
        expect(await second.readAsBytes(), [3, 4]);
        expect(
          await (await files.cached(
            'account-a',
            1,
            attachment(),
          ))!.readAsBytes(),
          [3, 4],
        );
      } finally {
        await reader.close();
      }
    },
  );

  test(
    'account removal cancels staging and removes the partial file',
    () async {
      final listening = Completer<void>();
      final source = StreamController<List<int>>(onListen: listening.complete);
      final staged = files.stage(
        'account-a',
        'report.txt',
        'text/plain',
        source.stream,
      );
      final rejected = expectLater(staged, throwsStateError);
      await listening.future;
      final removing = files.removeAccount('account-a');
      source.add([1, 2]);
      await source.close();
      await rejected;
      await removing;
      expect(await Directory('${root.path}/account-a').exists(), isFalse);
      await expectLater(
        files.stage(
          'account-a',
          'late.txt',
          'text/plain',
          const Stream.empty(),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'a queued cache write cannot recreate an account after removal starts',
    () async {
      await files.cache('account-a', 1, attachment(), [1]);
      final querying = Completer<void>();
      final retained = Completer<Set<String>>();
      final pruning = files.pruneUploads('account-a', () {
        querying.complete();
        return retained.future;
      });
      await querying.future;
      final late = files.cache('account-a', 1, attachment(), [2]);
      final rejected = expectLater(late, throwsStateError);
      final removing = files.removeAccount('account-a');
      retained.complete({});
      await pruning;
      await rejected;
      await removing;
      expect(await Directory('${root.path}/account-a').exists(), isFalse);
    },
  );

  test(
    'card and board pruning remove stale downloads without touching another account',
    () async {
      await files.cache('account-a', 1, attachment(), [1]);
      await files.cache('account-a', 1, attachment(modified: 11), [2]);
      await files.cache('account-b', 1, attachment(), [3]);
      await files.pruneCard(
        'account-a',
        1,
        8,
        () async => [attachment(modified: 11)],
      );
      expect(await files.cached('account-a', 1, attachment()), isNull);
      expect(
        await (await files.cached(
          'account-a',
          1,
          attachment(modified: 11),
        ))!.readAsBytes(),
        [2],
      );
      await files.pruneBoards('account-a', () async => {});
      expect(
        await files.cached('account-a', 1, attachment(modified: 11)),
        isNull,
      );
      expect(
        await (await files.cached('account-b', 1, attachment()))!.readAsBytes(),
        [3],
      );
    },
  );

  test(
    'staged file corruption is detected after restarting the storage',
    () async {
      final staged = await files.stage(
        'account-a',
        'report.txt',
        'text/plain',
        Stream.value([1, 2]),
      );
      final data = File('${root.path}/account-a/uploads/${staged.id}/data');
      await data.writeAsString('different length', encoding: utf8);
      await expectLater(
        AttachmentFiles(root).readUpload('account-a', staged.id),
        throwsStateError,
      );
    },
  );

  test(
    'queued pruning reads current metadata after earlier disk work finishes',
    () async {
      await files.cache('account-a', 1, attachment(), [1]);
      await files.cache('account-a', 1, attachment(modified: 11), [2]);
      await files.cache('account-a', 2, attachment(), [3]);
      final querying = Completer<void>();
      final release = Completer<Set<String>>();
      final blocker = files.pruneUploads('account-a', () {
        querying.complete();
        return release.future;
      });
      await querying.future;
      var currentAttachments = [attachment()];
      var currentBoards = {1};
      final cardPrune = files.pruneCard(
        'account-a',
        1,
        8,
        () async => currentAttachments,
      );
      final boardPrune = files.pruneBoards(
        'account-a',
        () async => currentBoards,
      );
      currentAttachments = [attachment(modified: 11)];
      currentBoards = {1, 2};
      release.complete({});
      await blocker;
      await cardPrune;
      await boardPrune;
      expect(await files.cached('account-a', 1, attachment()), isNull);
      expect(
        await (await files.cached(
          'account-a',
          1,
          attachment(modified: 11),
        ))!.readAsBytes(),
        [2],
      );
      expect(
        await (await files.cached('account-a', 2, attachment()))!.readAsBytes(),
        [3],
      );
    },
  );
}
