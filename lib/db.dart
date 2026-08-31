import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// sqflite provides the native databaseFactory on Android/iOS; keep it explicit.
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A file the writer attached to a capsule (photo or document).
class Attachment {
  Attachment({
    required this.id,
    required this.capsuleId,
    required this.name,
    required this.path,
    required this.kind,
  });

  final int id;
  final int capsuleId;
  final String name;
  final String path;

  /// 'image' or 'file'.
  final String kind;

  bool get isImage => kind == 'image';

  factory Attachment.fromRow(Map<String, Object?> r) => Attachment(
        id: r['id'] as int,
        capsuleId: r['capsule_id'] as int,
        name: r['name'] as String,
        path: r['path'] as String,
        kind: r['kind'] as String? ?? 'file',
      );
}

/// One capsule as stored on the device.
class Capsule {
  Capsule({
    required this.id,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.openAt,
    this.openedAt,
    required this.wordCount,
    required this.photoCount,
    this.isDraft = false,
    this.bioSealed = false,
    this.notified = false,
    this.attachments = const [],
  });

  final int id;
  final String title;
  final String note;
  final DateTime createdAt;
  final DateTime openAt;
  final DateTime? openedAt;
  final int wordCount;
  final int photoCount;
  final bool isDraft;
  final bool bioSealed;
  final bool notified;
  final List<Attachment> attachments;

  bool get opened => openedAt != null;
  bool get sealed => !isDraft && openedAt == null;

  /// Ready to open: sealed and its day has arrived.
  bool get due => sealed && !openAt.isAfter(DateTime.now());

