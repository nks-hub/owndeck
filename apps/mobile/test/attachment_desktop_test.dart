import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/attachment_files.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/attachments.dart';

import 'board_test_support.dart' show boardTestApp;

class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String reference) async => values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      values[reference] = password;
  @override
  Future<void> delete(String reference) async => values.remove(reference);
  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

/// Writes the bytes to a temp file the way the desktop file_picker backends do.
class _FakePicker extends FilePickerPlatform {
  _FakePicker(this.directory);
  final Directory directory;
  Uri? saved;
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return saved = file.uri;
  }
}

final _payload = Uint8List.fromList(List.generate(4096, (i) => (i * 31) % 256));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  const browser = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late DeckDatabase database;
  late DeckSession session;
  late FilePickerPlatform originalPicker;

  http.Response reply(Object value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );
  http.Response ocs(Object value) => reply({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': value,
    },
  });

  Future<void> init() async {
    messenger.setMockMethodCallHandler(connectivity, (_) async => null);
    originalPicker = FilePickerPlatform.instance;
    directory = await Directory.systemTemp.createTemp('owndeck-attach-');
    database = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'demo',
        appPassword: 'test-password',
      ),
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        'id': 1,
        'title': 'Board',
        'color': '008080',
        'archived': false,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
      }),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [
          {
            'id': 8,
            'stackId': 2,
            'title': 'Card',
            'description': '',
            'type': 'plain',
            'owner': 'demo',
            'order': 0,
            'archived': false,
            'deletedAt': 0,
          },
        ],
      }),
    ], null);
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'demo',
        appPassword: 'test-password',
        transport: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/cloud/user')) return ocs({'id': 'demo'});
          if (path.endsWith('/capabilities')) {
            return ocs({
              'capabilities': {
                'deck': {
                  'version': '1.19.1',
                  'apiVersions': ['1.1'],
                  'canCreateBoards': true,
                },
              },
            });
          }
          if (path.endsWith('/attachments/file/7')) {
            return http.Response.bytes(_payload, 200);
          }
          if (path.endsWith('/attachments')) {
            return reply([
              {
                'id': 7,
                'cardId': 8,
                'type': 'file',
                'data': 'report.pdf',
                'lastModified': 10,
                'deletedAt': 0,
              },
            ]);
          }
          if (path.endsWith('/boards/1')) {
            return reply({
              'id': 1,
              'title': 'Board',
              'color': '008080',
              'archived': false,
              'deletedAt': 0,
              'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
            });
          }
          throw StateError('unexpected_request ${request.url}');
        }),
      ),
      pollInterval: const Duration(hours: 1),
      files: () async => AttachmentFiles(directory),
    );
  }

  Future<void> dispose() async {
    debugDefaultTargetPlatformOverride = null;
    FilePickerPlatform.instance = originalPicker;
    messenger.setMockMethodCallHandler(connectivity, null);
    messenger.setMockMethodCallHandler(browser, null);
    await database.close();
    await directory.delete(recursive: true);
  }

  void fixtureTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await tester.runAsync(init);
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          session.dispose();
          await tester.pumpAndSettle();
          await tester.runAsync(dispose);
        }
      });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      boardTestApp(AttachmentsScreen(session: session, boardId: 1, cardId: 8)),
    );
    for (
      var i = 0;
      i < 100 && find.text('report.pdf').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(find.text('report.pdf'), findsOneWidget);
  }

  Future<void> settle(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
  }

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    fixtureTest('open on $platform hands the cached file to the system', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final launches = <MethodCall>[];
      messenger.setMockMethodCallHandler(browser, (call) async {
        launches.add(call);
        return true;
      });
      await mount(tester);
      await tester.tap(find.text('report.pdf'));
      await settle(tester, () => launches.isNotEmpty);
      final url = Uri.parse(
        (launches.single.arguments as Map)['url'] as String,
      );
      expect(url.scheme, 'file');
      expect(File.fromUri(url).readAsBytesSync(), _payload);
      expect(find.textContaining('could not be opened'), findsNothing);
    });

    fixtureTest('save on $platform writes bytes with an identical SHA-256', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final picker = _FakePicker(directory);
      FilePickerPlatform.instance = picker;
      await mount(tester);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Save file'));
      await settle(tester, () => picker.saved != null);
      expect(
        sha256.convert(File.fromUri(picker.saved!).readAsBytesSync()),
        sha256.convert(_payload),
      );
    });
  }

  fixtureTest('a failed desktop launch reports that the file did not open', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    messenger.setMockMethodCallHandler(browser, (_) async => false);
    await mount(tester);
    await tester.tap(find.text('report.pdf'));
    await settle(
      tester,
      () => find.textContaining('could not be opened').evaluate().isNotEmpty,
    );
  });
}
