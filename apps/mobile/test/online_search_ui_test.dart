import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/search.dart';

import 'test_support.dart';

class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

Map<String, Object?> entry(int id, String title, {bool assigned = false}) => {
  'id': id,
  'boardId': 1,
  'stackId': 2,
  'title': title,
  'description': '',
  'order': 0,
  'board': {'id': 1, 'title': 'Board'},
  'archived': false,
  'done': null,
  'assignedUsers': [
    if (assigned)
      {
        'type': 0,
        'participant': {'uid': 'canonical-user'},
      },
  ],
};
http.Response ocs(Object data) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': data,
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late DeckSession session;
  late Future<http.Response> Function(http.Request) respond;
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'alias',
        appPassword: 'test-password',
      ),
      userId: 'canonical-user',
    );
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'alias',
        appPassword: 'test-password',
        transport: MockClient((request) async {
          if (request.url.path.endsWith('/cloud/user')) {
            return ocs({'id': 'canonical-user'});
          }
          return respond(request);
        }),
      ),
    );
  });
  void testClean(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }

  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 100 && !ready(); i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready(), isTrue);
  }

  Future<void> serverSearch(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('search-filter-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Search on server'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
    await tester.pumpAndSettle();
  }

  testClean('late server results cannot replace a newer query', (tester) async {
    final first = Completer<http.Response>();
    var requested = '';
    respond = (request) async {
      requested = request.url.queryParameters['term']!;
      return requested == 'first'
          ? first.future
          : ocs([entry(2, 'Second remote')]);
    };
    await tester.pumpWidget(
      localizedTestApp(home: CardSearchScreen(session: session)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('card-search-query')), 'first');
    await tester.pump(const Duration(milliseconds: 250));
    await serverSearch(tester);
    await waitFor(tester, () => requested == 'first');
    await tester.enterText(
      find.byKey(const Key('card-search-query')),
      'second',
    );
    first.complete(ocs([entry(1, 'First remote')]));
    await tester.pump(const Duration(milliseconds: 250));
    await waitFor(
      tester,
      () => find.text('Second remote').evaluate().isNotEmpty,
    );
    expect(find.text('First remote'), findsNothing);
    expect(await database.boardView(session.account.id), isEmpty);
  });

  testClean('server my tasks filters unassigned cards by canonical UID', (
    tester,
  ) async {
    respond = (request) async {
      expect(request.url.path, endsWith('/overview/upcoming'));
      return ocs({
        'nodue': [entry(1, 'Unassigned'), entry(2, 'Assigned', assigned: true)],
      });
    };
    await tester.pumpWidget(
      localizedTestApp(
        home: CardSearchScreen(session: session, mineOnly: true),
      ),
    );
    await tester.pumpAndSettle();
    await serverSearch(tester);
    await waitFor(tester, () => find.text('Assigned').evaluate().isNotEmpty);
    expect(find.text('Unassigned'), findsNothing);
    expect(
      find.text(
        'The server overview includes active, unfinished cards assigned to you.',
      ),
      findsOneWidget,
    );
  });
  testClean(
    'inactive task tab preserves filters without background server reads',
    (tester) async {
      var calls = 0;
      respond = (request) async {
        if (!request.url.path.endsWith('/search')) return ocs([]);
        calls++;
        return ocs([entry(3, 'Remote result')]);
      };
      Widget view(bool active) => localizedTestApp(
        home: Scaffold(
          body: CardSearchView(session: session, active: active),
        ),
      );
      await tester.pumpWidget(view(true));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('card-search-query')),
        'kept',
      );
      await tester.pump(const Duration(milliseconds: 250));
      await serverSearch(tester);
      await waitFor(tester, () => calls == 1);
      await tester.pumpWidget(view(false));
      await tester.pump(const Duration(minutes: 2));
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('card-search-query')))
            .controller!
            .text,
        'kept',
      );
      await tester.pumpWidget(view(true));
      await waitFor(tester, () => calls == 2);
    },
  );
}
