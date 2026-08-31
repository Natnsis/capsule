import 'package:flutter_test/flutter_test.dart';
import 'package:capsule/db.dart';
import 'package:capsule/app_state.dart';
import 'package:capsule/tokens.dart';

void main() {
  test('SQLite: starts empty, then round-trips real data', () async {
    final db = Db.instance;
    await db.openInMemory();

    // No seed — a fresh device has nothing.
    expect(await db.allCapsules(), isEmpty);

    // Settings persist.
    await db.setSetting('brightness', 'dark');
    await db.setSetting('onboarding_done', '1');
    await db.setSetting('pin', '4321');
    final s = await db.allSettings();
    expect(s['brightness'], 'dark');
    expect(s['onboarding_done'], '1');

    final store = await AppStore.boot(db);
    expect(store.isDark, isTrue);
    expect(store.onboardingDone, isTrue);
    expect(store.hasPin, isTrue);
    expect(store.checkPin('4321'), isTrue);
    expect(store.checkPin('0000'), isFalse);
    expect(store.capsules, isEmpty);

    // Seal a capsule.
    await store.sealCapsule(
      title: 'To me',
      note: 'one two three',
      openAt: DateTime.now().add(const Duration(days: 30)),
    );
    expect(store.sealedCapsules.length, 1);
    expect((await db.allCapsules()).single.wordCount, 3);

    // Draft, edit, then activate (draft -> sealed).
    final draft = await store.saveDraft(
      title: 'Draftish',
      note: 'x',
      openAt: DateTime.now().add(const Duration(days: 10)),
    );
    expect(store.draftCapsules.map((c) => c.id), contains(draft.id));
    await store.sealCapsule(
      id: draft.id,
      title: 'Draftish',
      note: 'x y',
      openAt: draft.openAt,
    );
    expect(store.draftCapsules.map((c) => c.id), isNot(contains(draft.id)));
    expect(store.sealedCapsules.map((c) => c.id), contains(draft.id));

    // Attachment round-trip.
    await store.addAttachment(draft.id, 'clip.m4a', '/tmp/clip.m4a', 'audio');
    expect(store.byId(draft.id)!.attachments.single.kind, 'audio');

    // Delete.
    await store.deleteCapsule(draft.id);
    expect(store.byId(draft.id), isNull);

    C.set(AppBrightness.light);
  });

  test('a due capsule generates a notification on load', () async {
    // Fresh in-memory db (the previous test's instance is reused, so clear it).
    final db = Db.instance;
    for (final c in await db.allCapsules()) {
      await db.deleteCapsule(c.id);
    }
    await db.insertCapsule(
      title: 'Was due',
      note: 'hi',
      openAt: DateTime.now().subtract(const Duration(days: 1)),
      wordCount: 1,
      photoCount: 0,
    );
    final store = await AppStore.boot(db);
    expect(store.notificationsFeed, isNotEmpty);
    expect(store.notificationsFeed.first.title, contains('Was due'));
  });
}
