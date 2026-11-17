import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/passport_models.dart';

class PassportRepository {
  PassportRepository({Database? testDb}) : _db = testDb;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'repair_passport.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: createSchema,
    );
    return _db!;
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE objetos (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand_model TEXT NOT NULL DEFAULT '',
        serial_number TEXT NOT NULL DEFAULT '',
        purchase_date_iso TEXT,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE reparaciones (
        id TEXT PRIMARY KEY,
        object_id TEXT NOT NULL,
        date_iso TEXT NOT NULL,
        symptom TEXT NOT NULL,
        solution TEXT NOT NULL DEFAULT '',
        performed_by TEXT NOT NULL DEFAULT 'Propio / DIY',
        cost_eur REAL NOT NULL DEFAULT 0,
        warranty_months INTEGER NOT NULL DEFAULT 0,
        is_confirmed INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (object_id) REFERENCES objetos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE piezas (
        id TEXT PRIMARY KEY,
        repair_id TEXT NOT NULL,
        name TEXT NOT NULL,
        part_code TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT '',
        cost_eur REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (repair_id) REFERENCES reparaciones(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE adjuntos (
        id TEXT PRIMARY KEY,
        object_id TEXT NOT NULL,
        repair_id TEXT,
        label TEXT NOT NULL,
        local_path TEXT NOT NULL,
        sha256 TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE exportaciones (
        id TEXT PRIMARY KEY,
        object_id TEXT NOT NULL,
        format TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sha256 TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<List<Objeto>> listObjects() async {
    final db = await database;
    final rows = await db.query('objetos', orderBy: 'created_at DESC');
    return rows.map(Objeto.fromMap).toList();
  }

  Future<List<Reparacion>> listRepairs() async {
    final db = await database;
    final rows = await db.query('reparaciones', orderBy: 'date_iso DESC');
    return rows.map(Reparacion.fromMap).toList();
  }

  Future<List<Pieza>> listParts() async {
    final db = await database;
    final rows = await db.query('piezas');
    return rows.map(Pieza.fromMap).toList();
  }

  Future<void> upsertObject(Objeto object) async {
    final db = await database;
    await db.insert(
      'objetos',
      object.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteObject(String objectId) async {
    final db = await database;
    await db.transaction((txn) async {
      final repairs = await txn.query(
        'reparaciones',
        columns: ['id'],
        where: 'object_id = ?',
        whereArgs: [objectId],
      );
      for (final r in repairs) {
        await txn.delete('piezas',
            where: 'repair_id = ?', whereArgs: [r['id']]);
      }
      await txn.delete('reparaciones',
          where: 'object_id = ?', whereArgs: [objectId]);
      await txn.delete('adjuntos',
          where: 'object_id = ?', whereArgs: [objectId]);
      await txn.delete('objetos', where: 'id = ?', whereArgs: [objectId]);
    });
  }

  Future<void> saveRepairWithParts({
    required Reparacion repair,
    List<Pieza> parts = const [],
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'reparaciones',
        repair.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final part in parts) {
        await txn.insert(
          'piezas',
          part.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> recordExport(Exportacion exportRecord) async {
    final db = await database;
    await db.insert(
      'exportaciones',
      exportRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

