import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

typedef _Edit = TextEditingValue Function(TextEditingValue);

final _listLine = RegExp(r'^(\s*)([-*+] \[[ xX]\] |[-*+] |(\d+)\. )(.*)$');

/// Continues a Markdown list when Enter is typed and ends it on an empty item.
final class MarkdownListFormatter extends TextInputFormatter {
  const MarkdownListFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final caret = newValue.selection.baseOffset;
    if (!newValue.selection.isCollapsed ||
        text.length != oldValue.text.length + 1 ||
        caret < 1 ||
        text[caret - 1] != '\n' ||
        oldValue.text != text.replaceRange(caret - 1, caret, '')) {
      return newValue;
    }
    final lineStart = caret < 2 ? 0 : text.lastIndexOf('\n', caret - 2) + 1;
    final match = _listLine.firstMatch(text.substring(lineStart, caret - 1));
    if (match == null) return newValue;
    if (match[4]!.trim().isEmpty) {
      return TextEditingValue(
        text: text.replaceRange(lineStart, caret, ''),
        selection: TextSelection.collapsed(offset: lineStart),
      );
    }
    final number = match[3];
    final marker = match[2]!.contains('[')
        ? '${match[2]!.substring(0, 2)}[ ] '
        : number == null
        ? match[2]!
        : '${int.parse(number) + 1}. ';
    final insert = '${match[1]}$marker';
    return TextEditingValue(
      text: text.replaceRange(caret, caret, insert),
      selection: TextSelection.collapsed(offset: caret + insert.length),
    );
  }
}

/// Wraps the selection in [mark] on both sides, or inserts an empty pair.
TextEditingValue wrapMarkdown(TextEditingValue value, String mark) {
  final selection = _selection(value);
  final text = value.text;
  final inner = selection.textInside(text);
  return TextEditingValue(
    text: text.replaceRange(selection.start, selection.end, '$mark$inner$mark'),
    selection: TextSelection(
      baseOffset: selection.start + mark.length,
      extentOffset: selection.start + mark.length + inner.length,
    ),
  );
}

/// Starts every line touched by the selection with [prefix].
TextEditingValue prefixMarkdownLines(TextEditingValue value, String prefix) {
  final selection = _selection(value);
  final text = value.text;
  final start = selection.start == 0
      ? 0
      : text.lastIndexOf('\n', selection.start - 1) + 1;
  final lines = text.substring(start, selection.end).split('\n');
  final block = lines.map((line) => '$prefix$line').join('\n');
  return TextEditingValue(
    text: text.replaceRange(start, selection.end, block),
    selection: TextSelection(
      baseOffset: selection.start + prefix.length,
      extentOffset: selection.end + prefix.length * lines.length,
    ),
  );
}

/// Turns the selection into `[selection]()` and places the caret in the URL.
TextEditingValue linkMarkdown(TextEditingValue value) {
  final selection = _selection(value);
  final text = value.text;
  final label = selection.textInside(text);
  return TextEditingValue(
    text: text.replaceRange(selection.start, selection.end, '[$label]()'),
    selection: TextSelection.collapsed(
      offset: selection.start + (label.isEmpty ? 1 : label.length + 3),
    ),
  );
}

TextSelection _selection(TextEditingValue value) {
  final s = value.selection;
  if (!s.isValid) return TextSelection.collapsed(offset: value.text.length);
  return TextSelection(
    baseOffset: min(s.start, value.text.length),
    extentOffset: min(s.end, value.text.length),
  );
}

/// A multiline text field with list continuation and a Markdown toolbar.
class MarkdownField extends StatefulWidget {
  const MarkdownField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.decoration,
    this.enabled = true,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final bool enabled;

  @override
  State<MarkdownField> createState() => _MarkdownFieldState();
}

class _MarkdownFieldState extends State<MarkdownField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _apply(_Edit edit) {
    widget.controller.value = edit(widget.controller.value);
    _focus.requestFocus();
    widget.onChanged(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final buttons = <(String, IconData, String, _Edit)>[
      (
        'md-bold',
        Icons.format_bold,
        text.formatBold,
        (v) => wrapMarkdown(v, '**'),
      ),
      (
        'md-list',
        Icons.format_list_bulleted,
        text.formatList,
        (v) => prefixMarkdownLines(v, '- '),
      ),
      (
        'md-checklist',
        Icons.checklist,
        text.formatChecklist,
        (v) => prefixMarkdownLines(v, '- [ ] '),
      ),
      ('md-link', Icons.link, text.formatLink, linkMarkdown),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (key, icon, tooltip, edit) in buttons)
              IconButton(
                key: ValueKey(key),
                tooltip: tooltip,
                icon: Icon(icon),
                onPressed: widget.enabled ? () => _apply(edit) : null,
              ),
          ],
        ),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          minLines: 5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          inputFormatters: const [MarkdownListFormatter()],
          onChanged: widget.onChanged,
          decoration: widget.decoration,
        ),
      ],
    );
  }
}
