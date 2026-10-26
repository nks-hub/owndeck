import 'dart:async';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/technical_details.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/sync_notice.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

final class _Vault implements CredentialVault {
  final _values = <String, String>{};
  @override
  Future<String?> read(String reference) async => _values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      _values[reference] = password;
  @override
  Future<void> delete(String reference) async => _values.remove(reference);
  @override
  Future<Set<String>> references() async => _values.keys.toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase db;
  late StoredAccount account;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    PackageInfo.setMockInitialValues(
      appName: 'OwnDeck',
      packageName: 'example.app',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(db, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'login-alias',
        appPassword: 'secret-app-password',
      ),
    );
  });
  tearDown(() async {
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  DeckSession sessionFor(Future<http.Response> Function() answer) =>
      DeckSession(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'secret-app-password',
          transport: MockClient((_) => answer()),
        ),
        pollInterval: const Duration(hours: 1),
      );

  final cases = <String, ({Future<http.Response> Function() answer, String advice})>{
    'maintenance': (
      answer: () async => http.Response('', 503),
      advice: 'The server is in maintenance mode.',
    ),
    'certificate': (
      answer: () async => throw const TlsException('bad certificate'),
      advice: 'The server certificate is not trusted.',
    ),
    'timeout': (
      answer: () async => throw TimeoutException('slow'),
      advice: 'The server did not answer in time.',
    ),
    'deckMissing': (
      answer: () async => http.Response(
        'Not found',
        404,
        headers: {'content-type': 'text/html'},
      ),
      advice: 'The Deck app is not available on this server.',
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} error shows advice and copies safe details', (
      tester,
    ) async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final session = sessionFor(entry.value.answer)
        ..capabilities = const DeckCapabilities(
          version: '1.14.0',
          apiVersion: '1.1',
          canCreateBoards: true,
          serverVersion: '31.0.2',
        );
      addTearDown(session.dispose);
      await tester.runAsync(session.refreshBoards);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SyncNotice(
              session: session,
              scope: 'boards',
              retry: () {},
              hasData: false,
            ),
          ),
        ),
      );
      expect(find.textContaining(entry.value.advice), findsOneWidget);

      await tester.tap(find.text('Copy technical details'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('Technical details copied.'), findsOneWidget);
      final details = copied!;
      expect(details, contains('OwnDeck: 1.2.3 (45)'));
      expect(details, contains('Nextcloud: 31.0.2'));
      expect(details, contains('Deck: 1.14.0'));
      expect(details, contains('Category: ${entry.key}'));
      for (final secret in [
        'secret-app-password',
        'cloud.example.com',
        'login-alias',
        'https://',
      ]) {
        expect(details, isNot(contains(secret)));
      }
    });
  }

  test('unclassified errors have no advice but still describe the category', () {
    expect(errorCategory(const DeckException('request_rejected', status: 500)),
        ErrorCategory.other);
    expect(errorCategory(const LoginException('server_maintenance')),
        ErrorCategory.maintenance);
    expect(errorCategory(const DeckException('transport_failed')),
        ErrorCategory.network);
  });
}
