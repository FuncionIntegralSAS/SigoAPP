/*
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SyncService {
  final Database _db;
  final String _apiUrl = "https://tu-scriptcase.com/api_sync/sync_endpoint.php";

  SyncService(this._db);

  Future<void> syncLocalToRemote() async {
    // 1. Obtener registros no sincronizados (sync_status = 0)
    List<Map<String, dynamic>> unsyncedRows = await _db.query(
      'mi_tabla',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    if (unsyncedRows.isEmpty) return;

    try {
      // 2. Enviar a Scriptcase (vía POST)
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": unsyncedRows}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // 3. Si el servidor confirma, actualizamos localmente a sincronizado (1)
        // Idealmente usamos el ID retornado por el servidor si es nuevo
        for (var row in unsyncedRows) {
          await _db.update(
            'mi_tabla',
            {'sync_status': 1},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        print("Sincronización exitosa");
      }
    } catch (e) {
      print("Error de red: $e");
    }
  }
}
*/