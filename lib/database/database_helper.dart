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
    if (kIsWeb) {
      throw UnsupportedError(
        'La base de datos SQLite no está configurada para Web aún.',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE CountMasterItems ADD COLUMN barcode TEXT');
    }
    if (oldVersion < 3) {
      // Migración V3: Eliminar la columna expectedQuantity (NOT NULL) que causaba el error 1299
      // En SQLite la forma más segura y compatible de eliminar una columna es recrear la tabla.
      await db.transaction((txn) async {
        await txn.execute(
          'ALTER TABLE CountMasterItems RENAME TO _CountMasterItems_old',
        );

        await txn.execute('''
          CREATE TABLE CountMasterItems (
            id TEXT PRIMARY KEY,
            physicalCountId TEXT NOT NULL,
            financialArticleId TEXT NOT NULL,
            articleName TEXT NOT NULL,
            barcode TEXT,
            FOREIGN KEY (physicalCountId) REFERENCES ActiveCountForms (id) ON DELETE CASCADE
          )
        ''');

        await txn.execute('''
          INSERT INTO CountMasterItems (id, physicalCountId, financialArticleId, articleName, barcode)
          SELECT id, physicalCountId, financialArticleId, articleName, barcode
          FROM _CountMasterItems_old
        ''');

        await txn.execute('DROP TABLE _CountMasterItems_old');
      });
    }

    if (oldVersion < 4) {
      // Migración V4: Renombrar articleName a descripcion
      // Ocurre porque se hizo el cambio en el código fuente, pero la BD local seguía esperando articleName
      try {
        await db.execute(
          'ALTER TABLE CountMasterItems RENAME COLUMN articleName TO descripcion',
        );
      } catch (e) {
        // En caso de que se haya modificado la v3 manualmente y la tabla ya tuviera descripion pero el esquema
        // estuviera corrupto, evitamos crasheo de la migración si la columna ya existía.
        if (kDebugMode) {
          debugPrint(
            'Nota: La columna descripcion podría ya existir o renombrarse. \$e',
          );
        }
      }
    }
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
        descripcion $textType,
        barcode $textNullType,
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
