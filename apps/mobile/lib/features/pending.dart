import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'drafts.dart';
import 'color_choices.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  Map<String, String> _cardFields(JsonObject value, Set<String> fields) {
    final text = AppLocalizations.of(context)!;
    String textField(String key) => switch (value[key]) {
      String value => value,
      null => '',
      _ => text.pendingValueUnavailable,
    };
    String dateValue(Object? value) {
      if (value == null || value == '') return text.pendingValueNotSet;
      final date = switch (value) {
        String value => DateTime.tryParse(value),
        int value when value >= 0 && value <= 253402300799 =>
          DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true),
        _ => null,
      };
      if (date == null || date.year < 1 || date.year > 9999) {
        return text.pendingValueUnavailable;
      }
      final localDate = date.toLocal();
      final local = MaterialLocalizations.of(context);
      final time = local.formatTimeOfDay(
        TimeOfDay.fromDateTime(localDate),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return '${local.formatMediumDate(localDate)} $time';
    }

    String dateField(String key) => value.containsKey(key)
        ? dateValue(value[key])
        : text.pendingValueUnavailable;
    final color = value['color'];
    final colorValue = !value.containsKey('color')
        ? text.pendingValueUnavailable
        : color == null || color == ''
        ? text.pendingValueNotSet
        : color is String && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(color)
        ? colorName(color, text)
        : text.pendingValueUnavailable;
    final done = value['done'];
    final completion = !value.containsKey('done')
        ? text.pendingValueUnavailable
        : done == null
        ? text.pendingNotCompleted
        : dateValue(done);
    return {
      text.cardTitle: textField('title'),
      text.description: textField('description'),
      text.dueDate: dateField('duedate'),
      if (fields.contains('startdate')) text.startDate: dateField('startdate'),
      if (fields.contains('color')) text.cardColor: colorValue,
      if (fields.contains('done')) text.pendingCompletion: completion,
    };
  }

  String _attachmentSummary(JsonObject value) {
    final raw = value['name'] ?? value['data'];
    final name = raw is String ? raw.split(RegExp(r'[/\\]')).last : '';
    return name.isEmpty ? AppLocalizations.of(context)!.attachments : name;
  }

  String _filter = 'all';
  final _deciding = <String>{};
  late final _writes = widget.session.database.watchWrites(
    widget.session.account.id,
  );
  late final _drafts = widget.session.database.watchEditorDrafts(
    widget.session.account.id,
  );
  late final _boards = widget.session.watchBoards();

  bool _transferAccepted(PendingWrite write) {
    if (write.kind != 'cardTransfer') return false;
    final proposal = object(jsonDecode(write.proposal));
    if (proposal['transferReceipt'] is Map) return true;
    if (write.state != 'applied' || write.remote == null) return false;
    final receipt = object(jsonDecode(write.remote!));
    return receipt['phase'] == 'transfer' && receipt['acceptedCard'] is Map;
  }

  String _decisionLabel(PendingWrite write, bool discard) {
    final text = AppLocalizations.of(context)!;
    if (_transferAccepted(write)) {
      return discard ? text.discardWrite : text.retry;
    }
    if (write.state == 'conflict') {
      return discard ? text.keepServerVersion : text.useLocalChanges;
    }
    return discard ? text.discardWrite : text.retryWrite;
  }

  String _decisionMessage(PendingWrite write, bool discard) {
    final text = AppLocalizations.of(context)!;
    if (_transferAccepted(write)) {
      return discard
          ? text.confirmKeepServerVersion
          : text.confirmTransferRetry;
    }
    if (write.state == 'conflict') {
      return discard
          ? text.confirmKeepServerVersion
          : text.confirmUseLocalChanges;
    }
    if (discard) return text.confirmDiscard;
    return write.state == 'uncertain' ? text.confirmRetry : text.blocked;
  }

  Future<void> _refreshTransfer(PendingWrite write, bool discard) async {
    final session = widget.session;
    final proposal = object(jsonDecode(write.proposal));
    final receipt = proposal['transferReceipt'] is Map
        ? object(proposal['transferReceipt'])
        : write.remote == null
        ? <String, Object?>{}
        : object(jsonDecode(write.remote!));
    final boards = <int>{};
    for (final id in {
      receipt['sourceBoardId'] ?? write.boardId,
      proposal['destinationBoardId'],
      receipt['boardId'],
    }.whereType<int>()) {
      boards.add(
        await session.database.resolveId(
              session.account.id,
              id,
              'createBoard',
            ) ??
            id,
      );
    }
    if (!discard) {
      await session.refreshStacks(write.boardId);
      boards.remove(
        await session.database.resolveId(
              session.account.id,
              write.boardId,
              'createBoard',
            ) ??
            write.boardId,
      );
    }
    await Future.wait([
      for (final id in boards) session.refreshStacks(id, syncPending: false),
    ]);
  }

  Future<void> _decide(PendingWrite write, bool discard) async {
    if (!_deciding.add(write.id)) return;
    setState(() {});
    final text = AppLocalizations.of(context)!;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_decisionLabel(write, discard)),
          content: SingleChildScrollView(
            child: Text(_decisionMessage(write, discard)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_decisionLabel(write, discard)),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.session.database.decideWrite(
        widget.session.account.id,
        write.id,
        discard: discard,
        acceptRemoteBase: !discard && write.state == 'conflict',
      );
      if (write.kind == 'cardTransfer') {
        await _refreshTransfer(write, discard);
      } else if (write.boardId == 0 ||
          write.kind.endsWith('Board') ||
          write.kind == 'boardClone') {
        unawaited(widget.session.refreshBoards());
      } else {
        unawaited(widget.session.refreshStacks(write.boardId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error, text))));
      }
    } finally {
      _deciding.remove(write.id);
      if (mounted) setState(() {});
    }
  }

  bool _matches(PendingWrite write) => switch (_filter) {
    'waiting' => {'queued', 'sending', 'applied'}.contains(write.state),
    'conflict' => write.state == 'conflict',
    'uncertain' => write.state == 'uncertain',
    'blocked' => write.state == 'blocked',
    _ => true,
  };

  String _operation(PendingWrite write) {
    final text = AppLocalizations.of(context)!;
    return switch (write.kind) {
      'createCard' => text.addCard,
      'updateCard' => text.editCard,
      'moveCard' || 'cardTransfer' => text.moveCard,
      'cloneCard' => text.copyCard,
      'archiveCard' => text.archive,
      'unarchiveCard' => text.unarchive,
      'deleteCard' => text.deleteCard,
      'createBoard' => text.addBoard,
      'updateBoard' => text.editBoard,
      'deleteBoard' => text.deleteBoard,
      'restoreBoard' => text.restoreBoard,
      'boardClone' => text.copyBoard,
      'createStack' => text.addStack,
      'updateStack' || 'stackReorder' => text.editStack,
      'deleteStack' => text.deleteStack,
      'setDoneStack' => text.doneColumn,
      'createAcl' || 'updateAcl' || 'deleteAcl' => text.sharing,
      'createComment' => text.addComment,
      'updateComment' => text.editComment,
      'deleteComment' => text.deleteComment,
      'assignLabel' ||
      'removeLabel' ||
      'createLabel' ||
      'updateLabel' ||
      'deleteLabel' => text.labels,
      'assignUser' || 'unassignUser' => text.assignees,
      'addCardLink' || 'removeCardLink' => text.linkedCards,
      _ =>
        attachmentKinds.contains(write.kind)
            ? text.attachments
            : text.pendingChanges,
    };
  }

  String _stateMessage(PendingWrite write) {
    final text = AppLocalizations.of(context)!;
    if (write.error == 'already_shared') return text.alreadyShared;
    if (write.error == 'dependency_unavailable') {
      return text.dependencyUnavailable;
    }
    if (write.error == 'permission_denied') return text.permissionError;
    if (write.error == 'card_moved') return text.invalidDestination;
    return switch (write.state) {
      'queued' => text.savedLocally,
      'sending' => text.sending,
      'applied' => text.awaitingReadback,
      'conflict' => text.pendingConflictHelp,
      'uncertain' => text.uncertain,
      _ => text.blocked,
    };
  }

  IconData _stateIcon(PendingWrite write) => switch (write.state) {
    'queued' => Icons.cloud_upload_outlined,
    'sending' || 'applied' => Icons.sync,
    'conflict' => Icons.compare_arrows,
    'uncertain' => Icons.help_outline,
    _ => Icons.error_outline,
  };

  Widget _version(
    String title,
    Map<String, String> fields,
    Set<String> changed, {
    Object? color,
  }) {
    final text = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final field in fields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: changed.contains(field.key)
                      ? colors.secondaryContainer
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              field.key,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          if (changed.contains(field.key))
                            Tooltip(
                              message: text.changedField,
                              child: const Icon(Icons.compare_arrows, size: 18),
                            ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((field.key == text.cardColor ||
                                  field.key == text.color) &&
                              color is String &&
                              RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(color))
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsetsDirectional.only(end: 8),
                              decoration: BoxDecoration(
                                color: Color(
                                  0xff000000 | int.parse(color, radix: 16),
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.outline),
                              ),
                            ),
                          Expanded(
                            child: SelectableText(
                              field.value.isEmpty
                                  ? text.pendingValueNotSet
                                  : field.value,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardComparison(JsonObject local, JsonObject? remote) {
    final keys = {...local.keys, if (remote != null) ...remote.keys};
    return _versions(
      _cardFields(local, keys),
      remote == null ? null : _cardFields(remote, keys),
      localColor: local['color'],
      remoteColor: remote?['color'],
    );
  }

  Map<String, String> _metadataFields(JsonObject value, Set<String> fields) {
    final text = AppLocalizations.of(context)!;
    String field(String key) => !value.containsKey(key)
        ? text.pendingValueUnavailable
        : _textValue(value[key]);
    final participant = value['participant'];
    final displayName =
        value['displayName'] ??
        (participant is Map
            ? participant['displayname'] ?? participant['displayName']
            : null);
    return {
      if (fields.contains('title')) text.name: field('title'),
      if (fields.contains('displayName') || fields.contains('participant'))
        text.name: displayName is String && displayName.isNotEmpty
            ? displayName
            : text.pendingValueUnavailable,
      if (fields.contains('color'))
        text.color: value.containsKey('color')
            ? colorName(value['color'], text)
            : text.pendingValueUnavailable,
      if (fields.contains('archived'))
        text.archive: !value.containsKey('archived')
            ? text.pendingValueUnavailable
            : value['archived'] == true
            ? text.archivedBoards
            : text.activeBoards,
      for (final entry in <String, String>{
        'permissionRead': text.permissionRead,
        'permissionEdit': text.permissionEdit,
        'permissionShare': text.permissionShare,
        'permissionManage': text.permissionManage,
      }.entries)
        if (fields.contains(entry.key))
          entry.value: value[entry.key] is! bool
              ? text.pendingValueUnavailable
              : value[entry.key] == true
              ? text.permissionAllowed
              : text.permissionNotAllowed,
    };
  }

  Widget _versions(
    Map<String, String> localFields,
    Map<String, String>? serverFields, {
    Object? localColor,
    Object? remoteColor,
  }) {
    final text = AppLocalizations.of(context)!;
    final changed = <String>{
      if (serverFields != null)
        for (final key in localFields.keys)
          if (localFields[key] != serverFields[key] ||
              (key == text.cardColor || key == text.color) &&
                  localColor != remoteColor)
            key,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final localWidget = _version(
          text.localVersion,
          localFields,
          changed,
          color: localColor,
        );
        if (serverFields == null) return localWidget;
        final serverWidget = _version(
          text.serverVersion,
          serverFields,
          changed,
          color: remoteColor,
        );
        if (constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) >=
            620) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: localWidget),
              const SizedBox(width: 12),
              Expanded(child: serverWidget),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [localWidget, const SizedBox(height: 12), serverWidget],
        );
      },
    );
  }

  String _textValue(Object? value) => value is String ? value : '';

  Future<({int boardId, int stackId})> _transferIds(JsonObject changes) async {
    final boardId = intField(changes, 'destinationBoardId');
    final stackId = intField(changes, 'destinationStackId');
    final session = widget.session;
    final ids = await Future.wait([
      session.database.resolveId(session.account.id, boardId, 'createBoard'),
      session.database.resolveId(session.account.id, stackId, 'createStack'),
    ]);
    return (boardId: ids[0] ?? boardId, stackId: ids[1] ?? stackId);
  }

  Widget _transferDestination(JsonObject changes, Map<int, String> boardNames) {
    final text = AppLocalizations.of(context)!;
    final boardId = intField(changes, 'destinationBoardId');
    final stackId = intField(changes, 'destinationStackId');
    return FutureBuilder<({int boardId, int stackId})>(
      key: ValueKey((boardId, stackId)),
      future: _transferIds(changes),
      initialData: (boardId: boardId, stackId: stackId),
      builder: (context, ids) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${text.destinationBoard}: ${boardNames[ids.data?.boardId] ?? text.pendingValueUnavailable}',
          ),
          StreamBuilder<List<DeckStack>>(
            key: ValueKey(ids.data),
            stream: ids.hasError
                ? null
                : widget.session.watchStacks(ids.data!.boardId),
            builder: (context, snapshot) {
              final stack = snapshot.data
                  ?.where((stack) => stack.id == ids.data?.stackId)
                  .firstOrNull;
              return Text(
                '${text.destinationColumn}: ${stack?.title ?? text.pendingValueUnavailable}',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _writeCard(PendingWrite write, Map<int, String> boardNames) {
    final text = AppLocalizations.of(context)!;
    final changes = object(jsonDecode(write.proposal));
    final base = write.base == null
        ? <String, Object?>{}
        : object(jsonDecode(write.base!));
    final remote = write.remote == null
        ? null
        : object(jsonDecode(write.remote!));
    final attachment = attachmentKinds.contains(write.kind);
    final card = write.kind == 'createCard' || write.kind == 'updateCard';
    final remoteCard = card && remote?['acceptedCard'] is Map
        ? object(remote!['acceptedCard'])
        : remote;
    final title = [
      changes['displayName'],
      changes['name'],
      changes['title'],
      base['title'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).firstOrNull;
    final metadata = const {
      'createBoard',
      'updateBoard',
      'restoreBoard',
      'deleteBoard',
      'createStack',
      'updateStack',
      'deleteStack',
      'createLabel',
      'updateLabel',
      'deleteLabel',
      'createAcl',
      'updateAcl',
      'deleteAcl',
    }.contains(write.kind);
    final fields = {
      ...base.keys,
      ...changes.keys,
      if (remote != null) ...remote.keys,
    };
    final localMetadata = metadata
        ? _metadataFields({...base, ...changes}, fields)
        : <String, String>{};
    final busy = _deciding.contains(write.id) || write.state == 'sending';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _operation(write),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            if (write.kind != 'cardTransfer')
              if (boardNames[write.boardId] case final String board)
                Text(board, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (_transferAccepted(write))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(text.transferPositionPending),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_stateIcon(write)),
                const SizedBox(width: 8),
                Expanded(child: Text(_stateMessage(write))),
              ],
            ),
            const SizedBox(height: 16),
            if (write.kind == 'cardTransfer')
              _transferDestination(changes, boardNames)
            else if (card && write.state == 'conflict')
              _cardComparison({...base, ...changes}, remoteCard)
            else if (card)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(text.localVersion),
                subtitle: Text(
                  _textValue(changes['description'] ?? base['description']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  _cardComparison({...base, ...changes}, remoteCard),
                ],
              )
            else if (metadata && localMetadata.isNotEmpty)
              _versions(
                localMetadata,
                remote == null ? null : _metadataFields(remote, fields),
                localColor: changes.containsKey('color')
                    ? changes['color']
                    : base['color'],
                remoteColor: remote?['color'],
              )
            else ...[
              Text(
                text.localVersion,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SelectableText(
                attachment
                    ? _attachmentSummary({...base, ...changes})
                    : _textValue(
                        changes['message'] ??
                            changes['description'] ??
                            base['message'] ??
                            base['description'],
                      ),
              ),
              if (remote != null &&
                  (!attachment ||
                      remote['data'] is String ||
                      remote['name'] is String)) ...[
                const Divider(height: 24),
                Text(
                  text.serverVersion,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SelectableText(
                  attachment
                      ? _attachmentSummary(remote)
                      : [
                          _textValue(remote['title']),
                          _textValue(
                            remote['message'] ?? remote['description'],
                          ),
                        ].where((value) => value.isNotEmpty).join('\n'),
                ),
              ],
            ],
            if (write.state != 'sending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (write.state != 'queued' && write.state != 'applied')
                      FilledButton.tonal(
                        onPressed: busy ? null : () => _decide(write, false),
                        child: Text(_decisionLabel(write, false)),
                      ),
                    TextButton(
                      onPressed: busy ? null : () => _decide(write, true),
                      child: Text(_decisionLabel(write, true)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDrafts() => unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/drafts'),
        builder: (_) => DraftsScreen(session: widget.session),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.pendingChanges),
        actions: [
          IconButton(
            tooltip: text.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: widget.session.refreshBoards,
          ),
        ],
      ),
      body: StreamBuilder<List<DeckBoard>>(
        stream: _boards,
        builder: (context, boards) => StreamBuilder<List<PendingWrite>>(
          stream: _writes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(text.storageError));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.requireData;
            final writes = all.where(_matches).toList();
            final names = {
              for (final board in boards.data ?? <DeckBoard>[])
                board.id: board.title,
            };
            final filters = <String, String>{
              'all': text.allChanges,
              'waiting': text.pendingWaiting,
              'conflict': text.pendingConflicts,
              'uncertain': text.pendingUncertain,
              'blocked': text.needsDecision,
            };
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: writes.length + 1,
              itemBuilder: (context, index) {
                if (index > 0) return _writeCard(writes[index - 1], names);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<List<EditorDraft>>(
                      stream: _drafts,
                      builder: (context, drafts) => ListTile(
                        leading: const Icon(Icons.drafts_outlined),
                        title: Text(text.drafts),
                        subtitle: drafts.hasError
                            ? Text(text.storageError)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (drafts.hasData)
                              Text('${drafts.requireData.length}'),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: _openDrafts,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final entry in filters.entries)
                            ChoiceChip(
                              label: Text(entry.value),
                              selected: _filter == entry.key,
                              onSelected: (_) =>
                                  setState(() => _filter = entry.key),
                            ),
                        ],
                      ),
                    ),
                    if (writes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              all.isEmpty
                                  ? text.noPending
                                  : text.pendingEmptyGroup,
                            ),
                            if (all.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _filter = 'all'),
                                child: Text(text.allChanges),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
