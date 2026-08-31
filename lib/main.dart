import 'dart:async';

import 'package:flutter/material.dart';
import 'app_state.dart';
import 'db.dart';
import 'services.dart';
import 'artboards/onboarding.dart';
import 'artboards/create_pin.dart';
import 'tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await _boot();
  unawaited(Notifier.instance.init());
  runApp(CapsuleApp(store: store));
}

Future<AppStore> _boot() async {
  try {
    await Db.instance.open();
    return await AppStore.boot(Db.instance);
  } catch (_) {
    // Storage unavailable (e.g. an unsupported platform) — run in memory.
    return AppStore();
  }
}

class CapsuleApp extends StatefulWidget {
  const CapsuleApp({super.key, this.store});

  final AppStore? store;

  @override
  State<CapsuleApp> createState() => _CapsuleAppState();
}

class _CapsuleAppState extends State<CapsuleApp> {
  late final AppStore _store = widget.store ?? AppStore();
  late final bool _startAtPin = _store.onboardingDone;

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _store,
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final dark = _store.isDark;
          return MaterialApp(
            title: 'Capsule',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: dark ? Brightness.dark : Brightness.light,
              fontFamily: kFontFamily,
              scaffoldBackgroundColor: C.paper,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6E3F9E),
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            home: _startAtPin ? const CreatePinScreen() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
