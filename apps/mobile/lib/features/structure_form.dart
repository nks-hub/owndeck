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
  String _placement = 'keep';
  int? _anchor;
  List<DeckStack> _columns = [];
  bool _loadingColumns = false;
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
    _placement = widget.stack == null ? 'end' : 'keep';
    if (widget.column) unawaited(_loadColumns());
  }

  Future<void> _loadColumns() async {
    setState(() => _loadingColumns = true);
    try {
      final columns = await widget.session.database.stackView(
        widget.session.account.id,
        widget.board!.id,
      );
      if (mounted) {
        setState(
          () => _columns = columns
              .where(
                (column) =>
                    column.id != widget.stack?.id &&
                    (column.raw['deletedAt'] ?? 0) == 0,
              )
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.localReadError);
      }
    } finally {
      if (mounted) setState(() => _loadingColumns = false);
    }
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
    if (!widget.column && !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
      setState(() => _error = text.invalidColor);
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
        await session.database.transaction(() async {
          final id = await session.database.queueStructure(
            session.account,
            column
                ? stack == null
                      ? 'createStack'
                      : 'updateStack'
                : board == null
                ? 'createBoard'
                : 'updateBoard',
            {'title': title, if (!column) 'color': value.toLowerCase()},
            boardId: board?.id ?? 0,
            stackId: stack?.id ?? 0,
            base: column ? stack?.raw : board?.raw,
          );
          if (column && _placement != 'keep') {
            await session.database.queueStackReorder(
              session.account,
              board!.id,
              stack?.id ?? id,
              anchorStackId: _placement == 'after' ? _anchor : null,
              before: _placement == 'start',
            );
          }
        });
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
          _error = localWriteErrorMessage(
            error,
            text,
            pendingMessage: text.pendingBoardDecision,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    // Avoid moving the dialog through an inset animation with stale iOS semantics.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: _dialog(context),
    ),
  );

  Widget _dialog(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return AlertDialog(
      alignment: Alignment.topCenter,
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
          if (widget.column) ...[
            if (_loadingColumns) const LinearProgressIndicator(),
            DropdownButtonFormField<String>(
              initialValue: _placement,
              isExpanded: true,
              decoration: InputDecoration(labelText: text.position),
              items: [
                if (widget.stack != null)
                  DropdownMenuItem(
                    value: 'keep',
                    child: Text(text.keepPosition),
                  ),
                DropdownMenuItem(value: 'start', child: Text(text.moveToTop)),
                DropdownMenuItem(value: 'end', child: Text(text.moveToBottom)),
                if (_columns.isNotEmpty)
                  DropdownMenuItem(
                    value: 'after',
                    child: Text(text.afterColumn),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _placement = value;
                          _anchor ??= _columns.firstOrNull?.id;
                        });
                      }
                    },
            ),
            if (_placement == 'after')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: DropdownButtonFormField<int>(
                  initialValue: _anchor,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: text.destinationColumn,
                  ),
                  items: [
                    for (final column in _columns)
                      DropdownMenuItem(
                        value: column.id,
                        child: Text(
                          column.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _anchor = value),
                ),
              ),
          ] else ...[
            Text(text.color, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ColorChoices(
              value: _value.text,
              allowNone: false,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _value.text = value!),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!),
            ),
          if (_saving) const LinearProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(text.cancel),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: Text(text.save)),
      ],
    );
  }
}
