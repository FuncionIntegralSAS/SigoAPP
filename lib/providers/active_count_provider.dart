import 'package:flutter/foundation.dart';
import 'package:sigo_app/database/database_helper.dart';
import 'package:sigo_app/models/count_record_model.dart';
import 'package:sigo_app/models/physical_count_model.dart';

enum ActiveCountState { loading, idle, error, syncing }

class ActiveCountProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  ActiveCountState _state = ActiveCountState.idle;
  ActiveCountState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _activeCountId;
  String? get activeCountId => _activeCountId;

  String? _warehouseId;
  String? get warehouseId => _warehouseId;

  // Cédula del usuario actual que maneja el dispositivo
  String? _currentUserId;

  // 1, 2, or 3
  int _currentIteration = 1;
  int get currentIteration => _currentIteration;

  Map<String, Map<String, dynamic>> _masterItems = {};
  Map<String, Map<String, dynamic>> get masterItems => _masterItems;

  // Records counted in the current iteration: { 'financialArticleId': totalCounted }
  Map<String, double> _currentIterationRecords = {};
  Map<String, double> get currentIterationRecords => _currentIterationRecords;

  int get totalArticlesCount => _masterItems.length;
  int get countedArticlesCount => _currentIterationRecords.length;

  bool get hasActiveCount => _activeCountId != null;

  // For storing historical counts to compare (1 vs 2)
  Map<String, double> _count1Records = {};
  Map<String, double> _count2Records = {};

  // To fast check if an article needs a 3rd count
  Set<String> _articlesNeedingCount3 = {};

  void _setState(ActiveCountState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Inicializa el conteo desde la base de datos local SQLite si existe.
  Future<void> loadLocalActiveCount(String userId) async {
    _currentUserId = userId;
    _setState(ActiveCountState.loading);
    try {
      final db = await _dbHelper.database;

      // 1. Verificar si hay un formulario activo incompleto
      final forms = await db.query(
        'ActiveCountForms',
        where: 'isCompleted = ?',
        whereArgs: [0],
      );
      if (forms.isEmpty) {
        _activeCountId = null;
        _setState(ActiveCountState.idle);
        return;
      }

      final form = forms.first;
      _activeCountId = form['id'] as String;
      _warehouseId = form['warehouseId'] as String;

      final items = await db.query(
        'CountMasterItems',
        where: 'physicalCountId = ?',
        whereArgs: [_activeCountId],
      );

      if (items.isEmpty) {
        await db.delete(
          'ActiveCountForms',
          where: 'id = ?',
          whereArgs: [_activeCountId],
        );
        _activeCountId = null;
        _setState(ActiveCountState.idle);
        return;
      }

      _masterItems.clear();
      for (var item in items) {
        _masterItems[item['financialArticleId'] as String] = {
          'descripcion': item['descripcion'],
          'barcode': item['barcode'],
        };
      }

      // 3. Evaluar en qué iteración estamos y cargar el historial local
      await _evaluateCurrentIteration();

      _setState(ActiveCountState.idle);
    } catch (e) {
      _errorMessage = 'Error al cargar el conteo local: $e';
      _setState(ActiveCountState.error);
    }
  }

  Future<void> _evaluateCurrentIteration() async {
    if (_activeCountId == null) return;

    final recordsC1 = await _dbHelper.getRecordsForCount(_activeCountId!, 1);
    final recordsC2 = await _dbHelper.getRecordsForCount(_activeCountId!, 2);
    final recordsC3 = await _dbHelper.getRecordsForCount(_activeCountId!, 3);

    _count1Records = _aggregateRecords(recordsC1);
    _count2Records = _aggregateRecords(recordsC2);

    // Reglas de Negocio del Flujo:
    // Si no hay nada o solo C1 en curso, estamos en Iteración 1 (Pero el control de cierre de la iteración lo determina una bandera o la existencia de registros avanzados).
    // Asumiremos que el usuario pulsa un botón "Finalizar Conteo 1", y nosotros guardamos un registro marcador o inferimos.
    // Para simplificar: Si existe al menos un registro de C2, significa que C1 fue cerrado.
    // Si existe C3, significa que C2 fue cerrado.

    // NOTA: Para este prototipo, usaremos una lógica simple deducida.
    // Lo ideal es tener un estado de iteración en la tabla ActiveCountForms.

    // Calculamos discrepancias si existen ambos conteos
    _articlesNeedingCount3.clear();
    for (var articleId in _masterItems.keys) {
      final c1 = _count1Records[articleId] ?? 0.0;
      final c2 = _count2Records[articleId] ?? 0.0;
      // Si ya hay datos en C2 y difiere de C1, requiere C3
      if (recordsC2.isNotEmpty && c1 != c2) {
        _articlesNeedingCount3.add(articleId);
      }
    }

    if (recordsC3.isNotEmpty) {
      _currentIteration = 3;
      _currentIterationRecords = _aggregateRecords(recordsC3);
    } else if (recordsC2.isNotEmpty) {
      _currentIteration = 2;
      _currentIterationRecords = _count2Records;
    } else {
      _currentIteration = 1;
      _currentIterationRecords = _count1Records;
    }
  }

  Map<String, double> _aggregateRecords(List<Map<String, dynamic>> rawRecords) {
    Map<String, double> map = {};
    for (var r in rawRecords) {
      final id = r['financialArticleId'] as String;
      final qty = (r['countedQuantity'] as num).toDouble();
      map[id] = (map[id] ?? 0.0) + qty;
    }
    return map;
  }

  /// Registra el escaneo o ingreso manual de un artículo.
  Future<void> recordCount(String barcode, double quantity) async {
    if (_activeCountId == null ||
        _warehouseId == null ||
        _currentUserId == null)
      return;

    // Buscar si el código de barras coincide con un artículo financiero maestro
    String? financialArticleId;
    for (var entry in _masterItems.entries) {
      if (entry.value['barcode'] == barcode || entry.key == barcode) {
        financialArticleId = entry.key;
        break;
      }
    }

    if (financialArticleId == null) {
      _errorMessage =
          'El artículo con código $barcode no está asignado a este conteo.';
      notifyListeners();
      return;
    }

    // Validar si estamos en la iteración 3 y si este artículo realmente requiere conteo 3
    if (_currentIteration == 3 &&
        !_articlesNeedingCount3.contains(financialArticleId)) {
      _errorMessage =
          'Este artículo no presenta discrepancias, no requiere un 3er conteo.';
      notifyListeners();
      return;
    }

    final newRecord = CountRecordModel(
      physicalCountId: _activeCountId!,
      warehouseId: _warehouseId!,
      financialArticleId: financialArticleId,
      counterUserId: _currentUserId!,
      countNumber: _currentIteration,
      barcode: barcode,
      countedQuantity: quantity,
      countDate: DateTime.now(),
      status: 'CONTADO',
    );

    await _dbHelper.insertCountRecord(newRecord.toMap());

    // Actualizar el estado en memoria para la UI
    _currentIterationRecords[financialArticleId] =
        (_currentIterationRecords[financialArticleId] ?? 0.0) + quantity;

    notifyListeners();
  }

  /// Acaba la iteración actual y avanza a la siguiente (o finaliza).
  Future<void> completeCurrentIteration() async {
    if (_currentIteration == 1) {
      _currentIteration = 2;
      _currentIterationRecords.clear();
      // Guardar C1 memory
      _count1Records = Map.from(_currentIterationRecords);
    } else if (_currentIteration == 2) {
      // Calcular discrepancias
      _articlesNeedingCount3.clear();
      for (var articleId in _masterItems.keys) {
        final c1 = _count1Records[articleId] ?? 0.0;
        final c2 =
            _currentIterationRecords[articleId] ??
            0.0; // Lo que acabo de contar
        if (c1 != c2) {
          _articlesNeedingCount3.add(articleId);
        }
      }

      _count2Records = Map.from(_currentIterationRecords);
      _currentIterationRecords.clear();

      if (_articlesNeedingCount3.isEmpty) {
        // No hay diferencias, podemos cerrar el formulario completo
        await _finishEntireCount();
      } else {
        _currentIteration = 3;
      }
    } else if (_currentIteration == 3) {
      await _finishEntireCount();
    }
    notifyListeners();
  }

  Future<void> _finishEntireCount() async {
    // Marcar en SQlite como completado
    final db = await _dbHelper.database;
    await db.update(
      'ActiveCountForms',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [_activeCountId],
    );
    _activeCountId = null; // Quita de la UI activa

    // Aquí podríamos invocar syncWithBackend() para subir todos los registros.
    syncWithBackend();
  }

  /// Sincroniza los registros 'N' al backend.
  Future<void> syncWithBackend() async {
    _setState(ActiveCountState.syncing);
    try {
      final db = await _dbHelper.database;
      final pendingRecords = await db.query(
        'CountRecords',
        where: 'isSynced = ?',
        whereArgs: ['N'],
      );

      if (pendingRecords.isEmpty) {
        _setState(ActiveCountState.idle);
        return;
      }

      // 1. Llamar a la API real: await networkClient.post('/api/v1/conteo-fisico/registrarBatch', data: listaJson);
      // Simulación de latencia:
      await Future.delayed(const Duration(seconds: 2));

      // 2. Si es exitoso, marcarlos localmente como Sincronizados
      final List<int> idsToMark = pendingRecords
          .map((r) => r['localId'] as int)
          .toList();
      await _dbHelper.markRecordsAsSynced(idsToMark);

      _setState(ActiveCountState.idle);
    } catch (e) {
      _errorMessage = 'Error de conexión al sincronizar: $e';
      _setState(ActiveCountState.error);
    }
  }

  /// Descarga y guarda localmente la lista de pendientes (asociándola al usuario)
  Future<void> guardarPendientesLocales(
    List<PendienteArticuloResponse> pendientes,
  ) async {
    if (pendientes.isEmpty) return;
    _setState(ActiveCountState.syncing);
    try {
      // Tomamos el primer elemento como referencia para la cabecera (Form)
      // Asumimos que los pendientes vienen agrupados por un mismo conteo para el usuario.
      final ref = pendientes.first;
      final formId = ref.numeroConteo;

      final Map<String, dynamic> countFormMap = {
        'id': formId,
        'warehouseId': ref.idBodega ?? 'GENERIC_WH',
        'syncDate': DateTime.now().toIso8601String(),
        'isCompleted': 0,
      };

      final List<Map<String, dynamic>> masterItems = pendientes.map((p) {
        return {
          'id': p.idArticulo,
          'physicalCountId': formId,
          'financialArticleId': p.idArticulo.toString(),
          'descripcion': p.descripcion ?? 'Artículo ${p.idArticulo}',
          'barcode': p.codigoQr ?? p.idArticulo.toString(),
        };
      }).toList();

      await _dbHelper.saveActiveCount(countFormMap, masterItems);

      _setState(ActiveCountState.idle);

      // Recargar automáticamente el conteo local para el usuario de estos pendientes
      if (ref.idUsuario != null) {
        await loadLocalActiveCount(ref.idUsuario.toString());
      }
    } catch (e) {
      _errorMessage = 'Error al guardar pendientes localmente: $e';
      _setState(ActiveCountState.error);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
