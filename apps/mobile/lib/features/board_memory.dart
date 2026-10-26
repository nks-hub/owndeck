import 'package:flutter/material.dart';

/// Reports which column tab of a board is selected, so it can be reopened.
class ColumnTabMemory extends StatefulWidget {
  const ColumnTabMemory({
    super.key,
    required this.controller,
    required this.stackIds,
    required this.onChanged,
    required this.child,
  });
  final TabController controller;
  final List<int> stackIds;
  final ValueChanged<int> onChanged;
  final Widget child;

  @override
  State<ColumnTabMemory> createState() => _ColumnTabMemoryState();
}

class _ColumnTabMemoryState extends State<ColumnTabMemory> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_report);
  }

  void _report() {
    final controller = widget.controller;
    if (!controller.indexIsChanging &&
        controller.index < widget.stackIds.length) {
      widget.onChanged(widget.stackIds[controller.index]);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_report);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
