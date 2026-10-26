part of 'database.dart';

int cardPositionIndex(List<int> siblings, JsonObject proposal) {
  if (!proposal.containsKey('before') &&
      !proposal.containsKey('anchorCardId')) {
    final order = intField(proposal, 'order');
    if (order < 0) throw StateError('invalid_position');
    return order.clamp(0, siblings.length);
  }
  final before = proposal['before'];
  if (before is! bool) throw StateError('invalid_position');
  final anchor = proposal['anchorCardId'];
  if (anchor == null) return before ? 0 : siblings.length;
  if (anchor is! int) throw StateError('invalid_position');
  final index = siblings.indexOf(anchor);
  if (index < 0) throw StateError('invalid_destination');
  return index + (before ? 0 : 1);
}

List<DeckCard> cardPositionCandidates(DeckStack stack, {int? excluding}) =>
    stack.cards
        .where(
          (card) =>
              card.id != excluding &&
              !card.archived &&
              (card.raw['deletedAt'] ?? 0) == 0,
        )
        .toList()
      ..sort(
        (a, b) => a.order == b.order
            ? a.id.compareTo(b.id)
            : a.order.compareTo(b.order),
      );
