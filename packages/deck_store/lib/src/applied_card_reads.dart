part of 'sync.dart';

final class _AppliedCardUnavailable implements Exception {
  const _AppliedCardUnavailable(this.code, {this.boardId});
  final String code;
  final int? boardId;
}

extension _AppliedCardReads on DeckSync {
  Future<DeckResponse> _readAppliedResource(
    List<String> path, {
    int? boardId,
  }) async {
    try {
      return await client.rest('GET', path);
    } on DeckException catch (error) {
      if (error.status == 403 || error.status == 404) {
        throw _AppliedCardUnavailable(
          error.status == 403 ? 'permission_denied' : 'not_found',
          boardId: boardId,
        );
      }
      rethrow;
    }
  }

  Future<DeckCardContext> _readAppliedCard(
    int boardId,
    int stackId,
    int cardId,
  ) async {
    final card = DeckCard.fromJson(
      object(
        (await _readAppliedResource([
          'boards',
          '$boardId',
          'stacks',
          '$stackId',
          'cards',
          '$cardId',
        ])).data,
      ),
    );
    if (card.id != cardId || card.id <= 0 || card.stackId <= 0) {
      throw const FormatException('invalid_card_identity');
    }
    if ((card.raw['deletedAt'] ?? 0) != 0) {
      throw const _AppliedCardUnavailable('not_found');
    }
    // IDs are global: the request URL does not prove the card's current board.
    final stack = DeckStack.fromJson(
      object(
        (await _readAppliedResource([
          'boards',
          '$boardId',
          'stacks',
          '${card.stackId}',
        ])).data,
      ),
    );
    if (stack.id != card.stackId || stack.boardId <= 0) {
      throw const FormatException('invalid_stack_identity');
    }
    final board = DeckBoard.fromJson(
      object(
        (await _readAppliedResource([
          'boards',
          '${stack.boardId}',
        ], boardId: stack.boardId)).data,
      ),
    );
    if (board.id != stack.boardId) {
      throw const FormatException('invalid_board_identity');
    }
    if (!board.permissions.read) {
      throw _AppliedCardUnavailable('permission_denied', boardId: board.id);
    }
    if (board.deletedAt != 0 || (stack.raw['deletedAt'] ?? 0) != 0) {
      throw const _AppliedCardUnavailable('not_found');
    }
    return DeckCardContext(board: board, stack: stack, card: card);
  }
}
