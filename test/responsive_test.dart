import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule/app_state.dart';
import 'package:capsule/tokens.dart';
import 'package:capsule/artboards/onboarding.dart';
import 'package:capsule/artboards/create_pin.dart';
import 'package:capsule/artboards/biometric_seal.dart';
import 'package:capsule/artboards/new_capsule.dart';
import 'package:capsule/artboards/sealed_detail.dart';
import 'package:capsule/artboards/open_day.dart';
import 'package:capsule/artboards/notifications.dart';
import 'package:capsule/artboards/profile.dart';
import 'package:capsule/artboards/pick_date.dart';
import 'package:capsule/artboards/capsule_list.dart';

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

  final screens = <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'create_pin': const CreatePinScreen(),
    'biometric_seal':
        BiometricSealScreen(title: 'To me, at 25', openOn: DateTime(2027, 3, 1)),
    'new_capsule': const NewCapsuleScreen(),
    'sealed_detail':
        SealedDetailScreen(title: 'To me, at 25', openOn: DateTime(2027, 3, 1)),
    'open_day': const OpenDayScreen(),
    'notifications': const NotificationsScreen(),
    'profile': const ProfileScreen(),
    'capsule_list': const CapsuleListScreen(),
  };

  // Every screen, at a cramped "mini phone" viewport, must lay out without a
  // RenderFlex/paint overflow (content scrolls instead).
  tearDown(() => C.set(AppBrightness.light));

  for (final size in const [
    Size(320, 480),
    Size(360, 640),
    Size(390, 844),
    Size(720, 700), // wide + short (e.g. resized desktop window)
  ]) {
    for (final mode in AppBrightness.values) {
      final tag = mode == AppBrightness.dark ? ' [dark]' : '';
      screens.forEach((name, screen) {
        testWidgets(
            '$name fits ${size.width.toInt()}x${size.height.toInt()}$tag',
            (tester) async {
          C.set(mode);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(AppScope(
            notifier: AppStore()..setBrightness(mode),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: kFontFamily),
              home: screen,
            ),
          ));
          await tester.pump(const Duration(milliseconds: 120));
          expect(tester.takeException(), isNull,
              reason: '$name overflowed at $size ($mode)');
        });
      });
    }
  }

  testWidgets('pick-date sheet fits a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AppScope(
      notifier: AppStore(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: kFontFamily),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<DateTime>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const PickDateSheet(title: 'To me, at 25'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
