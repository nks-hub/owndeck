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

  /// Boards open natively when saved; everything else goes through [_link].
  Future<void> _openProject(ProjectResource resource) async {
    final target = resource.openUri(widget.session.client.base);
    if (resource.type == 'deck') {
      final id = int.tryParse(resource.id);
      final boards = await widget.session.database.boardView(
        widget.session.account.id,
      );
      final board = boards.where((b) => b.id == id && b.deletedAt == 0);
      if (!mounted) return;
      if (board.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/board'),
            builder: (_) =>
                BoardScreen(session: widget.session, board: board.first),
          ),
        );
        return;
      }
    }
    await _link(target?.toString());
  }

  Future<void> _share(DeckBoard board, DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final locale = MaterialLocalizations.of(context);
    final link = DeckCardLink(
      server: widget.session.client.base,
      boardId: board.id,
      cardId: card.id,
    );
    try {
      await textSharer(
        cardShareText(
          card: card,
          link: link.webUri,
          text: text,
          locale: locale,
        ),
        subject: card.title,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.shareError)));
      }
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

  Future<void> _delete(DeckCard card) => deleteCardWithConfirmation(
    context,
    widget.session,
    widget.board.id,
    card,
  );

  Future<void> _move(DeckBoard board, DeckCard card) => showBoardCardMove(
    context,
    widget.session,
    board,
    card,
    onTransferred: () {
      if (mounted) closeCard(context);
    },
  );

  Future<void> _labels(DeckBoard board, DeckCard card) =>
      chooseCardLabels(context, widget.session, board, card);

  Future<void> _users(DeckBoard board, DeckCard card) async {
    final text = AppLocalizations.of(context)!;
    final users = <String, ({String id, int type, JsonObject user})>{};
    for (final user in _items(board.raw['users'])) {
      final id = _uid(user);
      if (id.isEmpty) continue;
      users['0:$id'] = (id: id, type: 0, user: user);
    }
    final capabilities = widget.session.capabilities;
    final offeredTypes = {
      if (capabilities?.supportsGroupAssignment == true) 1,
      if (capabilities?.supportsTeamAssignment == true) 7,
    };
    // The server only accepts groups and teams that are shared with the board.
    for (final entry in _items(board.raw['acl'])) {
      final type = entry['type'];
      final participant = entry['participant'];
      final id = shareParticipantId(participant);
      if (!offeredTypes.contains(type) || id.isEmpty) continue;
      users.putIfAbsent(
        '$type:$id',
        () => (
          id: id,
          type: type as int,
          user: participant is JsonObject
              ? participant
              : <String, Object?>{'displayname': id},
        ),
      );
    }
    final assigned = <String>{};
    for (final assignment in _items(card.raw['assignedUsers'])) {
      final participant = assignment['participant'];
      final id = _uid(participant);
      if (id.isEmpty) continue;
      final type = assignment['type'] is int ? assignment['type'] as int : 0;
      final key = '$type:$id';
      assigned.add(key);
      users.putIfAbsent(
        key,
        () => (
          id: id,
          type: type,
          user: participant is JsonObject
              ? participant
              : <String, Object?>{'uid': id},
        ),
      );
    }
    String name(JsonObject user, int type) {
      for (final key in ['displayname', 'displayName', 'name']) {
        final value = user[key];
        if (value is String && value.trim().isNotEmpty) {
          return switch (type) {
            1 => '$value (${text.group})',
            7 => '$value (${text.team})',
            _ => value,
          };
        }
      }
      return switch (type) {
        0 => text.user,
        1 => text.group,
        6 => text.externalRecipient,
        7 => text.team,
        _ => text.pendingValueUnavailable,
      };
    }

    await showCardSelection(
      context,
      title: text.assignees,
      emptyMessage: text.noUsers,
      options: {
        for (final entry in users.entries)
          entry.key: name(entry.value.user, entry.value.type),
      },
      selected: assigned,
      onSave: (selected) async {
        await widget.session.database.transaction(() async {
          for (final entry in users.entries) {
            final key = entry.key;
            final user = entry.value;
            if (assigned.contains(key) == selected.contains(key)) continue;
            await widget.session.database.queueCardAction(
              widget.session.account,
              board.id,
              card,
              selected.contains(key) ? 'assignUser' : 'unassignUser',
              {'userId': user.id, 'type': user.type, 'user': user.user},
            );
          }
        });
        unawaited(widget.session.refreshStacks(board.id));
      },
    );
  }
}
