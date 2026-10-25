import 'package:flutter/widgets.dart';

import '../data/session.dart';

class BoardPresence extends StatefulWidget {
  const BoardPresence({
    super.key,
    required this.session,
    required this.boardId,
    required this.child,
  });

  final DeckSession session;
  final int boardId;
  final Widget child;

  @override
  State<BoardPresence> createState() => _BoardPresenceState();
}

class _BoardPresenceState extends State<BoardPresence> {
  final _owner = Object();

  void _update() => widget.session.setVisibleBoard(
    _owner,
    ModalRoute.isCurrentOf(context) == false ? null : widget.boardId,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant BoardPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.setVisibleBoard(_owner, null);
    }
    _update();
  }

  @override
  void dispose() {
    widget.session.setVisibleBoard(_owner, null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
