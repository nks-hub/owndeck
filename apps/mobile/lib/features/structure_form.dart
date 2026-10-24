part of 'structure_editor.dart';

class _StructureForm extends StatefulWidget {
  const _StructureForm({
    required this.session,
    required this.column,
    required this.labelItem,
    this.board,
    this.stack,
    this.label,
  });
  final DeckSession session;
  final DeckBoard? board;
  final DeckStack? stack;
  final bool column;
  final bool labelItem;
  final JsonObject? label;
  @override
  State<_StructureForm> createState() => _StructureFormState();
}

class _StructureFormState extends State<_StructureForm> {
  late final TextEditingController _name;
  late final TextEditingController _value;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final label = widget.label;
    final name = widget.labelItem
        ? label == null
              ? ''
              : stringField(label, 'title')
        : widget.column
        ? widget.stack?.title ?? ''
        : widget.board?.title ?? '';
    final value = widget.labelItem
        ? label == null
              ? '008080'
              : stringField(label, 'color')
        : widget.column
        ? '${widget.stack?.order ?? 999}'
        : widget.board?.color ?? '008080';
    _name = TextEditingController(text: name);
    _value = TextEditingController(text: value);
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final text = AppLocalizations.of(context)!;
    final title = _name.text.trim();
    final value = _value.text.trim().replaceFirst('#', '');
    if (title.isEmpty || title.runes.length > 100) {
      setState(() => _error = text.invalidName);
      return;
    }
    if (widget.column
        ? int.tryParse(value) == null || int.parse(value) < 0
        : !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
      setState(
        () => _error = widget.column ? text.invalidPosition : text.invalidColor,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final session = widget.session;
    final board = widget.board;
    final stack = widget.stack;
    final label = widget.label;
    final column = widget.column;
    final labelItem = widget.labelItem;
    try {
      if (labelItem) {
        final changes = <String, Object?>{
          if (label == null || label['title'] != title) 'title': title,
          if (label == null || label['color'] != value.toLowerCase())
            'color': value.toLowerCase(),
        };
        if (changes.isNotEmpty) {
          await session.database.queueBoardMetadata(
            session.account,
            board!.id,
            label == null ? 'createLabel' : 'updateLabel',
            changes,
            original: label,
          );
        }
      } else {
        await session.database.queueStructure(
          session.account,
          column
              ? stack == null
                    ? 'createStack'
                    : 'updateStack'
              : board == null
              ? 'createBoard'
              : 'updateBoard',
          {
            'title': title,
            if (column)
              'order': int.parse(value)
            else
              'color': value.toLowerCase(),
          },
          boardId: board?.id ?? 0,
          stackId: stack?.id ?? 0,
          base: column ? stack?.raw : board?.raw,
        );
      }
      if (mounted) Navigator.pop(context);
      unawaited(
        column || labelItem
            ? session.refreshStacks(board!.id)
            : session.refreshBoards(),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError && error.message == 'pending_decision'
              ? text.pendingDecision
              : text.loadError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        widget.labelItem
            ? widget.label == null
                  ? text.addLabel
                  : text.editLabel
            : widget.column
            ? widget.stack == null
                  ? text.addStack
                  : text.editStack
            : widget.board == null
            ? text.addBoard
            : text.editBoard,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            enabled: !_saving,
            autofocus: true,
            decoration: InputDecoration(labelText: text.name),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _value,
            enabled: !_saving,
            keyboardType: widget.column
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: widget.column ? text.position : text.color,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!),
            ),
          if (_saving) const LinearProgressIndicator(),
          const SizedBox(height: 24),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: Text(text.cancel),
              ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(text.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
