import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  });

  final int id;
  final String title;
  final String note;
  final DateTime createdAt;
  final DateTime openAt;
  final DateTime? openedAt;
  final int wordCount;
  final int photoCount;

  bool get sealed => openedAt == null;

  factory Capsule.fromRow(Map<String, Object?> r) => Capsule(
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
      );
}

/// Thin SQLite wrapper. One database file, two tables: `settings` (key/value)
/// and `capsules`.
class Db {
  Db._();
  static final Db instance = Db._();

  late Database _db;
  bool _open = false;

  Future<void> open() async {
    if (_open) return;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    _db = await databaseFactory.openDatabase(
      p.join(dir.path, 'capsule.db'),
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
    await _seedIfEmpty();
    _open = true;
  }

  /// For tests: an isolated in-memory database.
  Future<void> openInMemory() async {
    if (_open) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
    await _seedIfEmpty();
    _open = true;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
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
        photo_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
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
    return rows.map(Capsule.fromRow).toList();
  }

  Future<Capsule> insertCapsule({
    required String title,
    required String note,
    required DateTime openAt,
    required int wordCount,
    required int photoCount,
    DateTime? openedAt,
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
    });
    return Capsule(
      id: id,
      title: title,
      note: note,
      createdAt: now,
      openAt: openAt,
      openedAt: openedAt,
      wordCount: wordCount,
      photoCount: photoCount,
    );
  }

  Future<void> markOpened(int id) => _db.update(
        'capsules',
        {'opened_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND opened_at IS NULL',
        whereArgs: [id],
      );

  Future<void> deleteAllCapsules() => _db.delete('capsules');

  Future<void> _seedIfEmpty() async {
    final count = Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM capsules'));
    if ((count ?? 0) > 0) return;

    final now = DateTime.now();
    DateTime d(int days) => now.add(Duration(days: days));

    Future<void> add(String title, String note, DateTime openAt,
        {DateTime? openedAt, int photos = 0}) {
      final words = note.trim().isEmpty ? 0 : note.trim().split(RegExp(r'\s+')).length;
      return _db.insert('capsules', {
        'title': title,
        'note': note,
        'created_at': d(-200).millisecondsSinceEpoch,
        'open_at': openAt.millisecondsSinceEpoch,
        'opened_at': openedAt?.millisecondsSinceEpoch,
        'word_count': words,
        'photo_count': photos,
      });
    }

    await add(
      'To me, at 25',
      "Hey. You're 25 now, which sounds impossible from here. Things I hope are "
          "still true: you still call home on Sundays, you still keep the notebook.",
      d(3),
      photos: 2,
    );
    await add('Wedding day letter', 'Read this the morning of. Breathe.', d(365 * 5 + 40),
        photos: 1);
    await add('One year of Capsule', 'A note to mark the first year.', d(120));
    await add('Thirty', 'Thoughts before the big one.', d(365 * 3 + 20));
    await add('First week notes', 'The very first entry.', d(-400), openedAt: d(-200));
    await add('Letter before the move', 'Written the night before leaving.', d(-500),
        openedAt: d(-300));
  }
}
