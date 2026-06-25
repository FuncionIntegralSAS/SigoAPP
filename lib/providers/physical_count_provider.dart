import 'package:flutter/foundation.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/models/person_model.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:sigo_app/services/physical_count_service.dart';
import 'package:dio/dio.dart';

enum PhysicalCountState { initial, enProceso, creada, error }

class PhysicalCountProvider extends ChangeNotifier {
  final PhysicalCountService _service;

  PhysicalCountState _state = PhysicalCountState.initial;
  PhysicalCountState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Listas de datos para selectores
  List<CompanyModel> companies = [];
  List<WarehouseModel> warehouses = [];
  List<ArticleModel> articles = [];
  List<PersonModel> foundPersons = [];

  // Múltiples personas seleccionadas
  List<PersonModel> selectedPersons = [];

  // Valores seleccionados
  CompanyModel? selectedCompany;
  WarehouseModel? selectedWarehouse;
  DateTime selectedDate = DateTime.now();
  ArticleModel? selectedArticle;
  bool verifyExistence = false;

  PhysicalCountProvider(this._service) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _setState(PhysicalCountState.enProceso);
    try {
      companies = await _service.getCompanies();
      _setState(PhysicalCountState.initial);
    } catch (e) {
      _setError('Error al cargar datos iniciales. $e');
    }
  }

  void selectCompany(CompanyModel? company) {
    selectedCompany = company;
    selectedWarehouse = null;
    selectedArticle = null;
    warehouses.clear();
    articles.clear();
    notifyListeners();

    if (company != null) {
      _loadWarehouses(company.codigo);
    }
  }

  Future<void> _loadWarehouses(String companyId) async {
    _setState(PhysicalCountState.enProceso);
    try {
      warehouses = await _service.getWarehouses(companyId);
      _setState(PhysicalCountState.initial);
    } catch (e) {
      _setError('Error al cargar bodegas.');
    }
  }

  void selectWarehouse(WarehouseModel? warehouse) {
    selectedWarehouse = warehouse;
    selectedArticle = null;
    articles.clear();
    notifyListeners();

    if (warehouse != null) {
      _loadArticles(warehouse.bodeCodi);
    }
  }

  Future<void> _loadArticles(String warehouseId) async {
    _setState(PhysicalCountState.enProceso);
    try {
      articles = await _service.getArticles(warehouseId);
      _setState(PhysicalCountState.initial);
    } catch (e) {
      _setError('Error al cargar artículos.');
    }
  }

  void updateDate(DateTime newDate) {
    selectedDate = newDate;
    notifyListeners();
  }

  void selectArticle(ArticleModel? article) {
    selectedArticle = article;
    notifyListeners();
  }

  void setVerifyExistence(bool value) {
    verifyExistence = value;
    notifyListeners();
  }

  Future<void> searchPersons({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    // Validar en el cliente antes de enviar al servicio para no desperdiciar recursos
    final hasNombre = nombre != null && nombre.trim().isNotEmpty;
    final hasApellido = apellido != null && apellido.trim().isNotEmpty;
    final hasCedula = cedula != null && cedula.trim().isNotEmpty;

    if (!hasNombre && !hasApellido && !hasCedula) {
      foundPersons = [];
      _setError(
        'Por favor llena al menos un campo de búsqueda (Nombre, Apellido o Cédula).',
      );
      return;
    }

    // Limpiar mensaje error de búsqueda al intentar buscar
    if (state == PhysicalCountState.error) {
      clearError();
    }

    try {
      foundPersons = await _service.searchPersons(
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
      );
      notifyListeners();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        _setError(
          e.response?.data['message'] ?? 'Falta parámetro de búsqueda.',
        );
      } else {
        _setError('Error en la búsqueda de personal.');
      }
    }
  }

  void togglePersonSelection(PersonModel person) {
    final index = selectedPersons.indexWhere(
      (p) => p.nationalId == person.nationalId,
    );
    if (index >= 0) {
      selectedPersons.removeAt(index);
    } else {
      selectedPersons.add(person);
    }
    notifyListeners();
  }

  void removePerson(PersonModel person) {
    selectedPersons.removeWhere((p) => p.nationalId == person.nationalId);
    notifyListeners();
  }

  // --- LÓGICA DE NEGOCIO ---
  Future<void> submitPhysicalCount() async {
    if (!_validateFields()) return;

    _setState(PhysicalCountState.enProceso);

    final request = PhysicalCountRequest(
      companyId: selectedCompany!.codigo,
      warehouseId: selectedWarehouse!.bodeCodi,
      date: selectedDate,
      articleId: selectedArticle!.id,
      verifyExistence: verifyExistence,
    );

    try {
      await _service.createPhysicalCount(request);
      _setState(PhysicalCountState.creada);
    } catch (e) {
      String msg = 'Un error inesperado ha ocurrido.';
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          msg =
              'Solicitud incorrecta (Error 400). Verifique los datos enviados.';
        } else if (e.response?.statusCode == 409) {
          msg =
              'Conflicto (Error 409). Es posible que la bodega ya esté bloqueada.';
        } else if (e.response?.statusCode == 500) {
          msg = 'Error del servidor (Error 500). Inténtalo más tarde.';
        } else {
          msg = 'Error de red: ${e.message}';
        }
      }
      _setError(msg);
    }
  }

  bool _validateFields() {
    if (selectedCompany == null) {
      _setError('Debe seleccionar una Empresa.');
      return false;
    }
    if (selectedWarehouse == null) {
      _setError('Debe seleccionar una Bodega.');
      return false;
    }
    if (selectedArticle == null) {
      _setError('Debe seleccionar un Artículo o la opción "Todos".');
      return false;
    }
    // Personas participantes no son obligatorias en esta fase ya que se extraerán a otra vista.
    return true;
  }

  void _setState(PhysicalCountState newState) {
    _state = newState;
    if (newState != PhysicalCountState.error) {
      _errorMessage = null; // Limpiar errores pasados al cambiar estado
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = PhysicalCountState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = PhysicalCountState.initial;
    notifyListeners();
  }

  void resetForm() {
    selectedCompany = null;
    selectedWarehouse = null;
    selectedArticle = null;
    selectedPersons.clear();
    verifyExistence = false;
    selectedDate = DateTime.now();
    _setState(PhysicalCountState.initial);
  }
}
