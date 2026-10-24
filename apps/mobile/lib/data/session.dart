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
  }) : _files = files {
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
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground && _openBoards.isNotEmpty) _refreshVisible();
    });
  }
  final DeckDatabase database;
  final StoredAccount account;
  final DeckClient client;
  final Future<AttachmentFiles> Function()? _files;
  final Future<void> Function()? onAuthenticationRequired;

  Future<void> _authenticationFailed(DeckException error) async {
    if (!_disposed && error.status == 401)
      await onAuthenticationRequired?.call();
  }

  late final DeckSync sync;
  late final StreamSubscription<List<ConnectivityResult>> _connection;
  late final Timer _timer;
  final _openBoards = <int>{};
  bool _foreground = true;
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
    if (_foreground) _refreshVisible();
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
      final details = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '$resolved'])).data),
      );
      if (_disposed) return;
      await database.saveBoard(account, details, epoch);
      final response = await client.rest('GET', [
        'boards',
        '$resolved',
        'stacks',
      ], etag: cached?.etag);
      if (_disposed || response.notModified) return;
      final active = objects(response.data).map(DeckStack.fromJson).toList();
      final archived = objects(
        (await client.rest('GET', [
          'boards',
          '$resolved',
          'stacks',
          'archived',
        ])).data,
      ).map(DeckStack.fromJson).toList();
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
      final current = await database.account(account.id);
      if (_disposed ||
          current == null ||
          current.state != 'active' ||
          current.generation != account.generation) {
        return;
      }
      client.deferUntil(current.syncNotBefore);
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
          await database.deferSync(account, client.retryUntil);
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
