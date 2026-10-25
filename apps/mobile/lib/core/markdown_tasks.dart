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
