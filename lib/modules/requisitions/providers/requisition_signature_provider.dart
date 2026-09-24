import 'package:flutter/material.dart';
import 'package:sigo_app/exceptions/requisition_business_exception.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/modules/requisitions/models/requisition_model.dart';
import 'package:sigo_app/modules/requisitions/repositories/requisition_repository.dart';
import 'package:sigo_app/utils/app_logger.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

/// Provider para la orquestación del flujo de Firma de Requisiciones y
/// Asentamiento de Salida definitiva en el ERP (DOCUINVE / MOVIINVE).
class RequisitionSignatureProvider extends ChangeNotifier {
  final RequisitionRepository _repository;

  RequisitionSignatureProvider(this._repository);

  // Nivel 1: Bandeja de Documentos Entregados ('en')
  List<RequisicionResumen> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Nivel 2: Caché de Detalle y Firmas por terna identificadora
  final Map<String, RequisicionDetalle> _documentDetails = {};
  final Map<String, bool> _loadingDetails = {};
  final Map<String, String?> _errorDetails = {};

  // Catálogo maestro de empresas
  List<CompanyModel> _companies = [];
  bool _isLoadingCompanies = false;
  String? _companiesErrorMessage;

  // Filtros operativos
  String? _selectedEmpresa;
  DateTime? _selectedDesde;

  // Estados de operaciones transaccionales
  bool _isSubmittingSignature = false;
  bool _isRegisteringExit = false;
  String? _actionError;
  String? _technicalDetails;
  int? _statusCode;

  // Getters
  List<RequisicionResumen> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CompanyModel> get companies => _companies;
  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get companiesErrorMessage => _companiesErrorMessage;

  String? get selectedEmpresa => _selectedEmpresa;
  DateTime? get selectedDesde => _selectedDesde;

  bool get isSubmittingSignature => _isSubmittingSignature;
  bool get isRegisteringExit => _isRegisteringExit;
  String? get actionError => _actionError;
  String? get technicalDetails => _technicalDetails;
  int? get statusCode => _statusCode;

