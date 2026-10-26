part of 'sync.dart';

DeckCardContext? _cardInBoardSnapshot(
  DeckBoard board,
  int cardId,
  List<DeckStack> stacks,
) {
  DeckCardContext? result;
  for (final stack in stacks) {
    for (final card in stack.cards) {
      if (card.id != cardId) continue;
      if (result != null ||
          stack.boardId != board.id ||
          card.stackId != stack.id) {
        throw const FormatException('invalid_card_identity');
      }
      result = DeckCardContext(board: board, stack: stack, card: card);
    }
  }
  return result;
}

final class _CardContextUnavailable implements Exception {
  const _CardContextUnavailable(this.code, {this.boardId});
  final String code;
  final int? boardId;
}

extension _CurrentCardReads on DeckSync {
  Future<DeckResponse> _readCardResource(
    List<String> path, {
    int? boardId,
  }) async {
    try {
      return await client.rest('GET', path);
    } on DeckException catch (error) {
      if (error.status == 403 || error.status == 404) {
        throw _CardContextUnavailable(
          error.status == 403 ? 'permission_denied' : 'not_found',
          boardId: boardId,
        );
      }
      rethrow;
    }
  }

  Future<DeckCardContext> _readCurrentCardContext(
    int boardId,
    int stackId,
    int cardId, {
    DeckBoard? knownBoard,
  }) async {
    final card = DeckCard.fromJson(
      object(
        (await _readCardResource([
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
      throw const _CardContextUnavailable('not_found');
    }
    // IDs are global: the request URL does not prove the card's current board.
    final stack = DeckStack.fromJson(
      object(
        (await _readCardResource([
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
    final board = knownBoard?.id == stack.boardId
        ? knownBoard!
        : DeckBoard.fromJson(
            object(
              (await _readCardResource([
                'boards',
                '${stack.boardId}',
              ], boardId: stack.boardId)).data,
            ),
          );
    if (board.id != stack.boardId) {
      throw const FormatException('invalid_board_identity');
    }
    if (!board.permissions.read) {
      throw _CardContextUnavailable('permission_denied', boardId: board.id);
    }
    if (board.deletedAt != 0 || (stack.raw['deletedAt'] ?? 0) != 0) {
      throw const _CardContextUnavailable('not_found');
    }
    return DeckCardContext(board: board, stack: stack, card: card);
  }
}
