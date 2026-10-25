import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/widgets.dart';
import 'attachment_files.dart';

part 'session_attachments.dart';

final class DeckSession extends ChangeNotifier with WidgetsBindingObserver {
  DeckSession(
    this.database,
    this.account,
    this.client, {
    Future<AttachmentFiles> Function()? files,
    this.onAuthenticationRequired,
    Duration pollInterval = const Duration(seconds: 30),
  }) : _files = files {
    if (pollInterval <= Duration.zero) {
      throw ArgumentError('invalid_poll_interval');
    }
    sync = DeckSync(
      database,
      account,
      client,
      readUpload: files == null
          ? null
          : (id) async => (await files()).readUpload(account.id, id),
    );
    userId = account.userId;
    if (account.capabilities != null) {
      capabilities = DeckCapabilities.fromJson(
        object(jsonDecode(account.capabilities!)),
      );
    }
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _connection = Connectivity().onConnectivityChanged.listen(
      (_) => _refreshVisible(),
      onError: (Object _) {
        // Connectivity is advisory; manual refresh and foreground polling still work.
      },
    );
    _pending = database
        .watchWrites(account.id)
        .listen(
          (writes) {
            _hasPending = writes.any(
              (write) => write.state == 'queued' || write.state == 'applied',
            );
          },
          onError: (Object error) {
            if (!_disposed) {
              _errors['boards'] = error;
              notifyListeners();
            }
          },
        );
    _timer = Timer.periodic(pollInterval, (_) {
      if (_foreground &&
          (_openBoards.isNotEmpty || _hasPending) &&
          !(client.retryUntil?.isAfter(DateTime.now().toUtc()) ?? false)) {
        _refreshVisible();
      }
    });
  }
  final DeckDatabase database;
  final StoredAccount account;
  final DeckClient client;
  final Future<AttachmentFiles> Function()? _files;
  final Future<void> Function()? onAuthenticationRequired;

  Future<void> _prepareRequest() async {
    final current = await database.account(account.id);
    if (_disposed ||
        current == null ||
        current.state != 'active' ||
        current.generation != account.generation) {
      throw StateError('account_unavailable');
    }
    client.deferUntil(current.syncNotBefore);
  }

  Future<void> _persistBackoff() async {
    if (!_disposed && client.retryUntil != null) {
      await database.deferSync(account, client.retryUntil);
    }
  }

  Future<void> _authenticationFailed(DeckException error) async {
    if (!_disposed && error.status == 401) {
      await onAuthenticationRequired?.call();
    }
  }

  Future<void> _revokeBoardAccess(int boardId, DeckException error) async {
    if (_disposed) return;
    final changed = await database.revokeBoardAccess(
      account,
      boardId,
      reason: error.code,
    );
    if (changed && _files != null && !_disposed) {
      await _cleanAttachmentFiles();
    }
  }

