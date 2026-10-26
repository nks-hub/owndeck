part of 'structure_editor.dart';

class BoardLabelsScreen extends StatefulWidget {
  const BoardLabelsScreen({
    super.key,
    required this.session,
    required this.boardId,
  });
  final DeckSession session;
  final int boardId;
  @override
  State<BoardLabelsScreen> createState() => _BoardLabelsScreenState();
}

class _BoardLabelsScreenState extends State<BoardLabelsScreen> {
  late final _board = widget.session.database.watchBoard(
    widget.session.account.id,
    widget.boardId,
  );

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() => widget.session.refreshStacks(widget.boardId));
  }

  Future<void> _delete(DeckBoard board, JsonObject label) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.deleteLabel),
        content: Text(text.deleteLabelQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(text.remove),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await widget.session.database.queueBoardMetadata(
        widget.session.account,
        board.id,
        'deleteLabel',
        {},
        original: label,
      );
      unawaited(widget.session.refreshStacks(board.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.pendingDecision)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(text.manageLabels)),
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => StreamBuilder<DeckBoard?>(
          stream: _board,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(text.localReadError));
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final board = snapshot.data;
            if (board == null || board.deletedAt != 0) {
              return Center(child: Text(text.permissionError));
            }
            final labels = objects(board.raw['labels'] ?? <Object?>[]);
            final editable = board.permissions.manage && !board.archived;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SyncNotice(
                  session: widget.session,
                  scope: 'board:${widget.boardId}',
                  retry: () => widget.session.refreshStacks(widget.boardId),
                  hasData: true,
                ),
                if (editable)
                  FilledButton.icon(
                    onPressed: () => editStructure(
                      context,
                      widget.session,
                      board: board,
                      labelItem: true,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(text.addLabel),
                  ),
                if (labels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(text.noLabels),
                  ),
                for (final label in labels)
                  ListTile(
                    title: Text(stringField(label, 'title')),
                    subtitle: label['syncState'] == null
                        ? null
                        : Text(text.pendingChanges),
                    leading: Icon(
                      Icons.label_outline,
                      color: Color(
                        0xff000000 |
                            (int.tryParse(
                                  label['color']?.toString().replaceFirst(
                                        '#',
                                        '',
                                      ) ??
                                      '',
                                  radix: 16,
                                ) ??
                                0),
                      ),
                    ),
                    onTap: editable
                        ? () => editStructure(
                            context,
                            widget.session,
                            board: board,
                            labelItem: true,
                            label: label,
                          )
                        : null,
                    trailing: editable && intField(label, 'id') > 0
                        ? IconButton(
                            tooltip: text.deleteLabel,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(board, label),
                          )
                        : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
