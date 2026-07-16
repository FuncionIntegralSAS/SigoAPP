import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sigo_app/database/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    // Inicializar sqflite_common_ffi para pruebas de escritorio/consola
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dbHelper = DatabaseHelper.instance;
  });

  test('Should insert an ActiveCountForm and its MasterItems', () async {
    final countForm = {
      'id': 'COUNT-001',
      'warehouseId': 'WH-1',
      'syncDate': DateTime.now().toIso8601String(),
      'isCompleted': 0,
    };

    final masterItems = [
      {
        'id': 'MITEM-001',
        'physicalCountId': 'COUNT-001',
        'financialArticleId': 'ART-001',
        'descripcion': 'Laptop Dell',
        'expectedQuantity': 5.0,
      },
      {
        'id': 'MITEM-002',
        'physicalCountId': 'COUNT-001',
        'financialArticleId': 'ART-002',
        'descripcion': 'Mouse Logitech',
        'expectedQuantity': 10.0,
      },
    ];

    await dbHelper.saveActiveCount(countForm, masterItems);

    final db = await dbHelper.database;
    final forms = await db.query('ActiveCountForms');
    final items = await db.query('CountMasterItems');

    expect(forms.length, 1);
    expect(forms.first['id'], 'COUNT-001');
    expect(items.length, 2);
    expect(items.first['descripcion'], 'Laptop Dell');
  });

  test('Should insert and retrieve CountRecords', () async {
    // Para cumplir las llaves foráneas, insertamos el parent form primero (si aplicamos foreign keys estrictas, SQLite a veces no las forza por defecto a menos que 'PRAGMA foreign_keys = ON', pero está bien).
    final countForm = {
      'id': 'COUNT-002',
      'warehouseId': 'WH-1',
      'syncDate': DateTime.now().toIso8601String(),
      'isCompleted': 0,
    };
    await dbHelper.saveActiveCount(countForm, []);

    final recordMap = {
      'physicalCountId': 'COUNT-002',
      'warehouseId': 'WH-1',
      'financialArticleId': 'ART-00X',
      'counterUserId': 'USER-1',
      'countNumber': 1,
      'barcode': '123456789',
      'countedQuantity': 1.0,
      'countDate': DateTime.now().toIso8601String(),
      'status': 'CONTADO',
      'isSynced': 'N',
    };

    final id1 = await dbHelper.insertCountRecord(recordMap);
    expect(id1, isNotNull);

    // Obtener los registros
    final records = await dbHelper.getRecordsForCount('COUNT-002', 1);
    expect(records.length, 1);
    expect(records.first['barcode'], '123456789');
  });

  test('Should update multiple CountRecords as Sincronizado', () async {
    final countForm = {
      'id': 'COUNT-003',
      'warehouseId': 'WH-1',
      'syncDate': DateTime.now().toIso8601String(),
      'isCompleted': 0,
    };
    await dbHelper.saveActiveCount(countForm, []);

    final recordMap1 = {
      'physicalCountId': 'COUNT-003',
      'warehouseId': 'WH-1',
      'financialArticleId': 'ART-00X',
      'counterUserId': 'USER-1',
      'countNumber': 1,
      'barcode': '123456789',
      'countedQuantity': 1.0,
      'countDate': DateTime.now().toIso8601String(),
      'status': 'CONTADO',
      'isSynced': 'N',
    };

    final recordMap2 = Map<String, dynamic>.from(recordMap1);
    recordMap2['barcode'] = '987654321';

    final id1 = await dbHelper.insertCountRecord(recordMap1);
    final id2 = await dbHelper.insertCountRecord(recordMap2);

    await dbHelper.markRecordsAsSynced([id1, id2]);

    final db = await dbHelper.database;
    final syncedRecords = await db.query(
      'CountRecords',
      where: 'isSynced = ?',
      whereArgs: ['S'],
    );

    expect(syncedRecords.length, 2);
  });
}
