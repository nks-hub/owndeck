import 'package:flutter/widgets.dart' show Characters;
import 'package:markdown/markdown.dart' as md;

const markdownPreviewSourceLimit = 1200;
const markdownPreviewLength = 160;
final _markdownSyntax = RegExp(r'[`*_~\[\]<>\\&|#=+\-\r\n]');
final _orderedList = RegExp(r'^ {0,3}[0-9]{1,9}[.)](?:[ \t]|$)');

// One extra code point records truncation without scanning the remaining text.
String markdownPreviewInput(String source) {
  final points = <int>[];
  final iterator = source.runes.iterator;
  while (points.length <= markdownPreviewSourceLimit && iterator.moveNext()) {
    points.add(iterator.current);
  }
  return String.fromCharCodes(points);
}

String markdownPreview(String source) {
  final input = markdownPreviewInput(source);
  final truncated = input.runes.length > markdownPreviewSourceLimit;
  var bounded = String.fromCharCodes(
    input.runes.take(markdownPreviewSourceLimit),
  );
  if (truncated) {
    // The final cluster may have been cut between a base and its modifiers.
    final clusters = Characters(bounded).toList(growable: false);
    bounded = clusters.take(clusters.length - 1).join();
  }
  final plain =
      !_markdownSyntax.hasMatch(bounded) && !_orderedList.hasMatch(bounded);
  final nodes = plain
      ? <md.Node>[md.Text(bounded)]
      : md.Document(
          extensionSet: md.ExtensionSet.gitHubFlavored,
          encodeHtml: false,
        ).parse(bounded);
  const blocks = {
    'p',
    'blockquote',
    'ul',
    'ol',
    'li',
    'pre',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'table',
    'thead',
    'tbody',
    'tr',
    'th',
    'td',
    'br',
    'hr',
  };
  final content = StringBuffer();
  void visit(md.Node node) {
    if (node is md.Text) {
      content.write(node.text);
      return;
    }
    if (node is! md.Element || node.tag == 'input') return;
    if (blocks.contains(node.tag)) content.write(' ');
    if (node.tag == 'img') {
      content.write(node.attributes['alt'] ?? '');
    } else {
      for (final child in node.children ?? <md.Node>[]) {
        visit(child);
      }
    }
    if (blocks.contains(node.tag)) content.write(' ');
  }

  for (final node in nodes) {
    visit(node);
  }
  final text = content.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return '';
  final characters = Characters(text);
  if (truncated || characters.length > markdownPreviewLength) {
    return '${characters.take(markdownPreviewLength - 1).toString().trimRight()}…';
  }
  return text;
}
