part of 'card_detail.dart';

extension _CardDialogs on _CardScreenState {
  Future<void> _delete(DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.deleteCard),
        content: Text(text.deleteCardQuestion),
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
    if (confirmed == true && mounted) await _action(card, 'deleteCard', {});
  }

  Future<void> _move(DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    List<DeckStack> stacks;
    try {
      stacks = await widget.session.database.stackView(
        widget.session.account.id,
        widget.board.id,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.storageError)));
      return;
    }
    if (!mounted || stacks.isEmpty) return;
    var destination = stacks.any((s) => s.id == card.stackId)
        ? card.stackId
        : stacks.first.id;
    final position = TextEditingController(text: '0');
    String? error;
    try {
      final move = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(text.moveCard),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: destination,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: text.destinationColumn,
                    ),
                    items: [
                      for (final stack in stacks)
                        DropdownMenuItem(
                          value: stack.id,
                          child: Text(
                            stack.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => destination = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: position,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: text.position),
                  ),
                  if (error != null) Text(error!),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(text.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final order = int.tryParse(position.text);
                  if (order == null || order < 0) {
                    setState(() => error = text.invalidPosition);
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: Text(text.moveCard),
              ),
            ],
          ),
        ),
      );
      if (move == true && mounted)
        await _action(card, 'moveCard', {
          'stackId': destination,
          'order': int.parse(position.text),
        });
    } finally {
      position.dispose();
    }
  }

  Future<void> _labels(DeckBoard board, DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final labels = _items(board.raw['labels']);
    final assigned = _items(
      card.raw['labels'],
    ).map((label) => label['id']).toSet();
    final chosen = await showModalBottomSheet<JsonObject>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: labels.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(text.noLabels),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: labels.length,
                itemBuilder: (context, index) {
                  final label = labels[index];
                  return CheckboxListTile(
                    value: assigned.contains(label['id']),
                    title: Text(label['title']?.toString() ?? ''),
                    onChanged: (_) => Navigator.pop(context, label),
                  );
                },
              ),
      ),
    );
    if (chosen != null && mounted)
      await _action(
        card,
        assigned.contains(chosen['id']) ? 'removeLabel' : 'assignLabel',
        {'labelId': chosen['id'], 'label': chosen},
      );
  }

  Future<void> _users(DeckBoard board, DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final users = _items(
      board.raw['users'],
    ).where((u) => _uid(u).isNotEmpty).toList();
    final assigned = _items(
      card.raw['assignedUsers'],
    ).map((assignment) => _uid(assignment['participant'])).toSet();
    final chosen = await showModalBottomSheet<JsonObject>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: users.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(text.noUsers),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return CheckboxListTile(
                    value: assigned.contains(_uid(user)),
                    title: Text(_name(user)),
                    onChanged: (_) => Navigator.pop(context, user),
                  );
                },
              ),
      ),
    );
    if (chosen != null && mounted)
      await _action(
        card,
        assigned.contains(_uid(chosen)) ? 'unassignUser' : 'assignUser',
        {'userId': _uid(chosen), 'type': 0, 'user': chosen},
      );
  }
}
