part of 'card_detail.dart';

extension _CardDialogs on _CardScreenState {
  Future<void> _copyLink(DeckBoard board, DeckCard card) async {
    final link = DeckCardLink(
      server: widget.session.client.base,
      boardId: board.id,
      cardId: card.id,
    );
    await Clipboard.setData(ClipboardData(text: link.webUri.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cardLinkCopied)),
      );
    }
  }

  Future<void> _copy(DeckCard card) async {
    if (_copying) return;
    _setCopyState(active: true);
    final text = AppLocalizations.of(context)!;
    try {
      final boards =
          (await widget.session.database.boardView(widget.session.account.id))
              .where(
                (board) =>
                    board.permissions.edit &&
                    !board.archived &&
                    board.deletedAt == 0,
              )
              .toList();
      if (!mounted) return;
      if (boards.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.noCopyDestination)));
        return;
      }
      final targetBoard = await showModalBottomSheet<DeckBoard>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  text.copyDestinationBoard,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final board in boards)
                ListTile(
                  title: Text(board.title),
                  leading: const Icon(Icons.view_kanban_outlined),
                  onTap: () => Navigator.pop(context, board),
                ),
            ],
          ),
        ),
      );
      if (targetBoard == null || !mounted) return;
      var stacks = await widget.session.database.stackView(
        widget.session.account.id,
        targetBoard.id,
      );
      if (!mounted) return;
      if (stacks.isEmpty) {
        _setCopyState(loading: true);
        await widget.session.refreshStacks(targetBoard.id);
        stacks = await widget.session.database.stackView(
          widget.session.account.id,
          targetBoard.id,
        );
        _setCopyState(loading: false);
      }
      if (!mounted) return;
      if (stacks.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.noStacks)));
        return;
      }
      var selected =
          targetBoard.id == widget.board.id &&
              stacks.any((stack) => stack.id == card.stackId)
          ? card.stackId
          : stacks.first.id;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(text.copyCard),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text.copyCardDescription),
                  const SizedBox(height: 16),
                  Text(targetBoard.title),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selected,
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
                      if (value != null) update(() => selected = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(text.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(text.copyCard),
              ),
            ],
          ),
        ),
      );
      if (confirmed == true && mounted) {
        await _action(card, 'cloneCard', {
          'title': card.title,
          'destinationBoardId': targetBoard.id,
          'destinationStackId': selected,
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.loadError)));
      }
    } finally {
      _setCopyState(active: false, loading: false);
    }
  }

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

  Future<void> _move(DeckBoard board, DeckCard card) =>
      showBoardCardMove(context, widget.session, board, card);

  Future<void> _labels(DeckBoard board, DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final labels = _items(
      board.raw['labels'],
    ).where((label) => label['id'] is int).toList();
    final assigned = _items(
      card.raw['labels'],
    ).map((label) => '${label['id']}').toSet();
    await showCardSelection(
      context,
      title: text.labels,
      emptyMessage: text.noLabels,
      options: {
        for (final label in labels)
          '${label['id']}': label['title']?.toString().trim().isNotEmpty == true
              ? label['title'].toString()
              : text.unnamedLabel,
      },
      selected: assigned,
      onSave: (selected) async {
        await widget.session.database.transaction(() async {
          for (final label in labels) {
            final id = '${label['id']}';
            if (assigned.contains(id) == selected.contains(id)) continue;
            await widget.session.database.queueCardAction(
              widget.session.account,
              board.id,
              card,
              selected.contains(id) ? 'assignLabel' : 'removeLabel',
              {'labelId': label['id'], 'label': label},
            );
          }
        });
        unawaited(widget.session.refreshStacks(board.id));
      },
    );
  }

  Future<void> _users(DeckBoard board, DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final users = _items(
      board.raw['users'],
    ).where((user) => _uid(user).isNotEmpty).toList();
    final assigned = _items(
      card.raw['assignedUsers'],
    ).map((assignment) => _uid(assignment['participant'])).toSet();
    await showCardSelection(
      context,
      title: text.assignees,
      emptyMessage: text.noUsers,
      options: {for (final user in users) _uid(user): _name(user)},
      selected: assigned,
      onSave: (selected) async {
        await widget.session.database.transaction(() async {
          for (final user in users) {
            final id = _uid(user);
            if (assigned.contains(id) == selected.contains(id)) continue;
            await widget.session.database.queueCardAction(
              widget.session.account,
              board.id,
              card,
              selected.contains(id) ? 'assignUser' : 'unassignUser',
              {'userId': id, 'type': 0, 'user': user},
            );
          }
        });
        unawaited(widget.session.refreshStacks(board.id));
      },
    );
  }
}
