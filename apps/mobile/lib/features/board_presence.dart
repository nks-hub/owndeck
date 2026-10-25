import 'package:flutter/widgets.dart';

import '../data/session.dart';

class BoardPresence extends StatefulWidget {
  const BoardPresence({
    super.key,
    required this.session,
    this.boardId,
    this.active = true,
    required this.child,
  });

  final DeckSession session;
  final int? boardId;
  final bool active;
  final Widget child;

  @override
  State<BoardPresence> createState() => _BoardPresenceState();
}

class _BoardPresenceState extends State<BoardPresence> {
  final _owner = Object();

  void _update() {
    final visible = widget.active && ModalRoute.isCurrentOf(context) != false;
    widget.session.setVisibleBoard(_owner, visible ? widget.boardId : null);
    widget.session.setBoardOverviewVisible(
      _owner,
      visible && widget.boardId == null,
    );
  }

  void _release(DeckSession session) {
    session.setVisibleBoard(_owner, null);
    session.setBoardOverviewVisible(_owner, false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant BoardPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _release(oldWidget.session);
    }
    _update();
  }

  @override
  void dispose() {
    _release(widget.session);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