  /// Retorna el [CompanyModel] correspondiente a la empresa seleccionada si existe.
  CompanyModel? get selectedCompanyModel {
    if (_selectedEmpresa == null) return null;
    for (final c in _companies) {
      if (c.codigo == _selectedEmpresa) return c;
    }
    return null;
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
      AppLogger.e('Error al cargar empresas en RequisitionSignatureProvider', e);
    } finally {
      _isLoadingCompanies = false;
      notifyListeners();
    }
  }

  /// Selecciona una empresa a partir del [CompanyModel].
  void selectCompany(CompanyModel? company) {
    setEmpresa(company?.codigo);
  }

  /// Actualiza la empresa seleccionada y recarga la bandeja.
  void setEmpresa(String? empresa) {
    _selectedEmpresa = (empresa != null && empresa.trim().isNotEmpty) ? empresa.trim() : null;
    loadDeliveredRequisitions();
  }

  /// Actualiza la fecha inicial ('desde') y recarga la bandeja.
  void setDesde(DateTime? fecha) {
    _selectedDesde = fecha;
    loadDeliveredRequisitions();
  }

  /// Limpia los filtros activos y vacía la bandeja.
  void clearFilters() {
    _selectedEmpresa = null;
    _selectedDesde = null;
    loadDeliveredRequisitions();
  }

  /// Formatea [DateTime] a cadena ISO YYYY-MM-DD sin hora.
  String? _formatIsoDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Carga la lista de requisiciones en estado entregado ('en').
  ///
  /// Regla de Protección de Red (Fail-Fast UI / Lazy Fetch):
  /// Si [_selectedDesde] es nulo, NO emite peticiones hacia el backend y
  /// deja la lista en estado inicial vacío sin error para prevenir el escaneo masivo sobre MOVIRESU.
  Future<void> loadDeliveredRequisitions({bool forceRefresh = false}) async {
    final effectiveDesde = _formatIsoDate(_selectedDesde);

    if (effectiveDesde == null || effectiveDesde.trim().isEmpty) {
      _documents = [];
      _documentDetails.clear();
      _loadingDetails.clear();
      _errorDetails.clear();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    if (forceRefresh) {
      _documentDetails.clear();
      _loadingDetails.clear();
      _errorDetails.clear();
    }
    notifyListeners();

    try {
      _documents = await _repository.getRequisitions(
        estado: 'en',
        empresa: _selectedEmpresa,
        desde: effectiveDesde,
      );
    } on RequisitionBusinessException catch (e) {
      _errorMessage = DialogUtils.extractFriendlyMessage(e.message);
    } catch (e) {
      _errorMessage = 'Error al cargar requisiciones entregadas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Consulta bajo demanda el detalle específico de un documento (Nivel 2)
  /// con sus firmas y líneas de artículos.
  Future<void> loadDetail(
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
      _errorDetails[key] = 'Error al consultar detalle: $e';
      AppLogger.w('Error al cargar detalle de requisición ($key): $e');
    } finally {
      _loadingDetails[key] = false;
      notifyListeners();
    }
  }

  /// Registra digitalmente la firma de salida ('SA') o recibo ('RE').
  Future<bool> submitSignature({
    required String empresa,
    required String tipoDocumento,
    required dynamic numero,
    required String tipo,
    required String persona,
    required String firmaBase64,
  }) async {
    _isSubmittingSignature = true;
    _actionError = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      final formattedFirma = firmaBase64.startsWith('data:image')
          ? firmaBase64
          : 'data:image/png;base64,$firmaBase64';

      final request = RequisicionFirmaRequest(
        tipo: tipo,
        persona: persona.trim(),
        firma: formattedFirma,
      );

      await _repository.signRequisition(
        empresa,
        tipoDocumento,
        numero.toString(),
        request,
      );

      // Recargamos el detalle para reflejar el nuevo estado de firmas en la tarjeta
      await loadDetail(empresa, tipoDocumento, numero, force: true);
      return true;
    } on RequisitionBusinessException catch (e) {
      _actionError = DialogUtils.extractFriendlyMessage(e.message);
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
      AppLogger.e('Error al registrar firma de requisición', e);
      return false;
    } catch (e) {
      _actionError = 'Error al registrar firma: $e';
      AppLogger.e('Error inesperado al registrar firma', e);
      return false;
    } finally {
      _isSubmittingSignature = false;
      notifyListeners();
    }
  }

  /// Asienta la salida definitiva en inventario ERP (DOCUINVE / MOVIINVE).
  /// PUNTO DE NO RETORNO.
  Future<bool> registerExit({
    required String empresa,
    required String tipoDocumento,
    required dynamic numero,
    RequisicionRegistrarRequest? request,
  }) async {
    _isRegisteringExit = true;
    _actionError = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      await _repository.registerExit(
        empresa,
        tipoDocumento,
        numero.toString(),
        request: request,
      );

      // Refrescamos la lista de requisiciones entregadas
      await loadDeliveredRequisitions(forceRefresh: true);
      return true;
    } on RequisitionBusinessException catch (e) {
      _actionError = DialogUtils.extractFriendlyMessage(e.message);
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
      AppLogger.e('Error al asentar salida ERP de requisición', e);
      return false;
    } catch (e) {
      _actionError = 'Error al asentar salida ERP: $e';
      AppLogger.e('Error inesperado al registrar salida ERP', e);
      return false;
    } finally {
      _isRegisteringExit = false;
      notifyListeners();
    }
  }

  /// Limpia los errores de la última acción transaccional.
  void clearActionError() {
    _actionError = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();
  }

  /// Limpia los errores de consulta general.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Restablece el estado completo del provider.
  void reset() {
    _documents = [];
    _documentDetails.clear();
    _loadingDetails.clear();
    _errorDetails.clear();
    _companies = [];
    _isLoadingCompanies = false;
    _companiesErrorMessage = null;
    _selectedEmpresa = null;
    _selectedDesde = null;
    _isLoading = false;
    _errorMessage = null;
    _isSubmittingSignature = false;
    _isRegisteringExit = false;
    _actionError = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();
  }
}
