import 'package:flutter/material.dart';
import '../exceptions/requisition_business_exception.dart';
import '../models/company_model.dart';
import '../models/requisition_model.dart';
import '../repositories/requisition_repository.dart';
import '../utils/app_logger.dart';

/// Orquestador de estado para el flujo de Aprobación y Entrega de Requisiciones.
class RequisitionApprovalProvider extends ChangeNotifier {
  final RequisitionRepository _repository;

  RequisitionApprovalProvider(this._repository);

  // Nivel 1: Bandeja de Documentos de Requisición
  List<RequisicionResumen> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _processErrorMessage;
  String _currentStatus = 'in';

  // Nivel 2: Caché de Detalle y Movimientos de Requisición por terna
  final Map<String, RequisicionDetalle> _documentDetails = {};
  final Map<String, bool> _loadingDetails = {};
  final Map<String, String?> _errorDetails = {};

  // Catálogo maestro de empresas
  List<CompanyModel> _companies = [];
  bool _isLoadingCompanies = false;
  String? _companiesErrorMessage;

  // Filtros operativos por pestaña (Aprobación: 'in', Entrega: 'ap')
  String? _empresaAprobacion;
  DateTime? _desdeAprobacion;

  String? _empresaEntrega;
  DateTime? _desdeEntrega;

  // Estado para las selecciones en bloque: { ID : Cantidad }
  final Map<String, int> _selectedItems = {};

  List<RequisicionResumen> get documents => _documents;

