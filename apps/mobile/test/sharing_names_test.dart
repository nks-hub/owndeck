import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/sharing.dart';

import 'board_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'sharing shows text names without exposing malformed data or IDs',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(
              'dev.fluttercommunity.plus/connectivity_status',
            ),
            (_) async => null,
          );
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await boardModel(
          tester,
          fixture.db.saveBoards(
            fixture.account.id,
            fixture.account.generation,
            [
              DeckBoard.fromJson({
                ...fixture.board.raw,
                'acl': [
                  {
                    'id': 2,
                    'type': 1,
                    'participant': {
                      'uid': 'opaque-participant-id',
                      'displayname': {'internal': 'server-value'},
                      'displayName': 'Design team',
                    },
                  },
                  {
                    'id': 3,
                    'type': 0,
                    'participant': {'uid': 'another-opaque-id'},
                  },
                ],
              }),
            ],
            null,
          ),
        );
        await tester.pumpWidget(
          boardTestApp(SharingScreen(session: fixture.session, boardId: 1)),
        );
        await settleBoard(tester);
        expect(find.text('Design team'), findsOneWidget);
        expect(find.textContaining('opaque'), findsNothing);
        expect(find.textContaining('server-value'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );
}
