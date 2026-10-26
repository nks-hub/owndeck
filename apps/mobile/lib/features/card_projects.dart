import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';

/// Files, Talk rooms, cards and boards linked to a card through Nextcloud
/// projects. It stays hidden when the server has none or does not answer.
class CardProjects extends StatefulWidget {
  const CardProjects({
    super.key,
    required this.session,
    required this.cardId,
    required this.open,
  });
  final DeckSession session;
  final int cardId;
  final ValueChanged<ProjectResource> open;

  @override
  State<CardProjects> createState() => _CardProjectsState();
}

class _CardProjectsState extends State<CardProjects> {
  List<CardProject> _projects = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final projects = await widget.session.client.cardProjects(widget.cardId);
      if (mounted) setState(() => _projects = projects);
    } catch (_) {
      // A missing route, a 404 or being offline all mean "nothing to show".
    }
  }

  IconData _icon(String type) => switch (type) {
    'file' => Icons.insert_drive_file_outlined,
    'room' => Icons.chat_bubble_outline,
    'deck' => Icons.view_kanban_outlined,
    'deck-card' => Icons.view_agenda_outlined,
    _ => Icons.link,
  };

  @override
  Widget build(BuildContext context) {
    if (_projects.isEmpty) return const SizedBox.shrink();
    final text = AppLocalizations.of(context)!;
    final base = widget.session.client.base;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(text.projects, style: Theme.of(context).textTheme.titleMedium),
        for (final project in _projects) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              project.name,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final resource in project.resources)
            ListTile(
              key: ValueKey((project.id, resource.type, resource.id)),
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icon(resource.type)),
              title: Text(resource.name),
              onTap: resource.type == 'deck' || resource.openUri(base) != null
                  ? () => widget.open(resource)
                  : null,
            ),
        ],
      ],
    );
  }
}
