import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dzikir_fixture.dart';

void main() {
  Future<void> openDzikirTab(WidgetTester tester, DzikirHarness h) async {
    await tester.pumpWidget(h.app());
    await tester.tap(find.byKey(const ValueKey('tab-dzikir')));
    await tester.pump();
  }

  Future<void> openPagi(WidgetTester tester, DzikirHarness h) async {
    await openDzikirTab(tester, h);
    await tester.tap(find.text('Dzikir pagi'));
    await tester.pumpAndSettle();
  }

  Offset center(WidgetTester tester) =>
      tester.getCenter(find.byType(Scaffold).last);

  testWidgets('list suggests pagi in the morning', (tester) async {
    final h = DzikirHarness();
    await openDzikirTab(tester, h);

    expect(find.text('Pagi, belum'), findsOneWidget);
    expect(find.text('Petang, belum'), findsOneWidget);
    expect(find.text('SEKARANG'), findsOneWidget);
  });

  testWidgets('taps and swipes count; edges do not', (tester) async {
    final h = DzikirHarness();
    await openPagi(tester, h);
    expect(h.awake, [true]);
    expect(find.text('0'), findsOneWidget);

    await tester.tapAt(center(tester));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(h.store.progress['pagi']?.count, 1);

    final size = tester.getSize(find.byType(Scaffold).last);
    await tester.tapAt(Offset(4, size.height / 2));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.dragFrom(center(tester), const Offset(0, -120));
    await tester.pump();

    expect(h.feedback.events, [
      DzikirEvent.counted,
      DzikirEvent.entryCompleted,
    ]);
    expect(find.text('Selesai (1/2)'), findsOneWidget);
    expect(h.store.progress['pagi']?.entryIndex, 1);
  });

  testWidgets('read entries count with the done button', (tester) async {
    final h = DzikirHarness();
    await openPagi(tester, h);
    await tester.tapAt(center(tester));
    await tester.tapAt(center(tester));
    await tester.pump();

    // Tapping the text itself must not count in read mode.
    await tester.tap(find.text('Long recitation'));
    await tester.pump();
    expect(find.text('Selesai (1/2)'), findsOneWidget);

    await tester.tap(find.text('Selesai (1/2)'));
    await tester.pump();
    expect(find.text('Selesai, lanjut'), findsOneWidget);

    await tester.tap(find.text('Selesai, lanjut'));
    await tester.pump();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('dari 1'), findsOneWidget);
  });

  testWidgets('finishing records completion and clears progress', (
    tester,
  ) async {
    final h = DzikirHarness();
    await openPagi(tester, h);
    await tester.tapAt(center(tester));
    await tester.tapAt(center(tester));
    await tester.pump();
    await tester.tap(find.text('Selesai (1/2)'));
    await tester.pump();
    await tester.tap(find.text('Selesai, lanjut'));
    await tester.pump();
    await tester.tapAt(center(tester));
    await tester.pump();

    expect(find.text('Dzikir pagi selesai'), findsOneWidget);
    expect(h.feedback.events.last, DzikirEvent.sessionCompleted);
    expect(h.store.progress, isNot(contains('pagi')));
    expect(h.store.completed['pagi'], h.now);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(h.awake, [true, false]);
    expect(find.text('Selesai hari ini'), findsOneWidget);
    expect(find.text('Pagi, selesai'), findsOneWidget);
    expect(find.text('Petang, belum'), findsOneWidget);
  });

  testWidgets('reopening resumes stored progress', (tester) async {
    final h = DzikirHarness();
    h.store.progress['pagi'] = DzikirProgress(
      collectionId: 'pagi',
      entryIndex: 0,
      count: 1,
      updatedAt: h.now.subtract(const Duration(minutes: 20)),
    );
    await openDzikirTab(tester, h);
    expect(find.text('Lanjut · 0 dari 3'), findsOneWidget);

    await tester.tap(find.text('Dzikir pagi'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('free tasbih keeps counting past its goal', (tester) async {
    final h = DzikirHarness();
    await openDzikirTab(tester, h);
    await tester.tap(find.text('Tasbih bebas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('33').first);
    await tester.pump();
    await tester.tap(find.text('Subhanallah'));
    await tester.pumpAndSettle();
    expect(find.text('Target 33'), findsOneWidget);

    for (var i = 0; i < 34; i++) {
      await tester.tapAt(center(tester));
    }
    await tester.pump();

    expect(find.text('34'), findsOneWidget);
    expect(
      find.text('Target tercapai · boleh lanjut menghitung'),
      findsOneWidget,
    );
    expect(h.feedback.events[32], DzikirEvent.sessionCompleted);
    expect(h.store.progress['free:short']?.count, 34);
  });
}
