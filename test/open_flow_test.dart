import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule/app_state.dart';
import 'package:capsule/tokens.dart';
import 'package:capsule/artboards/sealed_detail.dart';
import 'package:capsule/artboards/open_day.dart';
import 'package:capsule/nav.dart';

Future<void> _fonts() async {
  final loader = FontLoader(kFontFamily);
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(File('assets/fonts/PlusJakartaSans-$w.ttf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_fonts);
  tearDown(() => C.set(AppBrightness.light));

  testWidgets('tapping "ready to open" marks the capsule opened and leaves Sealed',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    final due = await store.sealCapsule(
      title: 'Past me',
      note: 'hello from before',
      openAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(store.sealedCapsules.map((c) => c.id), contains(due.id));
    expect(store.isDue(store.byId(due.id)!), isTrue);

    await tester.pumpWidget(AppScope(
      notifier: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: kFontFamily),
        home: SealedDetailScreen(capsuleId: due.id),
      ),
    ));
    // The "ready" card has a looping pulse, so drive frames explicitly rather
    // than pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('OPENS IN'), findsNothing);
    expect(find.text('READY TO OPEN'), findsOneWidget);

    await tester.tap(find.text('Tap to open it now'));
    await tester.pump(); // kick off the async open
    await tester.pump(const Duration(milliseconds: 400)); // openCapsule + route
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(OpenDayScreen), findsOneWidget);
    expect(store.byId(due.id)!.opened, isTrue);
    expect(store.sealedCapsules.map((c) => c.id), isNot(contains(due.id)));
    expect(store.openedCapsules.map((c) => c.id), contains(due.id));
  });

  testWidgets('an opened capsule can be deleted from its screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    final c = await store.sealCapsule(
      title: 'Old letter',
      note: 'kept for years',
      openAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    await store.openCapsule(c);

    await tester.pumpWidget(AppScope(
      notifier: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: kFontFamily),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    go(context, OpenDayScreen(title: c.title, capsuleId: c.id)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete this capsule'));
    await tester.pumpAndSettle();

    // Wistful copy, not the blunt sealed one.
    expect(find.text('Let this one go?'), findsOneWidget);
    await tester.tap(find.text('Delete it'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.byId(c.id), isNull);
    expect(find.byType(OpenDayScreen), findsNothing); // popped back
  });
}
