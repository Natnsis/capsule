import 'dart:io';

import 'package:flutter/widgets.dart';

import 'db.dart';
import 'services.dart';
import 'tokens.dart';

export 'db.dart' show Capsule, Attachment, AppNotification;

/// App-wide state. Backed by SQLite ([Db]) in the running app; falls back to an
/// in-memory demo dataset when constructed without a database (tests, previews).
class AppStore extends ChangeNotifier {
  AppStore([this._db]) {
    C.set(_brightness);
    if (_db == null) _capsules = _demoCapsules();
  }

  final Db? _db;

  AppBrightness _brightness = AppBrightness.light;
  DateTime? _birthday;
  bool _notificationsEnabled = false;
  bool _onboardingDone = false;
  String? _pin;
  DateTime? _wipeArmedAt;
  ImageProvider? _profileImage;
  List<Capsule> _capsules = const [];
  List<AppNotification> _feed = const [];
  int _memId = -1;

  static Future<AppStore> boot(Db db) async {
    final store = AppStore(db);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    final db = _db!;
    final s = await db.allSettings();
    _brightness = s['brightness'] == 'dark' ? AppBrightness.dark : AppBrightness.light;
    C.set(_brightness);
    _birthday = _parseDate(s['birthday']);
    // Default OFF: these only turn on once the user opts in *and* the OS grants
    // the capability. Earlier builds defaulted them ON and persisted '1', so a
    // one-time migration wipes that stale value.
    if (s['settings_schema'] != '2') {
      await db.setSetting('notifications', null);
      await db.setSetting('biometric', null);
      await db.setSetting('settings_schema', '2');
      _notificationsEnabled = false;
      _biometricEnabled = false;
    } else {
      _notificationsEnabled = s['notifications'] == '1';
      _biometricEnabled = s['biometric'] == '1';
    }
    _onboardingDone = s['onboarding_done'] == '1';
    final pin = s['pin'] ?? '';
    _pin = pin.isEmpty ? null : pin;
    final avatar = s['profile_image'] ?? '';
    if (avatar.isNotEmpty && File(avatar).existsSync()) {
      _profileImagePath = avatar;
      _profileImage = FileImage(File(avatar));
    }
    _wipeArmedAt = _parseDate(s['wipe_armed_at']);
    _capsules = await db.allCapsules();

    if (_wipeArmedAt != null && DateTime.now().isAfter(wipeDeletesAt!)) {
      await db.deleteAllCapsules();
      await db.setSetting('wipe_armed_at', null);
      _wipeArmedAt = null;
      _capsules = const [];
    }

    await _emitDueNotifications();
    _feed = await db.allNotifications();
    notifyListeners();
  }

  /// Any sealed capsule whose day has arrived and hasn't been announced yet
  /// gets a feed entry — plus an OS notification when that's allowed.
  Future<void> _emitDueNotifications() async {
    final db = _db;
    if (db == null) return;
    var changed = false;
    for (final c in _capsules) {
      if (c.sealed && c.due && !c.notified) {
        await db.addNotification(
          capsuleId: c.id,
          title: '“${c.title}” is ready to open',
          body: 'Sealed ${c.createdAt.year} · it opened today. Tap to unlock.',
        );
        await db.markNotified(c.id);
        changed = true;
        if (_notificationsEnabled && await Notifier.instance.isGranted) {
          await Notifier.instance
              .show('“${c.title}” is ready', 'Your capsule opened today.');
        }
      }
    }
    if (changed) _capsules = await db.allCapsules();
  }

  Future<void> refresh() async {
    if (_db == null) return;
    await _emitDueNotifications();
    _capsules = await _db.allCapsules();
    _feed = await _db.allNotifications();
    notifyListeners();
  }

  void _put(String key, String? value) => _db?.setSetting(key, value);
  static DateTime? _parseDate(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);
  static int _words(String note) =>
      note.trim().isEmpty ? 0 : note.trim().split(RegExp(r'\s+')).length;

