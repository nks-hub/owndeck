import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/card_link_inbox.dart';
import 'package:nextclouddeck/data/shared_text_inbox.dart';
import 'package:nextclouddeck/features/login.dart';
import 'package:nextclouddeck/platform/card_links.dart';
import 'package:nextclouddeck/platform/shared_text.dart';

import 'test_support.dart';

void main() {
  // The binding checks the override is unset before tearDown runs.
  Future<void> on(TargetPlatform platform, Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  for (final entry in {
    TargetPlatform.windows: false,
    TargetPlatform.macOS: false,
    TargetPlatform.linux: false,
    TargetPlatform.android: true,
    TargetPlatform.iOS: true,
  }.entries) {
    testWidgets(
      'QR scanner is ${entry.value ? '' : 'not '}offered on ${entry.key.name}',
      (tester) => on(entry.key, () async {
        await tester.pumpWidget(
          ProviderScope(child: localizedTestApp(home: const LoginScreen())),
        );
        await tester.pumpAndSettle();
        final scan = find.byKey(const Key('onboarding-scan-login-code'));
        expect(scan, entry.value ? findsOneWidget : findsNothing);
        expect(
          find.byIcon(Icons.qr_code_scanner_rounded),
          entry.value ? findsOneWidget : findsNothing,
        );
      }),
    );
  }

  testWidgets('desktop start survives links and share channels without a host', (
    tester,
  ) => on(TargetPlatform.windows, () async {
    // A channel nobody listens on answers with null, which the channel API
    // reports as MissingPluginException.
    for (final name in ['links', 'share']) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('com.nkshub.nextclouddeck/$name'),
        (_) async => throw MissingPluginException(),
      );
    }
    final links = NativeCardLinks(CardLinkInbox());
    final shares = NativeSharedText(SharedTextInbox());
    await links.start();
    await shares.start();
    links.close();
    shares.close();
  }));

  for (final entry in {
    TargetPlatform.windows: true,
    TargetPlatform.linux: true,
    TargetPlatform.macOS: true,
  }.entries) {
    testWidgets(
      'system browser login polls without waiting for a resume on ${entry.key.name}',
      (tester) => on(entry.key, () async {
        const browser = MethodChannel('plugins.flutter.io/url_launcher');
        final launched = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(browser, (
          call,
        ) async {
          if (call.method == 'launch') {
            launched.add((call.arguments as Map)['url'] as String);
          }
          return true;
        });
        addTearDown(
          () => tester.binding.defaultBinaryMessenger
              .setMockMethodCallHandler(browser, null),
        );
        var polls = 0;
        http.Response json(Object value) => http.Response(
          jsonEncode(value),
          200,
          headers: {'content-type': 'application/json'},
        );
        await tester.pumpWidget(
          ProviderScope(
            child: localizedTestApp(
              home: LoginScreen(
                transportFactory: (_, _) => MockClient((request) async {
                  if (request.url.path == '/status.php') {
                    return json({
                      'installed': true,
                      'maintenance': false,
                      'needsDbUpgrade': false,
                    });
                  }
                  if (request.url.path == '/index.php/login/v2') {
                    return json({
                      'login': 'https://cloud.example.com/login/flow',
                      'poll': {
                        'endpoint': 'https://cloud.example.com/login/poll',
                        'token': 'test-token',
                      },
                    });
                  }
                  polls++;
                  return http.Response('', 404);
                }),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'cloud.example.com');
        await tester.ensureVisible(find.text('Continue'));
        await tester.tap(find.text('Continue'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(launched, ['https://cloud.example.com/login/flow']);
        expect(polls, 1);
        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }),
    );
  }
}