  Future<DeckBoard> _readAccessibleBoard(int boardId) async {
    try {
      final board = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '$boardId'])).data),
      );
      if (board.id != boardId) {
        throw const DeckException('invalid_response');
      }
      if (!board.permissions.read) {
        throw const DeckException('permission_denied', status: 403);
      }
      return board;
    } on DeckException catch (error) {
      if (error.status == 403 || error.status == 404) {
        await _revokeBoardAccess(boardId, error);
      }
      rethrow;
    }
  }

  /// Reads stay bound to this account; mutations belong in the durable outbox.
  Future<T> readServer<T>(
    Future<T> Function(DeckClient client) operation,
  ) async {
    await _prepareRequest();
    late T result;
    try {
      result = await operation(client);
    } on DeckException catch (error) {
      await _authenticationFailed(error);
      rethrow;
    } finally {
      await _persistBackoff();
    }
    await _prepareRequest();
    return result;
  }

  late final DeckSync sync;
  late final StreamSubscription<List<ConnectivityResult>> _connection;
  late final StreamSubscription<List<PendingWrite>> _pending;
  late final Timer _timer;
  final _openBoards = <int>{};
  bool _foreground = true;
  bool _hasPending = false;
  bool _refreshBoardListOnResume = false;
  final _running = <String, Future<void>>{};
  final _errors = <String, Object>{};
  bool _disposed = false;
  DeckCapabilities? capabilities;
  String? userId;

  void openBoard(int boardId) {
    if (_disposed) return;
    _openBoards.add(boardId);
    unawaited(refreshStacks(boardId));
  }

  void closeBoard(int boardId) => _openBoards.remove(boardId);

  void refreshBoardsOnNextResume() {
    if (!_disposed) _refreshBoardListOnResume = true;
  }

  void _refreshVisible() {
    if (_disposed || !_foreground) return;
    if (_openBoards.isEmpty) {
      unawaited(refreshBoards());
    } else {
      for (final id in _openBoards) {
        unawaited(refreshStacks(id));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) return;
    if (_refreshBoardListOnResume) {
      _refreshBoardListOnResume = false;
      unawaited(
        refreshBoards().then((_) {
          if (!_disposed && _openBoards.isNotEmpty) _refreshVisible();
        }),
      );
    } else {
      _refreshVisible();
    }
  }

  bool loading(String scope) => _running.containsKey(scope);
  Object? error(String scope) => _errors[scope];
  Stream<List<DeckBoard>> watchBoards() => database.watchBoards(account.id);
  Stream<List<DeckStack>> watchStacks(int boardId) =>
      database.watchStacks(account.id, boardId);

  Future<void> refreshBoards() => _refresh('boards', () async {
    userId = await client.currentUserId();
    await database.saveUserIdentity(account, userId!);
    await sync.run();
    capabilities = await client.capabilities();
    await database.saveCapabilities(account, capabilities!);
    final cached = await database.checkpoint(account.id, 'boards');
    final epoch = (await database.account(account.id))?.contentEpoch;
    final response = await client.rest('GET', ['boards'], etag: cached?.etag);
    if (_disposed || response.notModified) return;
    final boards = objects(response.data).map(DeckBoard.fromJson).toList();
    await database.saveBoards(
      account.id,
      account.generation,
      boards,
      response.etag,
      contentEpoch: epoch,
    );
  });

  Future<void> refreshStacks(int boardId) => _refresh(
    'board:$boardId',
    () async {
      await sync.run();
      final resolved = await database.resolveId(
        account.id,
        boardId,
        'createBoard',
      );
      if (resolved == null) return;
      final cached = await database.checkpoint(account.id, 'board:$resolved');
      final epoch = (await database.account(account.id))?.contentEpoch;
      if (_disposed || epoch == null) return;
      final details = await _readAccessibleBoard(resolved);
      if (_disposed) return;
      await database.saveBoard(account, details, epoch);
      if (details.deletedAt != 0) return;
      late DeckResponse response;
      late List<DeckStack> archived;
      try {
        response = await client.rest('GET', [
          'boards',
          '$resolved',
          'stacks',
        ], etag: cached?.etag);
        if (_disposed || response.notModified) return;
        archived = objects(
          (await client.rest('GET', [
            'boards',
            '$resolved',
            'stacks',
            'archived',
          ])).data,
        ).map(DeckStack.fromJson).toList();
      } on DeckException catch (error) {
        if (error.status == 403 || error.status == 404) {
          await _readAccessibleBoard(resolved);
        }
        rethrow;
      }
      if (_disposed || response.notModified) return;
      final active = objects(response.data).map(DeckStack.fromJson).toList();
      if (_disposed) return;
      final combined = {for (final stack in active) stack.id: stack};
      for (final stack in archived) {
        final previous = combined[stack.id];
        final cards = {
          for (final card in previous?.cards ?? <DeckCard>[]) card.id: card.raw,
          for (final card in stack.cards) card.id: card.raw,
        };
        combined[stack.id] = DeckStack.fromJson({
          ...stack.raw,
          'cards': cards.values.toList(),
        });
      }
      final stacks = combined.values.toList();
      await database.saveStacks(
        account.id,
        account.generation,
        resolved,
        stacks,
        response.etag,
        contentEpoch: epoch,
      );
    },
  );

  Future<void> refreshComments(int cardId) =>
      _refresh('comments:$cardId', () async {
        userId = await client.currentUserId();
        await database.saveUserIdentity(account, userId!);
        await sync.run();
        final resolved = await database.resolveId(
          account.id,
          cardId,
          'createCard',
        );
        if (_disposed || resolved == null) return;
        final epoch = (await database.account(account.id))?.contentEpoch;
        if (epoch == null) return;
        final comments = <int, DeckComment>{};
        await for (final page in client.commentPages(resolved)) {
          if (_disposed) return;
          for (final comment in page) {
            comments[comment.id] = comment;
          }
        }
        await database.saveComments(
          account,
          resolved,
          comments.values.toList(),
          epoch,
        );
      });

  Future<void> _refresh(String scope, Future<void> Function() operation) {
    if (_disposed) return Future.value();
    final existing = _running[scope];
    if (existing != null) return existing;
    final result = _perform(scope, operation);
    _running[scope] = result;
    notifyListeners();
    return result;
  }

  Future<void> _perform(String scope, Future<void> Function() operation) async {
    _errors.remove(scope);
    try {
      await _prepareRequest();
      await operation();
      if (_files != null && !_disposed) await _cleanAttachmentFiles();
    } catch (error) {
      // The view displays the error beside cached content, never raw exception text.
      _errors[scope] = error;
      if (error is DeckException) {
        try {
          await _authenticationFailed(error);
        } catch (storageError) {
          _errors[scope] = storageError;
        }
      }
    } finally {
      if (!_disposed) {
        try {
          await _persistBackoff();
        } catch (error) {
          _errors.putIfAbsent(scope, () => error);
        }
      }
      _running.remove(scope);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    sync.close();
    _timer.cancel();
    unawaited(_connection.cancel());
    unawaited(_pending.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
