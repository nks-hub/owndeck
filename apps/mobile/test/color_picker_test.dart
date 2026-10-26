import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/color_choices.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

void main() {
  String? picked = 'unset';

  Future<void> open(
    WidgetTester tester, {
    String? value,
    bool allowNone = true,
    String locale = 'en',
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    picked = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        theme: ThemeData(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ColorChoices(
              value: value,
              allowNone: allowNone,
              onChanged: (v) => picked = v,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.textContaining('Custom color').first);
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Use this color'));
    await tester.tap(find.text('Use this color'));
    await tester.pumpAndSettle();
  }

  Finder hexField() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  testWidgets('preset swatch is a quick pick and keeps its name', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Blue'));
    expect(picked, '2563eb');
  });

  testWidgets('no color is offered only when allowed', (tester) async {
    await open(tester, value: '2563eb');
    await tester.tap(find.text('No custom color'));
    expect(picked, isNull);
    await open(tester, allowNone: false);
    expect(find.text('No custom color'), findsNothing);
  });

  testWidgets('hue slider works with the keyboard and exposes a value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    await openPicker(tester);
    final hue = find.byType(Slider).first;
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^Hue')));
    expect(node.getSemanticsData().value, contains('°'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    final before = tester.widget<Slider>(hue).value;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.widget<Slider>(hue).value, greaterThan(before));
    await apply(tester);
    expect(picked, isNot('2563eb'));
    expect(colorFromHex(picked!), isNotNull);
    semantics.dispose();
  });

  testWidgets('plus and minus buttons step lightness without dragging', (
    tester,
  ) async {
    await open(tester);
    await openPicker(tester);
    final light = find.byType(Slider).last;
    final before = tester.widget<Slider>(light).value;
    await tester.tap(find.byTooltip('Increase Lightness'));
    await tester.pump();
    expect(tester.widget<Slider>(light).value, before + 5);
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease Lightness'));
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease Lightness'));
    await tester.pump();
    expect(tester.widget<Slider>(light).value, before - 5);
  });

  testWidgets('shows text contrast on the chosen color', (tester) async {
    await open(tester);
    await openPicker(tester);
    expect(find.textContaining('Text contrast'), findsOneWidget);
    expect(find.text('Sample text'), findsOneWidget);
  });

  testWidgets('hex entry validates six digits and stays optional', (
    tester,
  ) async {
    await open(tester);
    await openPicker(tester);
    await tester.ensureVisible(find.text('Enter exact code'));
    await tester.tap(find.text('Enter exact code'));
    await tester.pumpAndSettle();
    await tester.enterText(hexField(), 'zz12');
    await tester.pump();
    expect(find.text('Enter exactly 6 characters 0-9 or A-F.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Use this color'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(hexField(), '12345');
    await tester.pump();
    expect(find.text('Enter exactly 6 characters 0-9 or A-F.'), findsOneWidget);
    await tester.enterText(hexField(), 'A1b2C3');
    await tester.pump();
    expect(find.text('Enter exactly 6 characters 0-9 or A-F.'), findsNothing);
    await apply(tester);
    expect(picked, 'a1b2c3');
  });

  testWidgets('an existing custom color round-trips exactly', (tester) async {
    for (final stored in ['123abc', '#ABCDEF', '010101', 'fefefe']) {
      await open(tester, value: stored);
      expect(find.textContaining('Custom color:'), findsOneWidget);
      await openPicker(tester);
      await apply(tester);
      expect(picked, stored.replaceFirst('#', '').toLowerCase());
    }
  });

  testWidgets('cancel leaves the value untouched', (tester) async {
    await open(tester, value: '123abc');
    await openPicker(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(picked, 'unset');
  });

  testWidgets('describes colors in words, never hex', (tester) async {
    await open(tester, locale: 'cs');
    final text = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(describeColor(const Color(0xff1e3a8a), text), 'tmavě modrá');
    expect(describeColor(const Color(0xffbfdbfe), text), 'světle modrá');
    expect(describeColor(const Color(0xff2563eb), text), 'modrá');
    expect(describeColor(const Color(0xff000000), text), 'černá');
    expect(colorName('1e3a8a', text), 'Vlastní barva: tmavě modrá');
  });

  testWidgets('readable foreground follows the background', (tester) async {
    expect(readableForeground(const Color(0xff000000)), Colors.white);
    expect(readableForeground(const Color(0xffffff00)), Colors.black);
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'picker fits landscape at 200% text in $brightness with actions reachable',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(846, 412);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await open(tester, locale: 'cs', scale: 2, brightness: brightness);
        await tester.ensureVisible(find.textContaining('Vlastní barva').first);
        await tester.tap(find.textContaining('Vlastní barva').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Zrušit').hitTestable(), findsOneWidget);
        expect(find.text('Použít tuto barvu').hitTestable(), findsOneWidget);
        for (final button in find.byType(IconButton).evaluate()) {
          final size = tester.getSize(find.byWidget(button.widget));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        await tester.scrollUntilVisible(
          find.text('Zadat přesný kód'),
          100,
          scrollable: find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
