import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';

Future<void> editSharePermissions(
  BuildContext context,
  DeckSession session,
  DeckBoard board, {
  DeckShareTarget? target,
  JsonObject? original,
}) async {
  final text = AppLocalizations.of(context)!;
  var edit = original?['permissionEdit'] == true;
  var share = original?['permissionShare'] == true;
  var manage = original?['permissionManage'] == true;
  var saving = false;
  String? error;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(original == null ? text.addShare : text.editShare),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (target != null) Text(target.label),
              CheckboxListTile(
                value: true,
                onChanged: null,
                title: Text(text.permissionRead),
              ),
              CheckboxListTile(
                value: edit,
                title: Text(text.permissionEdit),
                onChanged:
                    !saving &&
                        (board.permissions.edit || board.permissions.manage)
                    ? (v) => setState(() => edit = v!)
                    : null,
              ),
              CheckboxListTile(
                value: share,
                title: Text(text.permissionShare),
                onChanged:
                    !saving &&
                        (board.permissions.share || board.permissions.manage)
                    ? (v) => setState(() => share = v!)
                    : null,
              ),
              CheckboxListTile(
                value: manage,
                title: Text(text.permissionManage),
                onChanged: !saving && board.permissions.manage
                    ? (v) => setState(() => manage = v!)
                    : null,
              ),
              if (error != null)
                Semantics(liveRegion: true, child: Text(error!)),
              if (saving) const LinearProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: Text(text.cancel),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final proposal = <String, Object?>{
                        if (original == null ||
                            edit != original['permissionEdit'])
                          'permissionEdit': edit,
                        if (original == null ||
                            share != original['permissionShare'])
                          'permissionShare': share,
                        if (original == null ||
                            manage != original['permissionManage'])
                          'permissionManage': manage,
                        if (target != null) ...{
                          'type': target.type,
                          'participant': target.id,
                          'displayName': target.label,
                        },
                      };
                      if (proposal.isNotEmpty) {
                        await session.database.queueBoardMetadata(
                          session.account,
                          board.id,
                          original == null ? 'createAcl' : 'updateAcl',
                          proposal,
                          original: original,
                        );
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      unawaited(session.refreshStacks(board.id));
                    } catch (e) {
                      if (dialogContext.mounted) {
                        setState(() {
                          saving = false;
                          error = errorMessage(
                            e,
                            text,
                            fallback: text.permissionError,
                          );
                        });
                      }
                    }
                  },
            child: Text(text.save),
          ),
        ],
      ),
    ),
  );
}
