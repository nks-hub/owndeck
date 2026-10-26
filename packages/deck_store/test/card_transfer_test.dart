import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'card_transfer_support.dart';

void main() {
  late TransferFixture f;
  var fixtureClosed = false;
  setUp(() async {
    fixtureClosed = false;
    f = TransferFixture();
    await f.initialize();
  });
  tearDown(() async {
    if (!fixtureClosed) await f.close();
  });

  for (final manage in [false, true]) {
    test(
      'transfer preserves identity/content and migrates labels with manage=$manage',
      () async {
        f.server.targetManage = manage;
        final before = {...f.server.cards[8]!};
        await f.database.saveAttachments(f.account, 1, 8, [
          DeckAttachment.fromJson({
            'id': 7,
            'cardId': 8,
            'type': 'file',
            'data': 'report.txt',
            'deletedAt': 0,
            'lastModified': 10,
          }),
        ], 0);
        await f.queue();
        expect(
          (await f.database.stackView(f.account.id, 1)).single.cards,
          isEmpty,
        );
        expect(
          (await f.database.stackView(
            f.account.id,
            3,
          )).singleWhere((s) => s.id == 4).cards.map((c) => c.id),
          [9, 8, 10],
        );
        f.server.cards[8]!['description'] = 'Fresh server text';
        await f.sync.run();
        expect(f.server.transfers, 1);
        expect(f.server.positions, 1);
        expect(f.server.crossBoardReorders, 0);
        expect(f.server.ordered(4).map((c) => c['id']), [9, 8, 10]);
        expect(f.server.cards.length, 3);
        final moved = f.server.cards[8]!;
        expect(moved['description'], 'Fresh server text');
        for (final key in [
          'owner',
          'type',
          'duedate',
          'startdate',
          'color',
          'assignedUsers',
          'commentsCount',
          'attachmentCount',
          'dependentCards',
        ]) {
          expect(moved[key], before[key], reason: key);
        }
        expect(
          (moved['labels'] as List).map((l) => l['title']),
          manage ? ['Common', 'Source only'] : ['Common'],
        );
        expect(await f.database.writesFor(f.account.id), isEmpty);
        expect(
          (await f.database.select(f.database.storedAttachments).get())
              .single
              .boardId,
          3,
        );
        expect(
          (await f.database.stackView(
            f.account.id,
            3,
          )).singleWhere((s) => s.id == 4).cards.map((c) => c.id),
          [9, 8, 10],
        );
      },
    );
  }

  for (final mode in ['enter', 'leave', 'keep']) {
    test(
      'done-column transition $mode uses fresh source and destination state',
      () async {
        f.server.sourceDone = mode == 'leave';
        f.server.targetDone = mode == 'enter';
        f.server.cards[8]!['done'] = '2030-01-01T00:00:00Z';
        await f.queue();
        await f.sync.run();
        final value = f.server.cards[8]!['done'];
        if (mode == 'leave') {
          expect(value, isNull);
        } else if (mode == 'keep') {
          expect(value, '2030-01-01T00:00:00Z');
        } else {
          expect(DateTime.tryParse(value! as String), isNotNull);
        }
        expect(await f.database.writesFor(f.account.id), isEmpty);
      },
    );
  }

  test(
    'accepted transfer waits only for read-back before positioning',
    () async {
      await f.queue();
      f.server.failTransferRead = true;
      await f.sync.run();
      await f.sync.run();
      final pending = (await f.database.writesFor(f.account.id)).single;
      expect(pending.state, 'applied');
      expect(jsonDecode(pending.remote!)['phase'], 'transfer');
      expect(f.server.transfers, 1);
      expect(f.server.positions, 0);
      f.server.failTransferRead = false;
      await f.sync.run();
      expect(f.server.transfers, 1);
      expect(f.server.positions, 1);
      expect(await f.database.writesFor(f.account.id), isEmpty);
    },
  );

  test(
    'accepted positioning waits only for GET and never repeats either mutation',
    () async {
      await f.queue();
      f.server.failPositionRead = true;
      await f.sync.run();
      await f.sync.run();
      final pending = (await f.database.writesFor(f.account.id)).single;
      expect(pending.state, 'applied');
      expect(jsonDecode(pending.proposal)['phase'], 'position');
      expect(jsonDecode(pending.proposal)['transferReceipt']['cardId'], 8);
      expect(f.server.transfers, 1);
      expect(f.server.positions, 1);
      f.server.failPositionRead = false;
      await f.sync.run();
      expect(f.server.transfers, 1);
      expect(f.server.positions, 1);
      expect(await f.database.writesFor(f.account.id), isEmpty);
    },
  );

  for (final phase in ['transfer', 'position']) {
    test(
      'lost $phase acknowledgement stays uncertain without automatic replay',
      () async {
        await f.queue();
        f.server.loseTransferResponse = phase == 'transfer';
        f.server.losePositionResponse = phase == 'position';
        await f.sync.run();
        await f.sync.run();
        final pending = (await f.database.writesFor(f.account.id)).single;
        expect(pending.state, 'uncertain');
        expect(f.server.transfers, 1);
        expect(f.server.positions, phase == 'position' ? 1 : 0);
        if (phase == 'position') {
          expect(
            jsonDecode(
              pending.proposal,
            )['transferReceipt']['acceptedCard']['id'],
            8,
          );
          f.server.losePositionResponse = false;
          await f.database.decideWrite(
            f.account.id,
            pending.id,
            discard: false,
          );
          await f.sync.run();
          expect(f.server.transfers, 1);
          expect(f.server.positions, 1);
          expect(await f.database.writesFor(f.account.id), isEmpty);
        }
      },
    );
  }

  test(
    'retrying a transfer the server already applied only positions the card (B62)',
    () async {
      await f.queue();
      f.server.loseTransferResponse = true;
      await f.sync.run();
      final pending = (await f.database.writesFor(f.account.id)).single;
      expect(pending.state, 'uncertain');
      f.server.loseTransferResponse = false;
      await f.database.decideWrite(f.account.id, pending.id, discard: false);
      await f.sync.run();
      expect(f.server.transfers, 1);
      expect(f.server.positions, 1);
      expect(await f.database.writesFor(f.account.id), isEmpty);
      expect(f.server.cards[8]!['stackId'], 4);
    },
  );

  test(
    'permission loss after transfer preserves the accepted step for a later retry',
    () async {
      await f.queue();
      f.server.afterTransfer = () async {
        f.server.targetRead = false;
      };
      await f.sync.run();
      var pending = (await f.database.writesFor(f.account.id)).single;
      expect(pending.state, 'blocked');
      expect(jsonDecode(pending.proposal)['phase'], 'position');
      expect(jsonDecode(pending.proposal)['transferReceipt']['cardId'], 8);
      expect(f.server.transfers, 1);
      expect(f.server.positions, 0);
      f.server.targetRead = true;
      f.server.afterTransfer = null;
      await f.database.decideWrite(f.account.id, pending.id, discard: false);
      await f.sync.run();
      expect(f.server.transfers, 1);
      expect(f.server.positions, 1);
      expect(await f.database.writesFor(f.account.id), isEmpty);
    },
  );

  for (final denial in [
    'source-edit',
    'target-edit',
    'source-external',
    'target-external',
    'wrong-stack',
  ]) {
    test('fresh $denial blocks before transfer', () async {
      await f.queue();
      if (denial == 'source-edit') f.server.sourceEdit = false;
      if (denial == 'target-edit') f.server.targetEdit = false;
      if (denial == 'source-external') f.server.sourceExternal = true;
      if (denial == 'target-external') f.server.targetExternal = true;
      if (denial == 'wrong-stack') f.server.malformedTarget = true;
      await f.sync.run();
      expect(f.server.transfers, 0);
      expect(f.server.positions, 0);
      expect(
        (await f.database.writesFor(f.account.id)).single.state,
        'blocked',
      );
      expect(f.server.cards[8]!['stackId'], 2);
    });
  }

  test(
    'a later comment and move follow the owned transfer without a foreign-move conflict',
    () async {
      await f.queue();
      final projected = (await f.database.stackView(
        f.account.id,
        3,
      )).singleWhere((s) => s.id == 4).cards.singleWhere((c) => c.id == 8);
      await f.database.queueCardAction(f.account, 3, projected, 'moveCard', {
        'stackId': 6,
        'order': 0,
      });
      await f.database.queueComment(f.account, 1, 2, 8, 'createComment', {
        'message': 'Keep my later text',
      });
      await f.database.saveEditorDraft(f.account, 'later-draft', 1, 2, {
        'description': 'Own draft',
      }, DeckCard.fromJson(f.server.cards[8]!));
      f.server.afterTransfer = () async {
        final epoch = (await f.database.account(f.account.id))!.contentEpoch;
        await f.database.saveStacks(
          f.account.id,
          f.account.generation,
          1,
          [
            DeckStack.fromJson({...f.server.stackData(2), 'cards': []}),
          ],
          null,
          contentEpoch: epoch,
        );
      };
      await f.sync.run();
      expect(f.server.cards[8]!['stackId'], 6);
      expect(f.server.comments, 1);
      expect(f.server.lastComment!['message'], 'Keep my later text');
      expect(await f.database.writesFor(f.account.id), isEmpty);
      final draft = (await f.database.editorDraft(
        f.account.id,
        'later-draft',
      ))!;
      expect(draft.boardId, 3);
      expect(draft.stackId, 6);
      expect(jsonDecode(draft.payload)['description'], 'Own draft');
    },
  );

  test('stale source actions are rejected after optimistic transfer', () async {
    final original = DeckCard.fromJson(f.server.cards[8]!);
    await f.queue();
    await expectLater(
      f.database.queueCardAction(f.account, 1, original, 'archiveCard', {}),
      throwsStateError,
    );
    expect((await f.database.writesFor(f.account.id)).length, 1);
  });

  test(
    'local card creation resolves to the same server identity before transfer',
    () async {
      await f.database.saveCardDraft(f.account, 1, 2, {
        'title': 'Local card',
        'description': 'Own text',
      });
      final local = (await f.database.stackView(
        f.account.id,
        1,
      )).single.cards.singleWhere((c) => c.id < 0);
      await f.database.queueCardTransfer(
        f.account,
        1,
        local,
        destinationBoardId: 3,
        destinationStackId: 4,
        anchorCardId: 9,
        before: true,
      );
      await f.sync.run();
      expect(f.server.createdCards, 1);
      expect(f.server.transfers, 1);
      expect(f.server.ordered(4).map((c) => c['id']), [20, 9, 10]);
      expect(f.server.cards[20]!['description'], 'Own text');
      expect(await f.database.writesFor(f.account.id), isEmpty);
    },
  );

  test(
    'a SQLite reopen resumes an accepted transfer with only its remaining step',
    () async {
      await f.close();
      fixtureClosed = true;
      final folder = await Directory.systemTemp.createTemp('owndeck-transfer-');
      final file = File('${folder.path}/store.sqlite');
      final original = TransferFixture(
        database: DeckDatabase(NativeDatabase(file)),
      );
      await original.initialize();
      final id = original.account.id;
      await original.queue();
      original.server.failTransferRead = true;
      await original.sync.run();
      await original.close();
      final reopened = DeckDatabase(NativeDatabase(file));
      final account = (await reopened.account(id))!;
      final sender = DeckSync(reopened, account, original.client());
      try {
        original.server.failTransferRead = false;
        await sender.run();
        expect(original.server.transfers, 1);
        expect(original.server.positions, 1);
        expect(await reopened.writesFor(account.id), isEmpty);
      } finally {
        sender.close();
        await reopened.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
