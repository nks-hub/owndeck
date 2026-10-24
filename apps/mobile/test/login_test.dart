import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/features/login.dart';

import 'test_support.dart';

http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  Future<void> mount(WidgetTester tester, LoginScreen screen) async {
    await tester.pumpWidget(
      ProviderScope(child: localizedTestApp(home: screen)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> connect(WidgetTester tester, String address) async {
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), address);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
  }

  testWidgets('suite login uses the shared labels and validates HTTP locally', (
    tester,
  ) async {
    var requests = 0;
    await mount(
      tester,
      LoginScreen(
        transportFactory: (_, _) => MockClient((_) async {
          requests++;
          return jsonResponse({});
        }),
        scan: (_) async => null,
      ),
    );
    expect(find.text('Your boards, one app'), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'https://',
    );
    await connect(tester, 'http://cloud.example.com');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid HTTPS Nextcloud address.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('maintenance stops before opening the browser', (tester) async {
    var opened = false;
    await mount(
      tester,
      LoginScreen(
        transportFactory: (_, _) => MockClient((request) async {
          expect(request.url.path, '/subdir/status.php');
          return jsonResponse({
            'installed': true,
            'maintenance': true,
            'needsDbUpgrade': false,
          });
        }),
        openBrowser: (_) async {
          opened = true;
          return true;
        },
      ),
    );
    await connect(tester, 'cloud.example.com/subdir/index.php/apps/deck/');
    await tester.pumpAndSettle();
    expect(
      find.text('This server is currently in maintenance mode.'),
      findsOneWidget,
    );
    expect(opened, isFalse);
  });

  testWidgets(
    'back cancels a pending readiness request without opening browser',
    (tester) async {
      final response = Completer<http.Response>();
      var opened = false;
      await mount(
        tester,
        LoginScreen(
          transportFactory: (_, _) => MockClient((_) => response.future),
          openBrowser: (_) async {
            opened = true;
            return true;
          },
        ),
      );
      await connect(tester, 'cloud.example.com');
      await tester.binding.handlePopRoute();
      response.complete(
        jsonResponse({
          'installed': true,
          'maintenance': false,
          'needsDbUpgrade': false,
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      expect(opened, isFalse);
    },
  );

  testWidgets('browser flow can be cancelled while a poll is in flight', (
    tester,
  ) async {
    final poll = Completer<http.Response>();
    var polls = 0;
    Uri? opened;
    await mount(
      tester,
      LoginScreen(
        transportFactory: (_, _) => MockClient((request) async {
          if (request.url.path == '/status.php') {
            return jsonResponse({
              'installed': true,
              'maintenance': false,
              'needsDbUpgrade': false,
            });
          }
          if (request.url.path == '/index.php/login/v2') {
            return jsonResponse({
              'login': 'https://cloud.example.com/login/flow',
              'poll': {
                'endpoint': 'https://cloud.example.com/login/poll',
                'token': 'test-token',
              },
            });
          }
          polls++;
          return poll.future;
        }),
        openBrowser: (uri) async {
          opened = uri;
          return true;
        },
      ),
    );
    await connect(tester, 'cloud.example.com');
    await tester.pump(const Duration(milliseconds: 300));
    expect(opened?.path, '/login/flow');
    expect(find.text('Finish signing in in your browser'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    poll.complete(
      jsonResponse({
        'server': 'https://cloud.example.com',
        'loginName': 'test-user',
        'appPassword': 'test-password',
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(polls, 1);
    expect(tester.takeException(), isNull);
  });
}
