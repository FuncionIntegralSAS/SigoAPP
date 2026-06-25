import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sigoapp_inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Inicializar FFI si estamos ejecutando la app en escritorio (Windows/Linux)
    // kIsWeb asegura que no intentemos acceder a dart:io en el navegador
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (kIsWeb) {
      throw UnsupportedError(
        'La base de datos SQLite no está configurada para Web aún.',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // Tabla 1: Formulario Activo (Cabecera)
    await db.execute('''
      CREATE TABLE ActiveCountForms (
        id $idType,
        warehouseId $textType,
        syncDate $textType,
        isCompleted $boolType
      )
    ''');

    // Tabla 2: Maestro de Artículos (Lo que se espera contar en esa bodega)
    await db.execute('''
      CREATE TABLE CountMasterItems (
        id $idType,
        physicalCountId $textType,
        financialArticleId $textType,
        articleName $textType,
        expectedQuantity $doubleType,
        FOREIGN KEY (physicalCountId) REFERENCES ActiveCountForms (id) ON DELETE CASCADE
      )
    ''');

    // Tabla 3: Registros de Conteo (Las lecturas que hace el usuario)
    await db.execute('''
      CREATE TABLE CountRecords (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,
        physicalCountId $textType,
        warehouseId $textType,
        financialArticleId $textType,
        counterUserId $textType,
        countNumber $integerType,
        barcode $textType,
        countedQuantity $doubleType,
        countDate $textType,
        syncDate $textNullType,
        status $textType,
        isSynced $textType,
        FOREIGN KEY (physicalCountId) REFERENCES ActiveCountForms (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.execute('DELETE FROM CountRecords');
      await txn.execute('DELETE FROM CountMasterItems');
      await txn.execute('DELETE FROM ActiveCountForms');
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // --- CRUD Operations ---

  /// Guarda una nueva cabecera de conteo físico y sus artículos maestros.
  Future<void> saveActiveCount(
    Map<String, dynamic> countFormMap,
    List<Map<String, dynamic>> masterItems,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'ActiveCountForms',
        countFormMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Usar un batch para insertar múltiples items rápidamente
      final batch = txn.batch();
      for (var item in masterItems) {
        batch.insert(
          'CountMasterItems',
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Guarda un registro de conteo (Código leido por la persona).
  Future<int> insertCountRecord(Map<String, dynamic> recordMap) async {
    final db = await instance.database;
    return await db.insert('CountRecords', recordMap);
  }

  /// Obtiene los registros guardados para un ID de conteo específico y número de conteo (1,2,3).
  Future<List<Map<String, dynamic>>> getRecordsForCount(
    String physicalCountId,
    int countNumber,
  ) async {
    final db = await instance.database;
    return await db.query(
      'CountRecords',
      where: 'physicalCountId = ? AND countNumber = ?',
      whereArgs: [physicalCountId, countNumber],
    );
  }

  /// Marca registros locales como sincronizados una vez han llegado al Backend.
  Future<void> markRecordsAsSynced(List<int> recordLocalIds) async {
    final db = await instance.database;
    final markers = List.filled(recordLocalIds.length, '?').join(',');
    await db.update(
      'CountRecords',
      {'isSynced': 'S'},
      where: 'localId IN ($markers)',
      whereArgs: recordLocalIds,
    );
  }
}
