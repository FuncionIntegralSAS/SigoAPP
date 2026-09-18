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

  List<RequisitionModel> _pendingRequisitions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentStatus = 'in';

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

  List<RequisitionModel> get pendingRequisitions => _pendingRequisitions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentStatus => _currentStatus;
  int get selectedCount => _selectedItems.length;

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

    AppLogger.i('[RequisitionApprovalProvider] Solicitando catálogo de empresas...');
    try {
      _companies = await _repository.getCompanies();
      AppLogger.i('[RequisitionApprovalProvider] Catálogo de empresas cargado: ${_companies.length} empresas encontradas.');
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

  /// Carga la lista de requisiciones según el estado correspondiente ('in', 'ap', etc.).
  /// Si no se especifican [empresa] o [desde], toma los filtros guardados para la pestaña activa.
  Future<void> loadRequisitions(
    String status, {
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  }) async {
    _currentStatus = status;
    _isLoading = true;
    _errorMessage = null;
    _selectedItems.clear();
    notifyListeners();

    final effectiveEmpresa = empresa ?? getEmpresaForStatus(status);
    final effectiveDesde = desde ?? _formatIsoDate(getDesdeForStatus(status));

    AppLogger.i('----------------------------------------------------------------');
    AppLogger.i('[RequisitionApprovalProvider] Solicitando requisiciones desde la UI:');
    AppLogger.i('  Pestaña/Estado : ${status == 'in' ? 'Aprobación (in)' : 'Entrega (ap)'}');
    AppLogger.i('  Filtro Empresa : ${effectiveEmpresa ?? "(Ninguna / Todas)"}');
    AppLogger.i('  Filtro Desde   : ${effectiveDesde ?? "(Sin filtro de fecha)"}');
    AppLogger.i('----------------------------------------------------------------');

    try {
      _pendingRequisitions = await _repository.getRequisitionsByStatus(
        status,
        empresa: effectiveEmpresa,
        tipoDocumento: tipoDocumento,
        bodega: bodega,
        desde: effectiveDesde,
      );
      AppLogger.i('[RequisitionApprovalProvider] Requisiciones cargadas exitosamente: ${_pendingRequisitions.length} líneas.');
    } on RequisitionBusinessException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error al cargar requisiciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega o quita ítems de la selección actual
  void toggleSelection(String id, bool isSelected, int quantity) {
    if (isSelected && quantity > 0) {
      _selectedItems[id] = quantity;
    } else {
      _selectedItems.remove(id);
    }
    notifyListeners();
  }

  /// Ejecuta el procesamiento masivo (Aprobar o Entregar) según la pestaña activa
  Future<bool> processBatchSelection(String currentTabStatus) async {
    if (_selectedItems.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String targetStatus = currentTabStatus == 'in' ? 'ap' : 'en';

      final success = await _repository.processBatch(
        _selectedItems,
        targetStatus,
        requisitions: _pendingRequisitions,
      );

      if (success) {
        _selectedItems.clear();
        await loadRequisitions(currentTabStatus);
        return true;
      }
      return false;
    } on RequisitionBusinessException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error procesando el lote: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia el mensaje de error activo
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia los datos de requisiciones y filtros en memoria al cerrar sesión
  void reset() {
    _pendingRequisitions = [];
    _isLoading = false;
    _errorMessage = null;
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