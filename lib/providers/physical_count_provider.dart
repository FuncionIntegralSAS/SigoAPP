import 'package:flutter/foundation.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/models/person_model.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:sigo_app/services/physical_count_service.dart';
import 'package:dio/dio.dart'; // Si usas dio para errores

enum PhysicalCountState { INITIAL, EN_PROCESO, CREADA, ERROR }

class PhysicalCountProvider extends ChangeNotifier {
  final PhysicalCountService _service;

  PhysicalCountState _state = PhysicalCountState.INITIAL;
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
    _setState(PhysicalCountState.EN_PROCESO);
    try {
      companies = await _service.getCompanies();
      _setState(PhysicalCountState.INITIAL);
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
      _loadWarehouses(company.id);
    }
  }

  Future<void> _loadWarehouses(String companyId) async {
    _setState(PhysicalCountState.EN_PROCESO);
    try {
      warehouses = await _service.getWarehouses(companyId);
      _setState(PhysicalCountState.INITIAL);
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
      _loadArticles(warehouse.id);
    }
  }

  Future<void> _loadArticles(String warehouseId) async {
    _setState(PhysicalCountState.EN_PROCESO);
    try {
      articles = await _service.getArticles(warehouseId);
      _setState(PhysicalCountState.INITIAL);
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

  Future<void> searchPersons(String query) async {
    if (query.isEmpty) {
      foundPersons = [];
      notifyListeners();
      return;
    }
    try {
      foundPersons = await _service.searchPersons(query);
      notifyListeners();
    } catch (e) {
      // Manejar error de forma silenciosa o mostrar mensaje
    }
  }

  void togglePersonSelection(PersonModel person) {
    final index = selectedPersons.indexWhere((p) => p.nationalId == person.nationalId);
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

    _setState(PhysicalCountState.EN_PROCESO);

    final request = PhysicalCountRequest(
      companyId: selectedCompany!.id,
      warehouseId: selectedWarehouse!.id,
      date: selectedDate,
      articleId: selectedArticle!.id,
      verifyExistence: verifyExistence,
      participants: selectedPersons,
    );

    try {
      await _service.createPhysicalCount(request);
      _setState(PhysicalCountState.CREADA);
    } catch (e) {
      String msg = 'Un error inesperado ha ocurrido.';
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          msg = 'Solicitud incorrecta (Error 400). Verifique los datos enviados.';
        } else if (e.response?.statusCode == 409) {
          msg = 'Conflicto (Error 409). Es posible que la bodega ya esté bloqueada.';
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
    if (selectedPersons.isEmpty) {
      _setError('Debe seleccionar al menos un participante.');
      return false;
    }
    return true;
  }

  void _setState(PhysicalCountState newState) {
    _state = newState;
    if (newState != PhysicalCountState.ERROR) {
      _errorMessage = null; // Limpiar errores pasados al cambiar estado
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = PhysicalCountState.ERROR;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = PhysicalCountState.INITIAL;
    notifyListeners();
  }

  void resetForm() {
    selectedCompany = null;
    selectedWarehouse = null;
    selectedArticle = null;
    selectedPersons.clear();
    verifyExistence = false;
    selectedDate = DateTime.now();
    _setState(PhysicalCountState.INITIAL);
  }
}
