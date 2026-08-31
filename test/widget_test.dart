import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule/main.dart';
import 'package:capsule/tokens.dart';
import 'package:capsule/artboards/onboarding.dart';
import 'package:capsule/artboards/create_pin.dart';
import 'package:capsule/artboards/main_shell.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader(kFontFamily);
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(File('assets/fonts/PlusJakartaSans-$w.ttf')
          .readAsBytes()
          .then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  });

  testWidgets('walks the 3 onboarding slides → PIN → main app', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CapsuleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Slides 1 and 2 show "Next"; the last shows "Get started".
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CreatePinScreen), findsOneWidget);

    // First-time setup: enter the PIN, then confirm it.
    for (var round = 0; round < 2; round++) {
      for (final k in ['1', '2', '3', '4']) {
        await tester.tap(find.text(k));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip jumps straight to the PIN screen', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CapsuleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CreatePinScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('the profile sun/moon chip toggles the whole app theme',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => C.set(AppBrightness.light));

    await tester.pumpWidget(const CapsuleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // First-time setup: enter the PIN, then confirm it.
    for (var round = 0; round < 2; round++) {
      for (final k in ['1', '2', '3', '4']) {
        await tester.tap(find.text(k));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MainShell), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();

    expect(C.isDark, isFalse);
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump();
    expect(C.isDark, isTrue, reason: 'tapping the chip should switch to dark');

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump();
    expect(C.isDark, isFalse, reason: 'tapping again should switch back to light');
  });
}
