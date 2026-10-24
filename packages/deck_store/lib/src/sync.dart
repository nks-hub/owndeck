import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'database.dart';

part 'structure_sync.dart';
part 'card_actions_sync.dart';
part 'comments_sync.dart';
part 'board_metadata_sync.dart';
part 'attachments_sync.dart';

final class AttachmentUploadSource {
  const AttachmentUploadSource({
    required this.filename,
    required this.mime,
    required this.length,
    required this.bytes,
  });
  final String filename;
  final String mime;
  final int length;
  final Stream<List<int>> bytes;
}

final class DeckSync {
  DeckSync(this.database, this.account, this.client, {this.readUpload});
  final Future<AttachmentUploadSource> Function(String id)? readUpload;
  final DeckDatabase database;
  final StoredAccount account;
  final DeckClient client;
  final String _owner = const Uuid().v4();
  Future<void>? _running;
  bool _closed = false;
  final _cancelled = Completer<void>();

  void close() {
    _closed = true;
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  Future<void> run() {
    if (_closed) return Future.value();
    final running = _running;
    if (running != null) return running;
    final next = _run();
    _running = next;
    return next.whenComplete(() {
      _running = null;
    });
  }

  Future<void> _run() async {
    if (!await database.acquireLease(account, _owner)) return;
    try {
      await database.recoverWrites(account, _owner);
      final attemptedReadbacks = <String>{};
      while (!_closed) {
        final applied = (await database.writesFor(account.id))
            .where(
              (w) => w.state == 'applied' && !attemptedReadbacks.contains(w.id),
            )
            .firstOrNull;
        if (applied != null) {
          final resolved = await database.resolveWrite(applied);
          attemptedReadbacks.add(applied.id);
          if (resolved != null) {
            if (attachmentKinds.contains(resolved.kind)) {
              await _finishAttachment(resolved);
            } else if (boardMetadataKinds.contains(resolved.kind)) {
              await _finishBoardMetadata(resolved);
            } else {
              await _finishApplied(resolved);
            }
          }
          continue;
        }
        PendingWrite? queued;
        for (final candidate in (await database.writesFor(
          account.id,
        )).where((w) => w.state == 'queued')) {
          if (await database.dependencyUnavailable(candidate)) {
            if (await database.startWrite(account, _owner, candidate.id)) {
              await database.markWrite(
                account,
                _owner,
                candidate.id,
                'blocked',
                error: 'dependency_unavailable',
              );
            }
            continue;
          }
          if (await database.hasEarlierCardWrite(candidate)) continue;
          queued = await database.resolveWrite(candidate);
          if (queued != null) break;
        }
        if (queued == null) return;
        if (boardMetadataKinds.contains(queued.kind)) {
          if (!await _sendBoardMetadata(queued)) return;
          continue;
        }
        if (queued.kind.endsWith('Board') || queued.kind.endsWith('Stack')) {
          if (!await _sendStructure(queued)) return;
          continue;
        }
        // A successful read establishes reachability before changing queued to sending.
        DeckResponse boardResponse;
        try {
          boardResponse = await client.rest('GET', [
            'boards',
            '${queued.boardId}',
          ]);
        } on DeckException catch (error) {
          if (error.status != 403 && error.status != 404) rethrow;
          if (await database.startWrite(account, _owner, queued.id)) {
            await database.markWrite(
              account,
              _owner,
              queued.id,
              'blocked',
              error: error.code,
            );
          }
          continue;
        }
        final board = DeckBoard.fromJson(object(boardResponse.data));
        if (_closed || !await database.acquireLease(account, _owner)) return;
        if (!await database.startWrite(account, _owner, queued.id)) continue;
        final allowed = queued.kind.endsWith('Comment')
            ? board.permissions.read && board.deletedAt == 0
            : board.permissions.edit && !board.archived && board.deletedAt == 0;
        if (!allowed) {
          await database.markWrite(
            account,
            _owner,
            queued.id,
            'blocked',
            error: 'permission_denied',
          );
          continue;
        }
        final shouldContinue = attachmentKinds.contains(queued.kind)
            ? await _sendAttachment(queued)
            : queued.kind.endsWith('Comment')
            ? await _sendComment(queued)
            : {'createCard', 'updateCard'}.contains(queued.kind)
            ? await _send(queued)
            : await _sendCardAction(queued);
        if (!shouldContinue) return;
      }
    } finally {
      await database.releaseLease(account.id, _owner);
    }
  }

  Future<bool> _send(PendingWrite write) async {
    var mutationStarted = false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final path = [
        'boards',
        '${write.boardId}',
        'stacks',
        '${write.stackId}',
        'cards',
      ];
      DeckResponse response;
      if (write.kind == 'createCard') {
        if (_closed || !await database.ownsLease(account, _owner)) return false;
        mutationStarted = true;
        response = await client.rest(
          'POST',
          path,
          body: {
            for (final key in [
              'title',
              'description',
              'type',
              'order',
              'duedate',
              'startdate',
              'color',
            ])
              if (proposal.containsKey(key)) key: proposal[key],
          },
        );
      } else if (write.kind == 'updateCard') {
        path.add('${write.cardId}');
        final current = DeckCard.fromJson(
          object((await client.rest('GET', path)).data),
        );
        final base = object(jsonDecode(write.base!));
        final conflict =
            current.stackId != write.stackId ||
            proposal.keys.any(
              (key) =>
                  jsonEncode(current.raw[key]) != jsonEncode(base[key]) &&
                  jsonEncode(current.raw[key]) != jsonEncode(proposal[key]),
            );
        if (conflict) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'conflict',
            error: 'concurrent_edit',
            remote: current.raw,
          );
          return true;
        }
        if (_closed || !await database.acquireLease(account, _owner)) {
          return false;
        }
        mutationStarted = true;
        response = await client.rest(
          'PUT',
          path,
          body: current.updateBody(proposal),
        );
      } else {
        await database.markWrite(
          account,
          _owner,
          write.id,
          'blocked',
          error: 'unsupported_operation',
        );
        return true;
      }
      final card = DeckCard.fromJson(object(response.data));
      await database.confirmCard(account, _owner, write, card);
      return true;
    } on DeckException catch (error) {
      final uncertain = mutationStarted && error.uncertain;
      final retryableRead =
          !mutationStarted &&
          (error.code == 'transport_failed' || error.code == 'timeout');
      final retryableStatus = error.status == 401 || error.status == 429;
      await database.markWrite(
        account,
        _owner,
        write.id,
        uncertain
            ? 'uncertain'
            : retryableRead || retryableStatus
            ? 'queued'
            : 'blocked',
        error: error.code,
      );
      if (retryableRead || retryableStatus) rethrow;
      return !uncertain;
    } on FormatException {
      await database.markWrite(
        account,
        _owner,
        write.id,
        mutationStarted ? 'uncertain' : 'blocked',
        error: 'invalid_response',
      );
      return false;
    }
  }
}
