import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/foundation.dart';

final class DeckSession extends ChangeNotifier {
  DeckSession(this.database, this.account, this.client) {
    sync = CardSync(database, account, client);
  }
  final DeckDatabase database;
  final StoredAccount account;
  final DeckClient client;
  late final CardSync sync;
  final _running = <String, Future<void>>{};
  final _errors = <String, Object>{};
  bool _disposed = false;
  DeckCapabilities? capabilities;

  bool loading(String scope) => _running.containsKey(scope);
  Object? error(String scope) => _errors[scope];
  Stream<List<DeckBoard>> watchBoards() => database.watchBoards(account.id);
  Stream<List<DeckStack>> watchStacks(int boardId) =>
      database.watchStacks(account.id, boardId);

  Future<void> refreshBoards() => _refresh('boards', () async {
    await sync.run();
    capabilities = await client.capabilities();
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

  Future<void> refreshStacks(int boardId) =>
      _refresh('board:$boardId', () async {
        await sync.run();
        final cached = await database.checkpoint(account.id, 'board:$boardId');
        final epoch = (await database.account(account.id))?.contentEpoch;
        final response = await client.rest('GET', [
          'boards',
          '$boardId',
          'stacks',
        ], etag: cached?.etag);
        if (_disposed || response.notModified) return;
        final stacks = objects(response.data).map(DeckStack.fromJson).toList();
        await database.saveStacks(
          account.id,
          account.generation,
          boardId,
          stacks,
          response.etag,
          contentEpoch: epoch,
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
      await operation();
    } catch (error) {
      // The view displays the error beside cached content, never raw exception text.
      _errors[scope] = error;
    } finally {
      _running.remove(scope);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    sync.close();
    super.dispose();
  }
}
