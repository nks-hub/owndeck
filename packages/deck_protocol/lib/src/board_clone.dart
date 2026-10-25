import 'client.dart';
import 'models.dart';

final class BoardCloneOptions {
  const BoardCloneOptions({
    this.withCards = false,
    this.withAssignments = false,
    this.withLabels = false,
    this.withDueDate = false,
    this.moveCardsToLeftStack = false,
    this.restoreArchivedCards = false,
  });

  factory BoardCloneOptions.fromJson(JsonObject json) {
    bool flag(String key) {
      final value = json[key];
      if (value == null) return false;
      if (value is! bool) throw const FormatException('invalid_clone_options');
      return value;
    }

    return BoardCloneOptions(
      withCards: flag('withCards'),
      withAssignments: flag('withAssignments'),
      withLabels: flag('withLabels'),
      withDueDate: flag('withDueDate'),
      moveCardsToLeftStack: flag('moveCardsToLeftStack'),
      restoreArchivedCards: flag('restoreArchivedCards'),
    );
  }

  final bool withCards;
  final bool withAssignments;
  final bool withLabels;
  final bool withDueDate;
  final bool moveCardsToLeftStack;
  final bool restoreArchivedCards;

  JsonObject toJson() => {
    'withCards': withCards,
    'withAssignments': withAssignments,
    'withLabels': withLabels,
    'withDueDate': withDueDate,
    'moveCardsToLeftStack': moveCardsToLeftStack,
    'restoreArchivedCards': restoreArchivedCards,
  };
}

extension DeckBoardCloning on DeckClient {
  Future<DeckBoard> cloneBoard(int boardId, BoardCloneOptions options) async {
    if (boardId <= 0) throw ArgumentError('invalid_board_identity');
    final response = await rest('POST', [
      'boards',
      '$boardId',
      'clone',
    ], body: options.toJson());
    try {
      final board = DeckBoard.fromJson(object(response.data));
      if (board.id <= 0 || board.id == boardId) {
        throw const FormatException('invalid_clone_identity');
      }
      return board;
    } on FormatException {
      throw const DeckException('invalid_response', uncertain: true);
    }
  }
}
