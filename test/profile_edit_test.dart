import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule/app_state.dart';
import 'package:capsule/tokens.dart';
import 'package:capsule/artboards/profile.dart';

Future<void> _fonts() async {
  final loader = FontLoader(kFontFamily);
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(File('assets/fonts/PlusJakartaSans-$w.ttf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

Widget _host(AppStore store) => AppScope(
      notifier: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: kFontFamily),
        home: const ProfileScreen(),
      ),
    );

void main() {
  setUpAll(_fonts);
  tearDown(() => C.set(AppBrightness.light));

  testWidgets('editing the name updates the header without a build-scope error',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    await tester.pumpWidget(_host(store));
    await tester.pumpAndSettle();

    // No name yet → "Guest".
    expect(find.text('Guest'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nati');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.name, 'Nati');
    expect(find.text('Nati'), findsOneWidget);
  });

  testWidgets('clearing the name falls back to Guest', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore()..setName('Nati');
    await tester.pumpWidget(_host(store));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.hasName, isFalse);
    expect(find.text('Guest'), findsOneWidget);
  });

  testWidgets('birthday sheet returns a month/day with no year dependence',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    await tester.pumpWidget(_host(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Birthday'));
    await tester.pumpAndSettle();

    expect(find.text('Your birthday'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.hasBirthday, isTrue);
    expect(store.birthday!.year, 2000); // sentinel — year is not meaningful
  });
}