  /// Compatibilidad regresiva: expone líneas de los detalles cargados en memoria
  List<RequisitionModel> get pendingRequisitions {
    final lines = <RequisitionModel>[];
    for (final detail in _documentDetails.values) {
      for (final linea in detail.lineas) {
        lines.add(RequisitionModel.fromDetalleLinea(detalle: detail, linea: linea));
      }
    }
    return lines;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get processErrorMessage => _processErrorMessage;
  String get currentStatus => _currentStatus;
  int get selectedCount => _selectedItems.length;

  /// Retorna la cantidad de documentos únicos que tienen movimientos seleccionados o modificados
  int get selectedDocumentsCount {
    final docKeys = <String>{};
    for (final key in _selectedItems.keys) {
      final parts = key.split('_');
      if (parts.length >= 3) {
        docKeys.add('${parts[0]}_${parts[1]}_${parts[2]}');
      }
    }
    return docKeys.length;
  }

  Map<String, int> get selectedItems => _selectedItems;

  List<CompanyModel> get companies => _companies;
  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get companiesErrorMessage => _companiesErrorMessage;

  // Getters contextuales según la pestaña activa
  String? get selectedEmpresa => _currentStatus == 'in' ? _empresaAprobacion : _empresaEntrega;
  DateTime? get selectedDesde => _currentStatus == 'in' ? _desdeAprobacion : _desdeEntrega;

  String? get empresaAprobacion => _empresaAprobacion;
  DateTime? get desdeAprobacion => _desdeAprobacion;
  String? get empresaEntrega => _empresaEntrega;
  DateTime? get desdeEntrega => _desdeEntrega;

  String? getEmpresaForStatus(String status) => status == 'in' ? _empresaAprobacion : _empresaEntrega;
  DateTime? getDesdeForStatus(String status) => status == 'in' ? _desdeAprobacion : _desdeEntrega;

  /// Retorna el [CompanyModel] correspondiente a la empresa seleccionada en la pestaña indicada.
  CompanyModel? getCompanyModelForStatus(String status) {
    final code = getEmpresaForStatus(status);
    if (code == null) return null;
    for (final c in _companies) {
      if (c.codigo == code) return c;
    }
    return null;
  }

  /// Selecciona una empresa a partir del [CompanyModel], delegando a [setEmpresa].
  void selectCompany(CompanyModel? company, {required String status}) {
    setEmpresa(company?.codigo, status: status);
  }

  /// Carga el catálogo maestro de empresas (GET /api/v1/empresas/getAll).
  Future<void> loadCompanies({bool forceRefresh = false}) async {
    if (_companies.isNotEmpty && !forceRefresh) return;
    _isLoadingCompanies = true;
    _companiesErrorMessage = null;
    notifyListeners();

    try {
      _companies = await _repository.getCompanies();
    } catch (e) {
      _companiesErrorMessage = 'Error al cargar empresas: $e';
      AppLogger.e('Error al cargar empresas en RequisitionApprovalProvider', e);
    } finally {
      _isLoadingCompanies = false;
      notifyListeners();
    }
  }

  /// Actualiza la empresa seleccionada para la pestaña indicada ('in' o 'ap').
  /// Si la otra pestaña se encuentra vacía, se autorrellena con el valor sugerido.
  void setEmpresa(String? empresa, {required String status}) {
    final sanitized = (empresa != null && empresa.trim().isNotEmpty) ? empresa.trim() : null;
    if (status == 'in') {
      _empresaAprobacion = sanitized;
      if (sanitized != null && (_empresaEntrega == null || _empresaEntrega!.isEmpty)) {
        _empresaEntrega = sanitized;
      }
    } else {
      _empresaEntrega = sanitized;
      if (sanitized != null && (_empresaAprobacion == null || _empresaAprobacion!.isEmpty)) {
        _empresaAprobacion = sanitized;
      }
    }
    loadRequisitions(status);
  }

  /// Actualiza la fecha inicial ('desde') para la pestaña indicada ('in' o 'ap').
  /// Si la otra pestaña se encuentra vacía, se autorrellena con el valor sugerido.
  void setDesde(DateTime? fecha, {required String status}) {
    if (status == 'in') {
      _desdeAprobacion = fecha;
      if (fecha != null && _desdeEntrega == null) {
        _desdeEntrega = fecha;
      }
    } else {
      _desdeEntrega = fecha;
      if (fecha != null && _desdeAprobacion == null) {
        _desdeAprobacion = fecha;
      }
    }
    loadRequisitions(status);
  }

  /// Limpia los filtros activos de la pestaña especificada y recarga sus datos.
  void clearFilters({required String status}) {
    if (status == 'in') {
      _empresaAprobacion = null;
      _desdeAprobacion = null;
    } else {
      _empresaEntrega = null;
      _desdeEntrega = null;
    }
    loadRequisitions(status);
  }

  /// Convierte [DateTime] a cadena estricta ISO `YYYY-MM-DD` sin horas.
  String? _formatIsoDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _docKey(String empresa, String tipoDoc, dynamic num) => '$empresa|$tipoDoc|$num';

  /// Obtiene el detalle cargado en memoria para una terna específica si existe.
  RequisicionDetalle? getDetail(String empresa, String tipoDoc, dynamic numero) =>
      _documentDetails[_docKey(empresa, tipoDoc, numero)];

  /// Indica si el detalle de la terna se encuentra actualmente en proceso de carga.
  bool isDetailLoading(String empresa, String tipoDoc, dynamic numero) =>
      _loadingDetails[_docKey(empresa, tipoDoc, numero)] == true;

  /// Retorna el error producido al intentar cargar el detalle de la terna, si existe.
  String? getDetailError(String empresa, String tipoDoc, dynamic numero) =>
      _errorDetails[_docKey(empresa, tipoDoc, numero)];

  /// Consulta bajo demanda el detalle específico de un documento (Nivel 2)
  /// invocando GET /api/v1/requisiciones/{empresa}/{tipoDocumento}/{numero}.
  Future<void> fetchDocumentDetail(
    String empresa,
    String tipoDocumento,
    dynamic numero, {
    bool force = false,
  }) async {
    final key = _docKey(empresa, tipoDocumento, numero);
    if (!force && (_documentDetails.containsKey(key) || _loadingDetails[key] == true)) {
      return;
    }

    _loadingDetails[key] = true;
    _errorDetails[key] = null;
    notifyListeners();

    try {
      final detail = await _repository.getRequisitionDetail(
        empresa,
        tipoDocumento,
        numero.toString(),
      );
      _documentDetails[key] = detail;
    } catch (e) {
      _errorDetails[key] = 'Error al consultar movimientos: $e';
      AppLogger.w('Error al cargar detalle de requisición ($key): $e');
    } finally {
      _loadingDetails[key] = false;
      notifyListeners();
    }
  }

  /// Carga la lista de documentos de requisición (Nivel 1) según el estado ('in' o 'ap').
  ///
  /// Regla de protección de red (Fail-Fast UI / Lazy Fetch):
  /// Si [desde] (o la fecha activa de la pestaña) es nula o vacía, NO emite peticiones
  /// hacia el backend y deja la lista de documentos en estado inicial vacío sin error.
  Future<void> loadRequisitions(
    String status, {
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  }) async {
    _currentStatus = status;

    final effectiveEmpresa = empresa ?? getEmpresaForStatus(status);
    final effectiveDesde = desde ?? _formatIsoDate(getDesdeForStatus(status));

    // Bloqueo de consulta sin fecha: prevenir escaneo masivo sobre MOVIRESU
    if (effectiveDesde == null || effectiveDesde.trim().isEmpty) {
      _documents = [];
      _documentDetails.clear();
      _loadingDetails.clear();
      _errorDetails.clear();
      _selectedItems.clear();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _selectedItems.clear();
    _documentDetails.clear();
    _loadingDetails.clear();
    _errorDetails.clear();
    notifyListeners();

    try {
      _documents = await _repository.getRequisitions(
        estado: status,
        empresa: effectiveEmpresa,
        tipoDocumento: tipoDocumento,
        bodega: bodega,
        desde: effectiveDesde,
      );
    } on RequisitionBusinessException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error al cargar requisiciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega o quita ítems de la selección actual para procesamiento en lote
  void toggleSelection(String id, bool isSelected, int quantity) {
    if (isSelected && quantity > 0) {
      _selectedItems[id] = quantity;
    } else {
      _selectedItems.remove(id);
    }
    notifyListeners();
  }

  /// Retorna si un movimiento específico está seleccionado
  bool isItemSelected(String id) => _selectedItems.containsKey(id);

  /// Retorna la cantidad seleccionada para un movimiento
  int getSelectedItemQuantity(String id) => _selectedItems[id] ?? 0;

  /// Selecciona todas las líneas autorizables de un documento con su cantidad máxima
  void selectAllForDocument(RequisicionDetalle detail, String currentTabStatus) {
    for (final linea in detail.lineas) {
      final int maxAllowed = currentTabStatus == 'in'
          ? linea.solicitada.round()
          : linea.aprobada.round();
      if (maxAllowed > 0) {
        final id =
            '${detail.empresa}_${detail.tipoDocumento}_${detail.numero}_${linea.bodega}_${linea.articulo}_${linea.secuencia}';
        _selectedItems[id] = maxAllowed;
      }
    }
    notifyListeners();
  }

  /// Deselecciona todas las líneas de un documento
  void deselectAllForDocument(RequisicionDetalle detail) {
    deselectDocumentByTerna(detail.empresa, detail.tipoDocumento, detail.numero);
  }

  /// Deselecciona todas las líneas de un documento a partir de su terna identificadora
  void deselectDocumentByTerna(String empresa, String tipoDocumento, dynamic numero) {
    final prefix = '${empresa}_${tipoDocumento}_${numero}_';
    _selectedItems.removeWhere((key, _) => key.startsWith(prefix));
    notifyListeners();
  }

  /// Retorna si al menos un movimiento del documento está seleccionado o modificado
  bool isDocumentModified(String empresa, String tipoDocumento, dynamic numero) {
    final prefix = '${empresa}_${tipoDocumento}_${numero}_';
    return _selectedItems.keys.any((key) => key.startsWith(prefix));
  }

  /// Retorna la cantidad de líneas seleccionadas para un documento específico
  int countSelectedLinesForDocument(String empresa, String tipoDocumento, dynamic numero) {
    final prefix = '${empresa}_${tipoDocumento}_${numero}_';
    return _selectedItems.keys.where((key) => key.startsWith(prefix)).length;
  }

  /// Ejecuta el procesamiento masivo (Aprobar o Entregar) según la pestaña activa
  Future<bool> processBatchSelection(String currentTabStatus) async {
    if (_selectedItems.isEmpty) return false;

    _isLoading = true;
    _processErrorMessage = null;
    notifyListeners();

    try {
      final String targetStatus = currentTabStatus == 'in' ? 'ap' : 'en';

      // Reconstruimos los modelos detallados a partir de los documentos consultados en memoria
      final allLoadedLines = <RequisitionModel>[];
      for (final detail in _documentDetails.values) {
        for (final linea in detail.lineas) {
          allLoadedLines.add(RequisitionModel.fromDetalleLinea(detalle: detail, linea: linea));
        }
      }

      final success = await _repository.processBatch(
        _selectedItems,
        targetStatus,
        requisitions: allLoadedLines,
      );

      if (success) {
        _selectedItems.clear();
        await loadRequisitions(currentTabStatus);
        return true;
      }
      return false;
    } on RequisitionBusinessException catch (e) {
      _processErrorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _processErrorMessage = 'Error procesando el lote: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia el mensaje de error de consulta activo
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error de procesamiento de lote activo
  void clearProcessErrorMessage() {
    _processErrorMessage = null;
    notifyListeners();
  }

  /// Limpia los datos de requisiciones y filtros en memoria al cerrar sesión
  void reset() {
    _documents = [];
    _documentDetails.clear();
    _loadingDetails.clear();
    _errorDetails.clear();
    _isLoading = false;
    _errorMessage = null;
    _processErrorMessage = null;
    _currentStatus = 'in';
    _selectedItems.clear();
    _companies = [];
    _isLoadingCompanies = false;
    _companiesErrorMessage = null;
    _empresaAprobacion = null;
    _desdeAprobacion = null;
    _empresaEntrega = null;
    _desdeEntrega = null;
    notifyListeners();
  }
}