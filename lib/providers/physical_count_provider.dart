import 'package:flutter/foundation.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/personal_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:sigo_app/repositories/physical_count_repository.dart';
import 'package:dio/dio.dart';

enum PhysicalCountState { initial, enProceso, creada, error }

class PhysicalCountProvider extends ChangeNotifier {
  final PhysicalCountRepository _repository;

  PhysicalCountState _state = PhysicalCountState.initial;
  PhysicalCountState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Listas de datos para selectores
  List<CompanyModel> companies = [];
  List<WarehouseModel> warehouses = [];
  List<ArticleModel> articles = [];
  List<PersonalModel> foundPersons = [];

  // Múltiples personas seleccionadas
  List<PersonalModel> selectedPersons = [];

  // Valores seleccionados
  CompanyModel? selectedCompany;
  WarehouseModel? selectedWarehouse;
  DateTime selectedDate = DateTime.now();
  ArticleModel? selectedArticle;
  bool verifyExistence = false;

  PhysicalCountProvider(this._repository) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _setState(PhysicalCountState.enProceso);
    try {
      companies = await _repository.getCompanies();
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
      warehouses = await _repository.getWarehouses(companyId);
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

    if (warehouse != null && selectedCompany != null) {
      _loadArticles(warehouse.bodeCodi, selectedCompany!.codigo);
    }
  }

  Future<void> _loadArticles(String warehouseId, String companyId) async {
    _setState(PhysicalCountState.enProceso);
    try {
      articles = await _repository.getArticles(warehouseId, companyId);
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

    _setState(PhysicalCountState.enProceso);

    try {
      foundPersons = await _repository.searchPersons(
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
      );
      _setState(PhysicalCountState.initial);
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

  void togglePersonSelection(PersonalModel person) {
    final index = selectedPersons.indexWhere(
      (p) => p.perscodi == person.perscodi,
    );
    if (index >= 0) {
      selectedPersons.removeAt(index);
    } else {
      selectedPersons.add(person);
    }
    notifyListeners();
  }

  void removePerson(PersonalModel person) {
    selectedPersons.removeWhere((p) => p.perscodi == person.perscodi);
    notifyListeners();
  }

  // --- LÓGICA DE NEGOCIO ---
  Future<void> submitPhysicalCount() async {
    if (!_validateFields()) return;

    _setState(PhysicalCountState.enProceso);

    final request = PhysicalCountRequest(
      empresa: selectedCompany!.codigo,
      bodega: selectedWarehouse!.bodeCodi,
      fecha: selectedDate,
      articulo: selectedArticle!.id,
      verificarExistencia: verifyExistence,
    );

    try {
      await _repository.createPhysicalCount(request);
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

  Future<void> assignPhysicalCount() async {
    if (selectedCompany == null || selectedWarehouse == null) {
      _setError(
        'Debe seleccionar la Empresa y la Bodega en la pestaña de Apertura.',
      );
      return;
    }

    if (selectedPersons.isEmpty) {
      _setError('Debe seleccionar al menos un participante para la asignación.');
      return;
    }

    _setState(PhysicalCountState.enProceso);

    final request = AsignacionConteoRequest(
      empresa: selectedCompany!.codigo,
      bodega: selectedWarehouse!.bodeCodi,
      fechaConteo: selectedDate,
      usuarios:
          selectedPersons
              .map(
                (p) => UsuarioAsignacion(
                  documento: p.perscodi,
                  nombre: '${p.persnomb} ${p.persapel}'.trim(),
                  email: p.perscoel,
                ),
              )
              .toList(),
    );

    try {
      await _repository.assignArticles(request);
      _setState(PhysicalCountState.creada); // Reutilizamos el estado de éxito
    } catch (e) {
      String msg = 'Error al asignar el conteo.';
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          msg =
              'Error de validación (400). Verifique los datos de la asignación.';
        } else {
          msg = 'Error de red al asignar: ${e.message}';
        }
      }
      _setError(msg);
    }
  }

  Future<void> createAndAssignPhysicalCount() async {
    if (!_validateFields()) return;

    if (selectedPersons.isEmpty) {
      _setError('Debe seleccionar al menos un participante para la asignación.');
      return;
    }

    _setState(PhysicalCountState.enProceso);

    final createRequest = PhysicalCountRequest(
      empresa: selectedCompany!.codigo,
      bodega: selectedWarehouse!.bodeCodi,
      fecha: selectedDate,
      articulo: selectedArticle!.id,
      verificarExistencia: verifyExistence,
    );

    try {
      await _repository.createPhysicalCount(createRequest);
    } catch (e) {
      String msg = 'Un error inesperado ha ocurrido al crear el conteo.';
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
      return; // Stop here if creation fails
    }

    final assignRequest = AsignacionConteoRequest(
      empresa: selectedCompany!.codigo,
      bodega: selectedWarehouse!.bodeCodi,
      fechaConteo: selectedDate,
      usuarios: selectedPersons
          .map((p) => UsuarioAsignacion(
                documento: p.perscodi,
                nombre: '${p.persnomb} ${p.persapel}'.trim(),
                email: p.perscoel,
              ))
          .toList(),
    );

    try {
      await _repository.assignArticles(assignRequest);
      _setState(PhysicalCountState.creada); 
    } catch (e) {
      String msg = 'Conteo creado, pero error al asignar personal.';
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          msg = 'Error de validación (400) en asignación.';
        } else {
          msg = 'Error de red al asignar: ${e.message}';
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
