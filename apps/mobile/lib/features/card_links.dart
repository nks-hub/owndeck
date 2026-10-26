import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_detail.dart';
import 'state_message.dart';
import 'sync_state.dart';

class CardLinksScreen extends StatefulWidget {
  const CardLinksScreen({
    super.key,
    required this.session,
    required this.boardId,
    required this.cardId,
  });
  final DeckSession session;
  final int boardId;
  final int cardId;
  @override
  State<CardLinksScreen> createState() => _CardLinksScreenState();
}

class _CardLinksScreenState extends State<CardLinksScreen> {
  late final _board = widget.session.database.watchBoard(
    widget.session.account.id,
    widget.boardId,
  );
  late final _card = widget.session.database.watchCard(
    widget.session.account.id,
    widget.boardId,
    widget.cardId,
  );
  late final _candidates = widget.session.database.watchCardSearch(
    widget.session.account.id,
    const CardSearchOptions(includeArchived: true, includeCompleted: true),
  );
  bool _busy = false;

  Future<void> _change(
    DeckCard card,
    CardSearchHit target, {
    required bool add,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.session.database.queueCardAction(
        widget.session.account,
        widget.boardId,
        card,
        add ? 'addCardLink' : 'removeCardLink',
        {
          'title': card.title,
          'dependentCardId': target.card.id,
          'dependentBoardId': target.board.id,
          'dependentStackId': target.stack.id,
        },
      );
      unawaited(widget.session.refreshStacks(widget.boardId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pendingDecision),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(DeckCard card, List<CardSearchHit> candidates) async {
    final target = await showModalBottomSheet<CardSearchHit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CardLinkPicker(
        candidates: candidates
            .where(
              (hit) =>
                  hit.card.id != card.id &&
                  !card.dependentCards.contains(hit.card.id),
            )
            .toList(),
      ),
    );
    if (target != null && mounted) await _change(card, target, add: true);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(text.linkedCards)),
      body: StreamBuilder<DeckBoard?>(
        stream: _board,
        builder: (context, board) => StreamBuilder<DeckCard?>(
          stream: _card,
          builder: (context, card) => StreamBuilder<CardSearchResult>(
            stream: _candidates,
            builder: (context, candidates) {
              if (board.hasError || card.hasError || candidates.hasError) {
                return Center(child: StateMessage(message: text.localReadError));
              }
              if (!board.hasData || !card.hasData || !candidates.hasData) {
                final waiting = [
                  board.connectionState,
                  card.connectionState,
                  candidates.connectionState,
                ].contains(ConnectionState.waiting);
                return Center(
                  child: waiting
                      ? const CircularProgressIndicator()
                      : StateMessage(
                          message: text.cardUnavailable,
                          actionLabel: text.close,
                          onAction: () => Navigator.maybePop(context),
                        ),
                );
              }
              final source = card.requireData!;
              final parent = board.requireData!;
              if (!parent.permissions.read ||
                  parent.deletedAt != 0 ||
                  !candidates.requireData.accountAvailable) {
                return Center(
                  child: StateMessage(
                    message: text.cardUnavailable,
                    actionLabel: text.close,
                    onAction: () => Navigator.maybePop(context),
                  ),
                );
              }
              final canEdit =
                  parent.permissions.edit &&
                  !parent.archived &&
                  !source.archived;
              final targets = {
                for (final candidate in candidates.requireData.hits)
                  candidate.card.id: candidate,
              };
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(text.cardLinksDescription),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (source.raw['syncState'] != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        syncStateLabel(source.raw['syncState'], text),
                      ),
                    ),
                  if (canEdit)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _add(source, targets.values.toList()),
                        icon: const Icon(Icons.add_link),
                        label: Text(text.addCardLink),
                      ),
                    ),
                  if (source.dependentCards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(text.noLinkedCards),
                    ),
                  for (final id in source.dependentCards)
                    if (targets[id] case final CardSearchHit target)
                      ListTile(
                        leading: const Icon(Icons.link),
                        title: Text(target.card.title),
                        subtitle: Text(
                          '${target.board.title} · ${target.stack.title}',
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(name: '/card'),
                            builder: (_) => CardScreen(
                              session: widget.session,
                              board: target.board,
                              card: target.card,
                            ),
                          ),
                        ),
                        trailing: canEdit
                            ? IconButton(
                                tooltip: text.removeCardLink,
                                icon: const Icon(Icons.link_off),
                                onPressed: _busy
                                    ? null
                                    : () => _change(source, target, add: false),
                              )
                            : null,
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.link_off),
                        title: Text(text.linkedCardUnavailable),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardLinkPicker extends StatefulWidget {
  const _CardLinkPicker({required this.candidates});
  final List<CardSearchHit> candidates;
  @override
  State<_CardLinkPicker> createState() => _CardLinkPickerState();
}

class _CardLinkPickerState extends State<_CardLinkPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final matches = widget.candidates
        .where(
          (hit) => '${hit.card.title}\n${hit.board.title}\n${hit.stack.title}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: text.searchCards,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(text.cardLinkCachedOnly),
                ),
              ),
              if (matches.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(text.noLinkCandidates),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final hit = matches[index];
                    return ListTile(
                      title: Text(hit.card.title),
                      subtitle: Text('${hit.board.title} · ${hit.stack.title}'),
                      onTap: () => Navigator.pop(context, hit),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
