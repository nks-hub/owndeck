import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';

import 'session.dart';

extension SessionCardReads on DeckSession {
  Future<DeckCardContext> openRemoteCard(
    int boardId,
    int cardId, {
    int? stackId,
  }) async {
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) throw StateError('account_unavailable');
    final result = await readServer(
      (api) => api.readCardContext(boardId, cardId, stackId: stackId),
    );
    if (!await database.saveReadCard(account, result, epoch)) {
      throw StateError('stale_response');
    }
    return result;
  }
}