  factory Capsule.fromRow(Map<String, Object?> r,
          {List<Attachment> attachments = const []}) =>
      Capsule(
        id: r['id'] as int,
        title: r['title'] as String,
        note: r['note'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        openAt: DateTime.fromMillisecondsSinceEpoch(r['open_at'] as int),
        openedAt: r['opened_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['opened_at'] as int),
        wordCount: (r['word_count'] as int?) ?? 0,
        photoCount: (r['photo_count'] as int?) ?? 0,
        isDraft: (r['draft'] as int? ?? 0) == 1,
        bioSealed: (r['bio_sealed'] as int? ?? 0) == 1,
        notified: (r['notified'] as int? ?? 0) == 1,
        attachments: attachments,
      );
}

/// An entry in the in-app Notifications feed.
class AppNotification {
  AppNotification({
    required this.id,
    this.capsuleId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  final int id;
  final int? capsuleId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory AppNotification.fromRow(Map<String, Object?> r) => AppNotification(
        id: r['id'] as int,
        capsuleId: r['capsule_id'] as int?,
        title: r['title'] as String,
        body: r['body'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        read: (r['read'] as int? ?? 0) == 1,
      );
}

/// Thin SQLite wrapper.
class Db {
  Db._();
  static final Db instance = Db._();

  late Database _db;
  bool _open = false;

  static const _version = 2;

  Future<void> open() async {
    if (_open) return;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    _db = await databaseFactory.openDatabase(
      p.join(dir.path, 'capsule.db'),
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
    _open = true;
  }

  /// For tests: an isolated in-memory database.
  Future<void> openInMemory() async {
    if (_open) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: _version, onCreate: _create),
    );
    _open = true;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)
    ''');
    await db.execute('''
      CREATE TABLE capsules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        open_at INTEGER NOT NULL,
        opened_at INTEGER,
        word_count INTEGER NOT NULL DEFAULT 0,
        photo_count INTEGER NOT NULL DEFAULT 0,
        draft INTEGER NOT NULL DEFAULT 0,
        bio_sealed INTEGER NOT NULL DEFAULT 0,
        notified INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        capsule_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'file'
      )
    ''');
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        capsule_id INTEGER,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        read INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) {
      for (final col in [
        'draft INTEGER NOT NULL DEFAULT 0',
        'bio_sealed INTEGER NOT NULL DEFAULT 0',
        'notified INTEGER NOT NULL DEFAULT 0',
      ]) {
        await db.execute('ALTER TABLE capsules ADD COLUMN $col');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS attachments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          capsule_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          kind TEXT NOT NULL DEFAULT 'file'
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          capsule_id INTEGER,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          read INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // ---- settings ------------------------------------------------------
  Future<Map<String, String>> allSettings() async {
    final rows = await _db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String? ?? ''};
  }

  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await _db.delete('settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await _db.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ---- capsules -----------------------------------------------------
  Future<List<Capsule>> allCapsules() async {
    final rows = await _db.query('capsules', orderBy: 'open_at ASC');
    final atts = await _db.query('attachments');
    final byCapsule = <int, List<Attachment>>{};
    for (final r in atts) {
      final a = Attachment.fromRow(r);
      byCapsule.putIfAbsent(a.capsuleId, () => []).add(a);
    }
    return rows
        .map((r) => Capsule.fromRow(r, attachments: byCapsule[r['id']] ?? const []))
        .toList();
  }

  Future<Capsule> _reload(int id) async {
    final rows = await _db.query('capsules', where: 'id = ?', whereArgs: [id], limit: 1);
    final atts = await _db.query('attachments', where: 'capsule_id = ?', whereArgs: [id]);
    return Capsule.fromRow(rows.first,
        attachments: atts.map(Attachment.fromRow).toList());
  }

  Future<Capsule> insertCapsule({
    required String title,
    required String note,
    required DateTime openAt,
    required int wordCount,
    required int photoCount,
    DateTime? openedAt,
    bool draft = false,
    bool bioSealed = false,
  }) async {
    final now = DateTime.now();
    final id = await _db.insert('capsules', {
      'title': title,
      'note': note,
      'created_at': now.millisecondsSinceEpoch,
      'open_at': openAt.millisecondsSinceEpoch,
      'opened_at': openedAt?.millisecondsSinceEpoch,
      'word_count': wordCount,
      'photo_count': photoCount,
      'draft': draft ? 1 : 0,
      'bio_sealed': bioSealed ? 1 : 0,
    });
    return _reload(id);
  }

  Future<Capsule> updateCapsule(
    int id, {
    String? title,
    String? note,
    DateTime? openAt,
    int? wordCount,
    int? photoCount,
    bool? draft,
    bool? bioSealed,
  }) async {
    final values = <String, Object?>{};
    if (title != null) values['title'] = title;
    if (note != null) values['note'] = note;
    if (openAt != null) values['open_at'] = openAt.millisecondsSinceEpoch;
    if (wordCount != null) values['word_count'] = wordCount;
    if (photoCount != null) values['photo_count'] = photoCount;
    if (draft != null) values['draft'] = draft ? 1 : 0;
    if (bioSealed != null) values['bio_sealed'] = bioSealed ? 1 : 0;
    if (values.isNotEmpty) {
      await _db.update('capsules', values, where: 'id = ?', whereArgs: [id]);
    }
    return _reload(id);
  }

  Future<Capsule> markOpened(int id) async {
    await _db.update(
      'capsules',
      {'opened_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ? AND opened_at IS NULL',
      whereArgs: [id],
    );
    return _reload(id);
  }

  Future<void> markNotified(int id) => _db.update('capsules', {'notified': 1},
      where: 'id = ?', whereArgs: [id]);

  Future<void> deleteCapsule(int id) async {
    await _db.delete('attachments', where: 'capsule_id = ?', whereArgs: [id]);
    await _db.delete('capsules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllCapsules() async {
    await _db.delete('attachments');
    await _db.delete('capsules');
  }

  // ---- attachments ------------------------------------------------
  Future<void> addAttachment(int capsuleId, String name, String path, String kind) =>
      _db.insert('attachments',
          {'capsule_id': capsuleId, 'name': name, 'path': path, 'kind': kind});

  Future<void> removeAttachment(int id) =>
      _db.delete('attachments', where: 'id = ?', whereArgs: [id]);

  // ---- notifications feed --------------------------------------
  Future<List<AppNotification>> allNotifications() async {
    final rows = await _db.query('notifications', orderBy: 'created_at DESC');
    return rows.map(AppNotification.fromRow).toList();
  }

  Future<void> addNotification({
    int? capsuleId,
    required String title,
    required String body,
  }) =>
      _db.insert('notifications', {
        'capsule_id': capsuleId,
        'title': title,
        'body': body,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'read': 0,
      });

  Future<void> markAllNotificationsRead() =>
      _db.update('notifications', {'read': 1});
}
