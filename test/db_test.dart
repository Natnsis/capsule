import 'package:flutter_test/flutter_test.dart';
import 'package:capsule/db.dart';
import 'package:capsule/app_state.dart';
import 'package:capsule/tokens.dart';

void main() {
  test('SQLite: schema, seed, settings and capsule round-trip', () async {
    final db = Db.instance;
    await db.openInMemory();

    // The seed populates six demo capsules.
    final seeded = await db.allCapsules();
    expect(seeded.length, 6);
    expect(seeded.where((c) => c.sealed).length, 4);
    expect(seeded.where((c) => !c.sealed).length, 2);

    // Settings persist.
    await db.setSetting('brightness', 'dark');
    await db.setSetting('onboarding_done', '1');
    final s = await db.allSettings();
    expect(s['brightness'], 'dark');
    expect(s['onboarding_done'], '1');

    // A store booted from this db reflects persisted state.
    final store = await AppStore.boot(db);
    expect(store.isDark, isTrue);
    expect(store.onboardingDone, isTrue);
    expect(store.capsules.length, 6);

    // Adding a capsule writes through to the db.
    await store.addCapsule(
      title: 'Test capsule',
      note: 'one two three',
      openAt: DateTime.now().add(const Duration(days: 30)),
    );
    expect((await db.allCapsules()).length, 7);
    expect(store.sealedCapsules.any((c) => c.title == 'Test capsule'), isTrue);

    // Wipe clears them.
    await store.deleteAllCapsules();
    expect((await db.allCapsules()), isEmpty);

    C.set(AppBrightness.light);
  });
}
