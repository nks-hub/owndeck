import 'dart:async';

import 'package:flutter/material.dart';

final class BoardCardDrag {
  const BoardCardDrag({
    required this.accountId,
    required this.generation,
    required this.boardId,
    required this.stackId,
    required this.cardId,
  });
  final String accountId;
  final int generation;
  final int boardId;
  final int stackId;
  final int cardId;
}

final class BoardDropPosition {
  const BoardDropPosition(
    this.stackId, {
    this.anchorId,
    this.after = false,
    this.index,
  });
  final int stackId;
  final int? anchorId;
  final bool after;
  final int? index;
}

typedef BoardDropHandler =
    void Function(BoardCardDrag drag, BoardDropPosition position);

Key boardDropKey(
  String accountId,
  int generation,
  int boardId,
  int stackId,
  int? cardId,
) => ValueKey(
  cardId == null
      ? ('drop-end', accountId, generation, boardId, stackId)
      : ('drop-card', accountId, generation, boardId, cardId),
);

final class BoardDragActivity extends ValueNotifier<BoardCardDrag?> {
  BoardDragActivity() : super(null);
  bool _closed = false;
  void start(BoardCardDrag drag) {
    if (!_closed) value = drag;
  }

  void stop() {
    if (!_closed) value = null;
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

class BoardDropSurface extends StatefulWidget {
  const BoardDropSurface({
    super.key,
    required this.accountId,
    required this.generation,
    required this.boardId,
    required this.enabled,
    required this.onDrop,
    required this.child,
    this.onPointer,
    this.onExit,
  });
  final String accountId;
  final int generation;
  final int boardId;
  final bool enabled;
  final BoardDropHandler onDrop;
  final Widget child;
  final ValueChanged<Offset>? onPointer;
  final VoidCallback? onExit;
  @override
  State<BoardDropSurface> createState() => _BoardDropSurfaceState();
}

class _BoardDropSurfaceState extends State<BoardDropSurface> {
  final _anchors = <_BoardCardDropTargetState>{};
  BoardCardDrag? _drag;
  Offset? _point;
  _BoardCardDropTargetState? _selected;
  bool _scheduled = false;
  bool _closed = false;

  bool _accepts(BoardCardDrag data) =>
      widget.enabled &&
      data.accountId == widget.accountId &&
      data.generation == widget.generation &&
      data.boardId == widget.boardId;
  void register(_BoardCardDropTargetState anchor) {
    _anchors.add(anchor);
    scheduleRefresh();
  }

  void unregister(_BoardCardDropTargetState anchor) {
    _anchors.remove(anchor);
    if (_selected == anchor) {
      anchor.widget.onExit?.call();
      _selected = null;
    }
    scheduleRefresh();
  }

  void scheduleRefresh() {
    if (_closed || _scheduled || _drag == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && !_closed) _refresh();
    });
  }

  _DropPlacement? _find() {
    final drag = _drag;
    final point = _point;
    final viewport = context.findRenderObject();
    if (drag == null ||
        point == null ||
        !_accepts(drag) ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      return null;
    }
    final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
    if (!visible.contains(point)) return null;
    _BoardCardDropTargetState? last;
    Rect? lastBounds;
    for (final anchor in _anchors) {
      final bounds = anchor.bounds;
      final clipped = anchor.visibleBounds;
      if (bounds == null ||
          clipped == null ||
          !clipped.overlaps(visible) ||
          point.dx < clipped.left ||
          point.dx >= clipped.right) {
        continue;
      }
      if (clipped.contains(point)) {
        if (!anchor.widget.enabled || anchor.widget.cardId == drag.cardId) {
          return null;
        }
        return _DropPlacement(
          anchor,
          anchor.widget.cardId != null && point.dy >= bounds.center.dy,
        );
      }
      if (lastBounds == null || bounds.bottom > lastBounds.bottom) {
        last = anchor;
        lastBounds = bounds;
      }
    }
    if (last != null &&
        lastBounds != null &&
        last.widget.cardId == null &&
        last.widget.enabled &&
        point.dy >= lastBounds.bottom) {
      return _DropPlacement(last, false);
    }
    return null;
  }

  void _refresh() {
    final placement = _find();
    if (_selected != placement?.anchor) {
      _selected?.highlight(null);
      _selected?.widget.onExit?.call();
    }
    _selected = placement?.anchor;
    _selected?.highlight(placement?.after);
    if (_point case final Offset point) {
      _selected?.widget.onPointer?.call(point);
    }
  }

  void _clear() {
    _drag = null;
    _point = null;
    _selected?.highlight(null);
    _selected?.widget.onExit?.call();
    _selected = null;
    widget.onExit?.call();
  }

  @override
  void didUpdateWidget(covariant BoardDropSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag != null && !_accepts(_drag!)) _clear();
    scheduleRefresh();
  }

  @override
  void dispose() {
    _closed = true;
    _anchors.clear();
    _selected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DragTarget<BoardCardDrag>(
    onWillAcceptWithDetails: (details) {
      if (!_accepts(details.data)) return false;
      _drag = details.data;
      _point = details.offset;
      scheduleRefresh();
      return true;
    },
    onMove: (details) {
      _drag = details.data;
      _point = details.offset;
      widget.onPointer?.call(details.offset);
      _refresh();
    },
    onLeave: (_) => _clear(),
    onAcceptWithDetails: (details) {
      _drag = details.data;
      _point = details.offset;
      final placement = _find();
      _clear();
      if (_accepts(details.data) && placement != null) {
        widget.onDrop(
          details.data,
          BoardDropPosition(
            placement.anchor.widget.stackId,
            anchorId: placement.anchor.widget.cardId,
            after: placement.after,
          ),
        );
      }
    },
    builder: (context, candidates, rejected) =>
        NotificationListener<ScrollNotification>(
          onNotification: (_) {
            scheduleRefresh();
            return false;
          },
          child: _BoardDropScope(surface: this, child: widget.child),
        ),
  );
}

