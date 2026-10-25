import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/markdown_tasks.dart';

void main() {
  test('tasks exclude fenced, indented, inline code and HTML blocks', () {
    const source = '''```markdown
- [ ] Fenced
```

    - [ ] Indented

Inline `- [ ] Code`

<div>
- [ ] HTML block
</div>

- [ ] Real **task**
''';
    final tasks = markdownTasks(source);
    expect(tasks.map((task) => task.label), ['Real task']);
    expect(
      toggleMarkdownTask(source, tasks.single, true),
      source.replaceFirst('- [ ] Real', '- [x] Real'),
    );
  });

  test(
    'nested ordered and quoted tasks retain their own labels and offsets',
    () {
      const source = '''- [ ] Parent
  - [x] Child

1. [ ] Ordered
2. [X] Uppercase

> - [ ] Quoted
''';
      final tasks = markdownTasks(source);
      expect(tasks.map((task) => task.label), [
        'Parent',
        'Child',
        'Ordered',
        'Uppercase',
        'Quoted',
      ]);
      expect(tasks.map((task) => task.checked), [
        false,
        true,
        false,
        true,
        false,
      ]);
      for (final task in tasks) {
        expect(
          source.substring(task.offset - 1, task.offset + 2),
          task.checked ? anyOf('[x]', '[X]') : '[ ]',
        );
      }
    },
  );

  test('Unicode, CRLF and duplicate labels survive a one-character edit', () {
    const source =
        '🧪 Příprava\r\n\r\n- [ ] Stejné\r\n- [X] Stejné\r\nKonec 🐈\r\n';
    final tasks = markdownTasks(source);
    expect(tasks, hasLength(2));
    final changed = toggleMarkdownTask(source, tasks.last, false);
    expect(changed, source.replaceFirst('[X]', '[ ]'));
    expect(changed.length, source.length);
    final differences = [
      for (var i = 0; i < source.length; i++)
        if (source[i] != changed[i]) i,
    ];
    expect(differences, [tasks.last.offset]);
    expect(markdownTasks(changed).map((task) => task.checked), [false, false]);
  });

  test('marker-like source text cannot impersonate a task', () {
    const source = '- [ ] Keep \u{f0000}OWNDECK_TASK_0\u{f0001}\n- [ ] Other';
    final tasks = markdownTasks(source);
    expect(tasks, hasLength(2));
    expect(tasks.first.label, 'Keep \u{f0000}OWNDECK_TASK_0\u{f0001}');
    expect(
      toggleMarkdownTask(source, tasks.last, true),
      source.replaceFirst('- [ ] Other', '- [x] Other'),
    );
  });

  test('raw HTML inputs are not Markdown tasks', () {
    const source =
        '<input type="checkbox" checked>\n\n'
        '- [ ] First\n- [x] Second\n';
    expect(markdownTasks(source).map((task) => task.label), [
      'First',
      'Second',
    ]);
    expect(
      markdownTasks('<ul><li><input type="checkbox">Fake</li></ul>'),
      isEmpty,
    );
  });

  test('invalid stored offsets are rejected without modifying the source', () {
    const source = '- [ ] Task';
    for (final offset in [-1, source.length, 0, 2]) {
      expect(
        () => toggleMarkdownTask(
          source,
          MarkdownTask(offset: offset, checked: false, label: 'Task'),
          true,
        ),
        throwsFormatException,
      );
    }
  });
}