  // ---- Theme -------------------------------------------------------------
  AppBrightness get brightness => _brightness;
  bool get isDark => _brightness == AppBrightness.dark;

  void toggleBrightness() =>
      setBrightness(isDark ? AppBrightness.light : AppBrightness.dark);

  void setBrightness(AppBrightness b) {
    if (b == _brightness) return;
    _brightness = b;
    C.set(b);
    _put('brightness', b == AppBrightness.dark ? 'dark' : 'light');
    notifyListeners();
  }

  // ---- Onboarding / PIN ---------------------------------------------
  bool get onboardingDone => _onboardingDone;
  void completeOnboarding() {
    if (_onboardingDone) return;
    _onboardingDone = true;
    _put('onboarding_done', '1');
    notifyListeners();
  }

  bool get hasPin => _pin != null;
  void setPin(String pin) {
    _pin = pin;
    _put('pin', pin);
    notifyListeners();
  }

  bool checkPin(String pin) => _pin == pin;

  // ---- Notifications permission --------------------------------------
  bool get notificationsEnabled => _notificationsEnabled;
  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _put('notifications', value ? '1' : '0');
    notifyListeners();
  }

  // ---- Biometric sealing preference ----------------------------
  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;
  void setBiometricEnabled(bool value) {
    _biometricEnabled = value;
    _put('biometric', value ? '1' : '0');
    notifyListeners();
  }

  // ---- Notifications feed ----------------------------------------
  List<AppNotification> get notificationsFeed => List.unmodifiable(_feed);
  int get unreadNotifications => _feed.where((n) => !n.read).length;

  Future<void> markNotificationsRead() async {
    await _db?.markAllNotificationsRead();
    _feed = [
      for (final n in _feed)
        AppNotification(
            id: n.id,
            capsuleId: n.capsuleId,
            title: n.title,
            body: n.body,
            createdAt: n.createdAt,
            read: true)
    ];
    notifyListeners();
  }

  // ---- Profile picture ---------------------------------------------
  String? _profileImagePath;
  ImageProvider? get profileImage => _profileImage;
  bool get hasProfileImage => _profileImage != null;
  ImageProvider get profileImageOrPlaceholder =>
      _profileImage ?? const AssetImage('assets/imgs/profile');

  /// Points [_profileImage] at a file the caller already copied into app
  /// storage. Persisted so it survives restarts.
  Future<void> setProfileImageFile(String path) async {
    if (_profileImagePath != null) {
      PaintingBinding.instance.imageCache.evict(FileImage(File(_profileImagePath!)));
    }
    _profileImagePath = path;
    _profileImage = FileImage(File(path));
    _put('profile_image', path);
    notifyListeners();
  }

  void clearProfileImage() {
    _profileImagePath = null;
    _profileImage = null;
    _put('profile_image', null);
    notifyListeners();
  }

  // ---- Birthday ---------------------------------------------------------
  DateTime? get birthday => _birthday;
  bool get hasBirthday => _birthday != null;

  void setBirthday(DateTime? date) {
    _birthday = date;
    _put('birthday', date?.toIso8601String());
    notifyListeners();
  }

  DateTime? nextBirthday({DateTime? from}) {
    final b = _birthday;
    if (b == null) return null;
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    var next = DateTime(today.year, b.month, b.day);
    if (!next.isAfter(today)) next = DateTime(today.year + 1, b.month, b.day);
    return next;
  }

  // ---- Capsules -----------------------------------------------------
  List<Capsule> get capsules => List.unmodifiable(_capsules);
  List<Capsule> get sealedCapsules =>
      _capsules.where((c) => c.sealed).toList()..sort((a, b) => a.openAt.compareTo(b.openAt));
  List<Capsule> get openedCapsules => _capsules.where((c) => c.opened).toList()
    ..sort((a, b) => (b.openedAt ?? b.openAt).compareTo(a.openedAt ?? a.openAt));
  List<Capsule> get draftCapsules => _capsules.where((c) => c.isDraft).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Capsule? byId(int id) {
    for (final c in _capsules) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The card the home screen highlights: the sealed capsule closest to its
  /// open day; if none are sealed, the most recently opened one.
  Capsule? get spotlight {
    final sealed = sealedCapsules;
    if (sealed.isNotEmpty) return sealed.first;
    final opened = openedCapsules;
    return opened.isEmpty ? null : opened.first;
  }

  Future<Capsule> saveDraft({
    int? id,
    required String title,
    required String note,
    required DateTime openAt,
    int photoCount = 0,
  }) async {
    if (_db != null) {
      final c = id == null
          ? await _db.insertCapsule(
              title: title,
              note: note,
              openAt: openAt,
              wordCount: _words(note),
              photoCount: photoCount,
              draft: true,
            )
          : await _db.updateCapsule(id,
              title: title,
              note: note,
              openAt: openAt,
              wordCount: _words(note),
              photoCount: photoCount,
              draft: true);
      _capsules = await _db.allCapsules();
      notifyListeners();
      return c;
    }
    return _memMutate(id, title, note, openAt, photoCount, draft: true);
  }

  Future<Capsule> sealCapsule({
    int? id,
    required String title,
    required String note,
    required DateTime openAt,
    bool bioSealed = false,
    int photoCount = 0,
  }) async {
    if (_db != null) {
      final Capsule c;
      if (id == null) {
        c = await _db.insertCapsule(
          title: title,
          note: note,
          openAt: openAt,
          wordCount: _words(note),
          photoCount: photoCount,
          bioSealed: bioSealed,
        );
      } else {
        c = await _db.updateCapsule(id,
            title: title,
            note: note,
            openAt: openAt,
            wordCount: _words(note),
            photoCount: photoCount,
            draft: false,
            bioSealed: bioSealed);
      }
      _capsules = await _db.allCapsules();
      notifyListeners();
      return c;
    }
    return _memMutate(id, title, note, openAt, photoCount,
        draft: false, bioSealed: bioSealed);
  }

  Future<Capsule> openCapsule(Capsule capsule) async {
    if (_db != null) {
      final c = await _db.markOpened(capsule.id);
      await _db.addNotification(
        capsuleId: c.id,
        title: 'You opened “${c.title}”',
        body: 'Unlocked ${DateTime.now().year}.',
      );
      _capsules = await _db.allCapsules();
      _feed = await _db.allNotifications();
      notifyListeners();
      return c;
    }
    _capsules = [
      for (final c in _capsules)
        if (c.id == capsule.id) _copy(c, openedAt: DateTime.now()) else c
    ];
    notifyListeners();
    return byId(capsule.id)!;
  }

  Future<void> deleteCapsule(int id) async {
    await _db?.deleteCapsule(id);
    _capsules = _capsules.where((c) => c.id != id).toList();
    notifyListeners();
  }

  Future<void> deleteAllCapsules() async {
    await _db?.deleteAllCapsules();
    _capsules = const [];
    if (_wipeArmedAt != null) {
      _wipeArmedAt = null;
      _put('wipe_armed_at', null);
    }
    notifyListeners();
  }

  // ---- Attachments -----------------------------------------------
  Future<void> addAttachment(
      int capsuleId, String name, String path, String kind) async {
    await _db?.addAttachment(capsuleId, name, path, kind);
    if (_db != null) {
      _capsules = await _db.allCapsules();
    } else {
      _capsules = [
        for (final c in _capsules)
          if (c.id == capsuleId)
            _copy(c, attachments: [
              ...c.attachments,
              Attachment(
                  id: _memId--,
                  capsuleId: capsuleId,
                  name: name,
                  path: path,
                  kind: kind),
            ])
          else
            c
      ];
    }
    notifyListeners();
  }

  Future<void> removeAttachment(int capsuleId, int attachmentId) async {
    await _db?.removeAttachment(attachmentId);
    if (_db != null) {
      _capsules = await _db.allCapsules();
    } else {
      _capsules = [
        for (final c in _capsules)
          if (c.id == capsuleId)
            _copy(c,
                attachments:
                    c.attachments.where((a) => a.id != attachmentId).toList())
          else
            c
      ];
    }
    notifyListeners();
  }

  // ---- Delete-everything request -------------------------------------
  DateTime? get wipeArmedAt => _wipeArmedAt;
  bool get wipePending => _wipeArmedAt != null;
  DateTime? get wipeDeletesAt => _wipeArmedAt?.add(const Duration(days: 7));

  int get wipeDaysLeft {
    final at = wipeDeletesAt;
    if (at == null) return 0;
    return at.difference(DateTime.now()).inDays.clamp(0, 7) + 1;
  }

  void armWipe() {
    _wipeArmedAt = DateTime.now();
    _put('wipe_armed_at', _wipeArmedAt!.toIso8601String());
    notifyListeners();
  }

  void cancelWipe() {
    _wipeArmedAt = null;
    _put('wipe_armed_at', null);
    notifyListeners();
  }

  // ---- In-memory helpers ----------------------------------------
  Capsule _copy(Capsule c,
          {DateTime? openedAt, List<Attachment>? attachments, bool? isDraft}) =>
      Capsule(
        id: c.id,
        title: c.title,
        note: c.note,
        createdAt: c.createdAt,
        openAt: c.openAt,
        openedAt: openedAt ?? c.openedAt,
        wordCount: c.wordCount,
        photoCount: c.photoCount,
        isDraft: isDraft ?? c.isDraft,
        bioSealed: c.bioSealed,
        notified: c.notified,
        attachments: attachments ?? c.attachments,
      );

  Future<Capsule> _memMutate(int? id, String title, String note, DateTime openAt,
      int photoCount,
      {required bool draft, bool bioSealed = false}) async {
    final existing = id == null ? null : byId(id);
    final c = Capsule(
      id: id ?? (_memId--),
      title: title,
      note: note,
      createdAt: existing?.createdAt ?? DateTime.now(),
      openAt: openAt,
      wordCount: _words(note),
      photoCount: photoCount,
      isDraft: draft,
      bioSealed: bioSealed,
      attachments: existing?.attachments ?? const [],
    );
    _capsules = [
      for (final e in _capsules)
        if (e.id != c.id) e,
      c,
    ];
    notifyListeners();
    return c;
  }

  static List<Capsule> _demoCapsules() {
    final now = DateTime.now();
    DateTime d(int days) => now.add(Duration(days: days));
    var id = 0;
    Capsule mk(String title, String note, DateTime openAt,
        {DateTime? openedAt, int photos = 0, bool draft = false}) {
      return Capsule(
        id: ++id,
        title: title,
        note: note,
        createdAt: d(-200),
        openAt: openAt,
        openedAt: openedAt,
        wordCount: _words(note),
        photoCount: photos,
        isDraft: draft,
      );
    }

    return [
      mk('To me, at 25', 'A letter to the person I hope to be.', d(3), photos: 2),
      mk('Wedding day letter', 'Read this the morning of.', d(365 * 5 + 40), photos: 1),
      mk('One year of Capsule', 'Marking the first year.', d(120)),
      mk('Thirty', 'Thoughts before the big one.', d(365 * 3 + 20)),
      mk('First week notes', 'The very first entry.', d(-400), openedAt: d(-200)),
      mk('Letter before the move', 'Written the night before leaving.', d(-500),
          openedAt: d(-300)),
      mk('Half-written to Sam', 'Still figuring out what to say…', d(200), draft: true),
    ];
  }
}

/// Exposes [AppStore] to the tree. Widgets that read it via [AppScope.of]
/// rebuild when it changes; use [AppScope.read] inside callbacks.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore super.notifier, required super.child});

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope)
          .notifier!;
}
