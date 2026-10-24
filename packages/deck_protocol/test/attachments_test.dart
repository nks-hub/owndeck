import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

DeckClient client(http.Client transport) => DeckClient(
  base: ServerBase.parse('https://cloud.example.com/nextcloud'),
  loginName: 'user',
  appPassword: 'test-password',
  transport: transport,
);

Map<String, Object?> attachment(
  String type, {
  int cardId = 3,
  int deletedAt = 0,
}) => {
  'id': 7,
  'cardId': cardId,
  'type': type,
  'data': 'report.txt',
  'deletedAt': deletedAt,
  'extendedData': <String, Object?>{},
};
http.Response json(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'a local read failure during upload is retained as an uncertain write',
    () async {
      final api = client(
        MockClient.streaming((request, body) async {
          await body.drain<void>();
          return http.StreamedResponse(const Stream.empty(), 200);
        }),
      );
      await expectLater(
        api.uploadAttachment(
          1,
          2,
          3,
          filename: 'file.txt',
          mime: 'text/plain',
          length: 3,
          bytes: Stream.error(const FileSystemException('source_unavailable')),
        ),
        throwsA(
          isA<DeckException>().having(
            (error) => error.uncertain,
            'uncertain',
            isTrue,
          ),
        ),
      );
    },
  );
  test(
    'both attachment kinds can have the same id and omit private file metadata',
    () async {
      final api = client(
        MockClient(
          (_) async =>
              json([attachment('file'), attachment('deck_file', deletedAt: 8)]),
        ),
      );
      final result = await api.attachments(1, 2, 3);
      expect(result.map((item) => item.type), ['file', 'deck_file']);
      expect(result.first.path, isNull);
      expect(result.last.canRestore, isTrue);
    },
  );

  test('an attachment response from another card is rejected', () async {
    final api = client(
      MockClient((_) async => json([attachment('file', cardId: 4)])),
    );
    await expectLater(api.attachments(1, 2, 3), throwsA(isA<DeckException>()));
  });

  test(
    'uploads multipart bytes and filename through the typed v1.1 route',
    () async {
      final api = client(
        MockClient((request) async {
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/deck/api/v1.1/boards/1/stacks/2/cards/3/attachments',
          );
          expect(request.method, 'POST');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data; boundary='),
          );
          expect(request.body, contains('name="type"\r\n\r\nfile'));
        expect(request.body, contains('name="data"\r\n\r\n\r\n'));
          expect(request.body, contains('name="file"; filename="report.txt"'));
          expect(request.body, contains('hello'));
          expect(request.followRedirects, isFalse);
          return json(attachment('file'));
        }),
      );
      final result = await api.uploadAttachment(
        1,
        2,
        3,
        filename: 'report.txt',
        mime: 'text/plain',
        length: 5,
        bytes: Stream.value(utf8.encode('hello')),
      );
      expect(result.id, 7);
      expect(result.cardId, 3);
    },
  );

  test(
    'an upload accepted before a lost response stays uncertain and is not retried',
    () async {
      var requests = 0;
      final api = client(
        MockClient((_) async {
          requests++;
          throw http.ClientException('connection_lost');
        }),
      );
      await expectLater(
        api.uploadAttachment(
          1,
          2,
          3,
          filename: 'report.txt',
          mime: 'text/plain',
          length: 0,
          bytes: const Stream.empty(),
        ),
        throwsA(
          isA<DeckException>().having(
            (error) => error.uncertain,
            'uncertain',
            isTrue,
          ),
        ),
      );
      expect(requests, 1);
    },
  );

  test('cancelling an active upload reports an uncertain write', () async {
    final cancelled = Completer<void>();
    final api = client(
      MockClient.streaming((request, body) async {
        await body.drain<void>();
        cancelled.complete();
        await (request as http.Abortable).abortTrigger;
        throw http.RequestAbortedException();
      }),
    );
    await expectLater(
      api.uploadAttachment(
        1,
        2,
        3,
        filename: 'report.txt',
        mime: 'text/plain',
        length: 0,
        bytes: const Stream.empty(),
        cancelled: cancelled.future,
      ),
      throwsA(
        isA<DeckException>()
            .having((error) => error.code, 'code', 'cancelled')
            .having((error) => error.uncertain, 'uncertain', isTrue),
      ),
    );
  });

  test(
    'downloads include attachment type and never follow redirects with credentials',
    () async {
      final paths = <String>[];
      final api = client(
        MockClient((request) async {
          paths.add(request.url.path);
          expect(request.followRedirects, isFalse);
          return paths.length == 1
              ? http.Response.bytes([1, 2, 3], 200)
              : http.Response(
                  '',
                  302,
                  headers: {'location': 'https://other.example.com/file'},
                );
        }),
      );
      expect(
        await api.downloadAttachment(
          1,
          2,
          DeckAttachment.fromJson(attachment('file')),
        ),
        [1, 2, 3],
      );
      await expectLater(
        api.downloadAttachment(
          1,
          2,
          DeckAttachment.fromJson(attachment('deck_file')),
        ),
        throwsA(isA<DeckException>()),
      );
      expect(paths, [
        endsWith('/attachments/file/7'),
        endsWith('/attachments/deck_file/7'),
      ]);
    },
  );

  test(
    'linking an existing cloud file creates a Deck share without uploading it',
    () async {
      final api = client(
        MockClient((request) async {
          expect(
            request.url.path,
            '/nextcloud/ocs/v2.php/apps/files_sharing/api/v1/shares',
          );
          expect(jsonDecode(request.body), {
            'path': '/Reports/A B.txt',
            'shareType': 12,
            'shareWith': '3',
          });
          return json({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': {'id': '45'},
            },
          });
        }),
      );
      expect(await api.attachCloudFile(3, ['Reports', 'A B.txt']), 45);
    },
  );

  test('only deleted legacy files can be restored', () async {
    var requests = 0;
    final api = client(
      MockClient((request) async {
        requests++;
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/attachments/deck_file/7/restore'));
        return json(attachment('deck_file'));
      }),
    );
    await expectLater(
      api.restoreAttachment(
        1,
        2,
        DeckAttachment.fromJson(attachment('file', deletedAt: 8)),
      ),
      throwsArgumentError,
    );
    await api.restoreAttachment(
      1,
      2,
      DeckAttachment.fromJson(attachment('deck_file', deletedAt: 8)),
    );
    expect(requests, 1);
  });
}
