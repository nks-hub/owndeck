import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../l10n/app_localizations.dart';

Future<void> showCardSelection(
  BuildContext context, {
  required String title,
  required String emptyMessage,
  required Map<String, String> options,
  required Set<String> selected,
  required Future<void> Function(Set<String>) onSave,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  showDragHandle: false,
  builder: (_) => _CardSelection(
    title: title,
    emptyMessage: emptyMessage,
    options: options,
    selected: selected,
    onSave: onSave,
  ),
);

class _CardSelection extends StatefulWidget {
  const _CardSelection({
    required this.title,
    required this.emptyMessage,
    required this.options,
    required this.selected,
    required this.onSave,
  });
  final String title;
  final String emptyMessage;
  final Map<String, String> options;
  final Set<String> selected;
  final Future<void> Function(Set<String>) onSave;
  @override
  State<_CardSelection> createState() => _CardSelectionState();
}

class _CardSelectionState extends State<_CardSelection> {
  late final _selected = {...widget.selected};
  bool _saving = false;
  Object? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(Set.unmodifiable(_selected));
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final options = widget.options.entries.toList();
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_saving) const LinearProgressIndicator(),
              Expanded(
                child: options.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(widget.emptyMessage),
                        ),
                      )
                    : ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return CheckboxListTile(
                            title: Text(option.value),
                            value: _selected.contains(option.key),
                            onChanged: _saving
                                ? null
                                : (value) => setState(() {
                                    if (value == true) {
                                      _selected.add(option.key);
                                    } else {
                                      _selected.remove(option.key);
                                    }
                                  }),
                          );
                        },
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(errorMessage(_error!, text)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(text.cancel),
                    ),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(text.selectionDone),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