final class _DropPlacement {
  const _DropPlacement(this.anchor, this.after);
  final _BoardCardDropTargetState anchor;
  final bool after;
}

class _BoardDropScope extends InheritedWidget {
  const _BoardDropScope({required this.surface, required super.child});
  final _BoardDropSurfaceState surface;
  @override
  bool updateShouldNotify(_BoardDropScope oldWidget) =>
      oldWidget.surface != surface;
}

class BoardCardDropTarget extends StatefulWidget {
  const BoardCardDropTarget({
    super.key,
    required this.stackId,
    required this.enabled,
    required this.child,
    this.cardId,
    this.onPointer,
    this.onExit,
  });
  final int stackId;
  final int? cardId;
  final bool enabled;
  final Widget child;
  final ValueChanged<Offset>? onPointer;
  final VoidCallback? onExit;
  @override
  State<BoardCardDropTarget> createState() => _BoardCardDropTargetState();
}

class _BoardCardDropTargetState extends State<BoardCardDropTarget> {
  _BoardDropSurfaceState? _surface;
  ScrollableState? _scrollable;
  bool? _after;
  bool _closed = false;
  Rect? get bounds {
    final box = context.findRenderObject();
    return mounted && !_closed && box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }

  Rect? get visibleBounds {
    final row = bounds;
    final viewport = _scrollable?.context.findRenderObject();
    if (row == null || viewport is! RenderBox || !viewport.hasSize) return null;
    final clipped = row.intersect(
      viewport.localToGlobal(Offset.zero) & viewport.size,
    );
    return clipped.isEmpty ? null : clipped;
  }

  void highlight(bool? after) {
    if (mounted && !_closed && _after != after) setState(() => _after = after);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.maybeOf(context);
    final surface = context
        .dependOnInheritedWidgetOfExactType<_BoardDropScope>()
        ?.surface;
    if (_surface != surface) {
      _surface?.unregister(this);
      _surface = surface;
      surface?.register(this);
    }
  }

  @override
  void didUpdateWidget(covariant BoardCardDropTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _surface?.scheduleRefresh();
  }

  @override
  void dispose() {
    _closed = true;
    _surface?.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_after != null)
        Positioned(
          left: 0,
          right: 0,
          top: _after == true ? null : 0,
          bottom: _after == true ? 0 : null,
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(
                  Icons.arrow_right_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: Container(
                    height: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class BoardDragScrollRegion extends StatefulWidget {
  const BoardDragScrollRegion({
    super.key,
    required this.activity,
    required this.builder,
    this.axis = Axis.vertical,
  });
  final BoardDragActivity activity;
  final Axis axis;
  final Widget Function(
    BuildContext,
    ScrollController,
    ValueChanged<Offset>,
    VoidCallback,
  )
  builder;
  @override
  State<BoardDragScrollRegion> createState() => _BoardDragScrollRegionState();
}

class _BoardDragScrollRegionState extends State<BoardDragScrollRegion> {
  final _scroll = ScrollController();
  Timer? _timer;
  double _step = 0;
  @override
  void initState() {
    super.initState();
    widget.activity.addListener(_activityChanged);
  }

  @override
  void didUpdateWidget(covariant BoardDragScrollRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.axis != widget.axis) _stop();
    if (oldWidget.activity != widget.activity) {
      oldWidget.activity.removeListener(_activityChanged);
      widget.activity.addListener(_activityChanged);
      _stop();
    }
  }

  void _activityChanged() {
    if (widget.activity.value == null) _stop();
  }

  void _stop() {
    _step = 0;
    _timer?.cancel();
    _timer = null;
  }

  void _pointer(Offset point) {
    final box = context.findRenderObject();
    if (box is! RenderBox || widget.activity.value == null) return;
    final local = box.globalToLocal(point);
    final position = widget.axis == Axis.vertical ? local.dy : local.dx;
    final extent = widget.axis == Axis.vertical
        ? box.size.height
        : box.size.width;
    const edge = 48.0;
    _step = position < edge
        ? -12.0 * (1 - position / edge).clamp(0, 1)
        : position > extent - edge
        ? 12.0 * ((position - extent + edge) / edge).clamp(0, 1)
        : 0;
    if (_step == 0) {
      _stop();
      return;
    }
    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients || widget.activity.value == null) {
        _stop();
        return;
      }
      final next = (_scroll.offset + _step)
          .clamp(
            _scroll.position.minScrollExtent,
            _scroll.position.maxScrollExtent,
          )
          .toDouble();
      if (next != _scroll.offset) _scroll.jumpTo(next);
    });
  }

  @override
  void dispose() {
    widget.activity.removeListener(_activityChanged);
    _stop();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _scroll, _pointer, _stop);
}
