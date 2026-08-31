import 'package:flutter/widgets.dart';

import 'db.dart';
import 'tokens.dart';

export 'db.dart' show Capsule;

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
  bool _notificationsEnabled = true;
  bool _onboardingDone = false;
  String? _pin;
  DateTime? _wipeArmedAt;
  ImageProvider? _profileImage;
  List<Capsule> _capsules = const [];

  /// Build a store backed by [db], loading everything persisted.
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
    _notificationsEnabled = s['notifications'] != '0';
    _onboardingDone = s['onboarding_done'] == '1';
    final pin = s['pin'] ?? '';
    _pin = pin.isEmpty ? null : pin;
    _wipeArmedAt = _parseDate(s['wipe_armed_at']);
    _capsules = await db.allCapsules();

    // If a scheduled wipe has come due while the app was closed, honour it.
    if (_wipeArmedAt != null && DateTime.now().isAfter(wipeDeletesAt!)) {
      await db.deleteAllCapsules();
      await db.setSetting('wipe_armed_at', null);
      _wipeArmedAt = null;
      _capsules = const [];
    }
    notifyListeners();
  }

  void _put(String key, String? value) => _db?.setSetting(key, value);
  static DateTime? _parseDate(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

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

  bool checkPin(String pin) => _pin == null || _pin == pin;

  // ---- Notifications permission --------------------------------------
  bool get notificationsEnabled => _notificationsEnabled;
  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _put('notifications', value ? '1' : '0');
    notifyListeners();
  }

  // ---- Profile picture ---------------------------------------------
  ImageProvider? get profileImage => _profileImage;
  ImageProvider get profileImageOrPlaceholder =>
      _profileImage ?? const AssetImage('assets/imgs/profile');

  void setProfileImage(ImageProvider? image) {
    _profileImage = image;
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
  List<Capsule> get openedCapsules => _capsules.where((c) => !c.sealed).toList()
    ..sort((a, b) => (b.openedAt ?? b.openAt).compareTo(a.openedAt ?? a.openAt));

  Future<Capsule> addCapsule({
    required String title,
    required String note,
    required DateTime openAt,
    int photoCount = 0,
  }) async {
    final words =
        note.trim().isEmpty ? 0 : note.trim().split(RegExp(r'\s+')).length;
    late final Capsule c;
    if (_db != null) {
      c = await _db.insertCapsule(
        title: title,
        note: note,
        openAt: openAt,
        wordCount: words,
        photoCount: photoCount,
      );
    } else {
      c = Capsule(
        id: DateTime.now().microsecondsSinceEpoch,
        title: title,
        note: note,
        createdAt: DateTime.now(),
        openAt: openAt,
        wordCount: words,
        photoCount: photoCount,
      );
    }
    _capsules = [..._capsules, c];
    notifyListeners();
    return c;
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

  // ---- In-memory demo data (no database) --------------------------
  static List<Capsule> _demoCapsules() {
    final now = DateTime.now();
    DateTime d(int days) => now.add(Duration(days: days));
    var id = 0;
    Capsule mk(String title, String note, DateTime openAt,
        {DateTime? openedAt, int photos = 0}) {
      final w = note.trim().isEmpty ? 0 : note.trim().split(RegExp(r'\s+')).length;
      return Capsule(
        id: ++id,
        title: title,
        note: note,
        createdAt: d(-200),
        openAt: openAt,
        openedAt: openedAt,
        wordCount: w,
        photoCount: photos,
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
