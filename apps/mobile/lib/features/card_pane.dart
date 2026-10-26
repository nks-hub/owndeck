import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import 'card_detail.dart';
import 'desktop_platform.dart';

/// Window width from which a card opens in a right pane instead of a page.
const cardPaneMinWidth = 1024.0;

typedef OpenCard = ({DeckSession session, DeckBoard board, DeckCard card});

/// Holds the card shown in the right pane of a wide desktop window.
class CardPaneController extends ChangeNotifier {
  /// The controller of the pane currently on screen, for code outside the
  /// widget tree such as card link routing.
  static CardPaneController? active;

  OpenCard? _open;
  bool wide = false;
  OpenCard? get open => _open;

  void show(DeckSession session, DeckBoard board, DeckCard card) {
    _open = (session: session, board: board, card: card);
    notifyListeners();
  }

  void close() {
    if (_open == null) return;
    _open = null;
    notifyListeners();
  }
}

/// Exposes the pane to everything under it, only while the window is wide.
class CardPaneScope extends InheritedNotifier<CardPaneController> {
  const CardPaneScope({
    super.key,
    required CardPaneController controller,
    required super.child,
  }) : super(notifier: controller);

  static CardPaneController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardPaneScope>()?.notifier;
}

/// Lays out [child] with the card pane on its right when the window is wide.
class CardPaneHost extends StatefulWidget {
  const CardPaneHost({
    super.key,
    required this.controller,
    required this.child,
  });
  final CardPaneController controller;
  final Widget child;
  @override
  State<CardPaneHost> createState() => _CardPaneHostState();
}

class _CardPaneHostState extends State<CardPaneHost> {
  @override
  void initState() {
    super.initState();
    CardPaneController.active = widget.controller;
  }

  @override
  void dispose() {
    if (CardPaneController.active == widget.controller) {
      CardPaneController.active = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          isDesktopPlatform && constraints.maxWidth >= cardPaneMinWidth;
      widget.controller.wide = wide;
      if (!wide) return widget.child;
      return CardPaneScope(
        controller: widget.controller,
        child: Row(
          children: [
            Expanded(child: widget.child),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final open = widget.controller.open;
                if (open == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: (constraints.maxWidth * .36).clamp(380.0, 560.0),
                      child: CardScreen(
                        key: ValueKey((
                          open.session,
                          open.board.id,
                          open.card.id,
                        )),
                        session: open.session,
                        board: open.board,
                        card: open.card,
                        onClose: widget.controller.close,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Opens a card in the pane when there is one, otherwise as a pushed page.
Future<void> openCard(
  BuildContext context,
  DeckSession session,
  DeckBoard board,
  DeckCard card,
) {
  final pane = CardPaneScope.maybeOf(context);
  if (pane != null) {
    pane.show(session, board, card);
    return Future.value();
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/card'),
      builder: (_) => CardScreen(session: session, board: board, card: card),
    ),
  );
}

/// Closes the card page or pane that [context] belongs to.
void closeCard(BuildContext context) {
  final pane = CardPaneScope.maybeOf(context);
  if (pane != null && pane.open != null) {
    pane.close();
  } else {
    Navigator.of(context).maybePop();
  }
}
