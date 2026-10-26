import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/errors.dart';
import 'package:nextclouddeck/features/state_message.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

void main() {
  Widget app(Widget child, {ThemeData? theme, double scale = 1}) =>
      MaterialApp(
        theme: theme,
        locale: const Locale('cs'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  for (final dark in [false, true]) {
    testWidgets('state message and notice fit 200% text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retried = 0;
      await tester.pumpWidget(
        app(
          Column(
            children: [
              StateMessage(
                message:
                    'Uložená data nelze v tomto zařízení načíst. Zkuste obrazovku otevřít znovu.',
                actionLabel: 'Zkusit znovu',
                onAction: () => retried++,
              ),
              IncompleteDataNotice(
                message:
                    'Karty 2 nástěnek zatím nejsou uložené v zařízení, seznam proto může být neúplný.',
                actionLabel: 'Načíst karty',
                onAction: () => retried++,
              ),
            ],
          ),
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      for (final label in ['Zkusit znovu', 'Načíst karty']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        await tester.ensureVisible(button);
        await tester.tap(button);
      }
      expect(retried, 2);
    });
  }

  testWidgets('local write failures never read as load or server errors', (
    tester,
  ) async {
    late AppLocalizations text;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            text = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      localWriteErrorMessage(const FormatException('task'), text),
      text.localSaveError,
    );
    expect(localWriteErrorMessage(Exception('x'), text), text.localSaveError);
    expect(
      localWriteErrorMessage(StateError('permission_denied'), text),
      text.writePermissionError,
    );
    expect(errorMessage(Exception('x'), text), text.loadError);
  });
}
