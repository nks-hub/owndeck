import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

final class MarkdownTask {
  const MarkdownTask({
    required this.offset,
    required this.checked,
    required this.label,
  });
  final int offset;
  final bool checked;
  final String label;
}

List<MarkdownTask> markdownTasks(String source) {
  final pattern = RegExp(
    r'^([ \t]*(?:>[ \t]*)*(?:[-+*]|\d+[.)])[ \t]+\[)([ xX])(\][ \t]+)',
    multiLine: true,
  );
  final candidates = pattern.allMatches(source).toList();
  if (candidates.isEmpty) return const [];
  var prefix = 'OWNDECK_TASK_';
  while (source.contains(prefix)) {
    prefix += '_';
  }
  final marked = StringBuffer();
  var end = 0;
  for (var i = 0; i < candidates.length; i++) {
    final match = candidates[i];
    marked.write(source.substring(end, match.end));
    marked.write('\u{f0000}$prefix$i\u{f0001}');
    end = match.end;
  }
  marked.write(source.substring(end));
  final marker = RegExp('\u{f0000}$prefix(\\d+)\u{f0001}');
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  final nodes = document.parseLines(
    const LineSplitter().convert(marked.toString()),
  );
  final result = <MarkdownTask>[];

  // Let the Markdown parser distinguish real tasks from code blocks and HTML.
  void visit(md.Node node) {
    if (node is! md.Element) return;
    if (node.tag == 'li') {
      final content = StringBuffer();
      bool? checked;
      void ownContent(md.Node child) {
        if (child is md.Text) {
          content.write(child.text);
          return;
        }
        if (child is! md.Element || {'ul', 'ol', 'li'}.contains(child.tag)) {
          return;
        }
        if (child.tag == 'input' && child.attributes['type'] == 'checkbox') {
          checked = child.attributes.containsKey('checked');
        }
        for (final descendant in child.children ?? <md.Node>[]) {
          ownContent(descendant);
        }
      }

      for (final child in node.children ?? <md.Node>[]) {
        ownContent(child);
      }
      final value = content.toString();
      final match = marker.firstMatch(value);
      if (checked != null && match != null) {
        final index = int.parse(match[1]!);
        final candidate = candidates[index];
        result.add(
          MarkdownTask(
            offset: candidate.start + candidate[1]!.length,
            checked: checked!,
            label: value.replaceFirst(marker, '').trim(),
          ),
        );
      }
    }
    for (final child in node.children ?? <md.Node>[]) {
      visit(child);
    }
  }

  for (final node in nodes) {
    visit(node);
  }
  return result;
}

String toggleMarkdownTask(String source, MarkdownTask task, bool checked) {
  if (task.offset < 0 ||
      task.offset >= source.length ||
      !{' ', 'x', 'X'}.contains(source[task.offset])) {
    throw const FormatException('invalid_task_position');
  }
  return source.replaceRange(task.offset, task.offset + 1, checked ? 'x' : ' ');
}

final _taskLine = RegExp(
  r'^[ \t]*(?:>[ \t]*)*(?:[-+*]|\d+[.)])[ \t]+\[[ xX]\]',
);
final _listMarker = RegExp(
  r'^[ \t]*(?:[-+*]|\d+[.)])[ \t]+(?:\[([ xX])\][ \t]+)?',
);

/// Appends one `- [ ] ` task per non-blank line of [input] to [source].
///
/// Existing bullet or checkbox prefixes in [input] are normalised; the
/// original text is never rewritten, only extended.
String appendMarkdownTasks(String source, String input) {
  final items = <String>[];
  for (final raw in const LineSplitter().convert(input)) {
    final marker = _listMarker.firstMatch(raw);
    final label = raw.substring(marker?.end ?? 0).trim();
    if (label.isEmpty) continue;
    final done = marker?[1]?.toLowerCase() == 'x';
    items.add('- [${done ? 'x' : ' '}] $label');
  }
  if (items.isEmpty) return source;
  final eol = source.contains('\r\n') ? '\r\n' : '\n';
  final body = items.join(eol);
  if (source.trim().isEmpty) return '$body$eol';
  final lines = const LineSplitter().convert(source.trimRight());
  final separator = source.endsWith('\n') ? '' : eol;
  final blank = _taskLine.hasMatch(lines.last) ? '' : eol;
  return '$source$separator$blank$body$eol';
}

/// Removes completed leaf tasks from [source] for display only.
///
/// Returns the reduced Markdown and the remaining tasks, which keep their
/// offsets in the original [source]. A completed task with indented lines
/// below it stays visible so unfinished sub-items are not hidden.
({String view, List<MarkdownTask> tasks}) hideCompletedTasks(String source) {
  final tasks = markdownTasks(source);
  final ranges = <(int, int)>[];
  final kept = <MarkdownTask>[];
  for (final task in tasks) {
    if (!task.checked) {
      kept.add(task);
      continue;
    }
    final start = source.lastIndexOf('\n', task.offset) + 1;
    var end = source.indexOf('\n', task.offset);
    end = end < 0 ? source.length : end + 1;
    if (_hasIndentedChild(source, start, end)) {
      kept.add(task);
    } else {
      ranges.add((start, end));
    }
  }
  final view = StringBuffer();
  var from = 0;
  for (final (start, end) in ranges) {
    view.write(source.substring(from, start));
    from = end;
  }
  view.write(source.substring(from));
  return (view: view.toString(), tasks: kept);
}

bool _hasIndentedChild(String source, int start, int end) {
  int indent(String line) => line.length - line.trimLeft().length;
  final own = indent(source.substring(start, end));
  for (var pos = end; pos < source.length;) {
    var next = source.indexOf('\n', pos);
    next = next < 0 ? source.length : next + 1;
    final line = source.substring(pos, next);
    if (line.trim().isNotEmpty) return indent(line) > own;
    pos = next;
  }
  return false;
}
