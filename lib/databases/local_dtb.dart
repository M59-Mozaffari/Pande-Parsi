import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pand.dart';
import 'package:sqflite/sqflite.dart';

class LocalDtb {
  static final LocalDtb instance = LocalDtb._init();
  static Database? _database;

  LocalDtb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pands.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, fileName);

    return await openDatabase(
      path,
      version: 3, // 🔥 افزایش نسخه
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ================= CREATE =================

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pands(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        sentence TEXT NOT NULL,
        teller TEXT NOT NULL,
        category TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 🔥 جدول جدید برای نوتیف
    await db.execute('''
      CREATE TABLE pand_notification_state(
        pand_id INTEGER PRIMARY KEY,
        shown_count INTEGER NOT NULL DEFAULT 0,
        last_shown_at TEXT
      )
    ''');
  }

  // ================= UPGRADE =================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE pands ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pand_notification_state(
          pand_id INTEGER PRIMARY KEY,
          shown_count INTEGER NOT NULL DEFAULT 0,
          last_shown_at TEXT
        )
      ''');
    }
  }

  // ================= PAND CRUD =================

  Future<void> insertPand(Pand pand) async {
    final db = await database;
    await db.insert(
      'pands',
      pand.toMap()..['id'] = pand.id,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePand(Pand pand) async {
    final db = await database;
    await db.update(
      'pands',
      pand.toMap(),
      where: 'id = ?',
      whereArgs: [pand.id],
    );
  }

  Future<void> deletePand(int id) async {
    final db = await database;

    // حذف پند
    await db.delete('pands', where: 'id = ?', whereArgs: [id]);

    // 🔥 حذف state مربوط به نوتیف (خیلی مهم)
    await db.delete(
      'pand_notification_state',
      where: 'pand_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Pand>> getAllPands() async {
    final db = await database;
    final maps = await db.query('pands');
    return maps.map((map) => Pand.fromMap(map)).toList();
  }

  Future<Pand?> getPandById(int id) async {
    final db = await database;
    final maps = await db.query('pands', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Pand.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Pand>> searchPands(String query) async {
    final db = await database;
    final maps = await db.query(
      'pands',
      where: 'title LIKE ? OR sentence LIKE ? OR teller LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );

    return maps.map((map) => Pand.fromMap(map)).toList();
  }

  // ================= NOTIFICATION STATE =================

  /// 🔥 گرفتن تعداد نمایش
  Future<int> getShownCount(int pandId) async {
    final db = await database;

    final result = await db.query(
      'pand_notification_state',
      where: 'pand_id = ?',
      whereArgs: [pandId],
    );

    if (result.isEmpty) return 0;

    return (result.first['shown_count'] as int?) ?? 0;
  }

  /// 🔥 افزایش تعداد نمایش
  Future<void> incrementShownCount(int pandId) async {
    final db = await database;

    final currentCount = await getShownCount(pandId);

    await db.insert('pand_notification_state', {
      'pand_id': pandId,
      'shown_count': currentCount + 1,
      'last_shown_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 🔥 ریست کل چرخه
  Future<void> resetAllShownCounts() async {
    final db = await database;

    await db.update('pand_notification_state', {'shown_count': 0});
  }

  /// 🔥 (اختیاری ولی حرفه‌ای) گرفتن قدیمی‌ترین پند
  Future<List<int>> getLeastShownPandIds() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT pand_id FROM pand_notification_state
      ORDER BY shown_count ASC, last_shown_at ASC
    ''');

    return result.map((e) => e['pand_id'] as int).toList();
  }

  // ================= CLOSE =================

  Future<void> close() async {
    final db = await database;
    _database = null;
    db.close();
  }
}
