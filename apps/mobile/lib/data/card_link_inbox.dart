import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/foundation.dart';

final class CardLinkRequest {
  const CardLinkRequest(this.sequence, this.link);
  final int sequence;
  final DeckCardLink? link;
}

final class CardLinkInbox extends ChangeNotifier {
  CardLinkRequest? pending;
  int _sequence = 0;

  void offer(String raw) {
    final link = parseDeckCardLink(raw);
    if (link != null && pending?.link?.webUri == link.webUri) return;
    pending = CardLinkRequest(++_sequence, link);
    notifyListeners();
  }

  bool contains(CardLinkRequest request) => identical(pending, request);

  void complete(CardLinkRequest request) {
    if (!contains(request)) return;
    pending = null;
    notifyListeners();
  }
}

List<StoredAccount> accountsForCardLink(
  Iterable<StoredAccount> accounts,
  DeckCardLink link,
) => accounts
    .where(
      (account) =>
          account.state != 'deleting' &&
          ServerBase.parse(account.server).uri == link.server.uri,
    )
    .toList();

final incomingCardLinks = CardLinkInbox();
