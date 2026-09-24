import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_person_model.dart';
import 'package:sigo_app/modules/inventory/repositories/inventory_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/transfer_repository.dart';

enum InventoryState { initial, loading, error, success }

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  final TransferRepository? _transferRepository;

  InventoryProvider(
    this._repository, {
    TransferRepository? transferRepository,
  }) : _transferRepository = transferRepository;

  InventoryState _state = InventoryState.initial;
  InventoryState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<CompanyModel> companies = [];
  List<WarehouseModel> warehouses = [];
  List<ArticleModel> articles = [];
  List<ArticleModel> _allArticles = [];

  // Soporte de colaboradores por bodega
  List<TransferPersonModel> collaborators = [];
  TransferPersonModel? selectedCollaborator;
  bool isLoadingCollaborators = false;
  String? collaboratorErrorMessage;

  CompanyModel? selectedCompany;
  WarehouseModel? selectedWarehouse;

  Future<void> loadCompanies() async {
    _setState(InventoryState.loading);
    try {
      companies = await _repository.getCompanies();
      _setState(InventoryState.success);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        _setError('Su sesión ha expirado o no tiene permisos. Por favor, vuelva a iniciar sesión.');
      } else {
        _setError('Error al cargar empresas. ${e is DioException ? (e.response?.data?['message'] ?? e.message) : e}');
      }
    }
  }

  void selectCompany(CompanyModel? company, {String tipo = 'PE'}) {
    selectedCompany = company;
    selectedWarehouse = null;
    selectedCollaborator = null;
    warehouses.clear();
    collaborators.clear();
    articles.clear();
    _allArticles.clear();
    notifyListeners();

    if (company != null) {
      loadWarehouses(company.codigo, tipo: tipo);
    }
  }

  Future<void> loadWarehouses(String companyId, {String tipo = 'PE'}) async {
    _setState(InventoryState.loading);
    try {
      warehouses = await _repository.getWarehouses(companyId, tipo: tipo);
      _setState(InventoryState.success);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        _setError('Su sesión ha expirado o no tiene permisos. Por favor, vuelva a iniciar sesión.');
      } else {
        _setError('Error al cargar bodegas.');
      }
    }
  }

  void selectWarehouse(WarehouseModel? bodega) {
    selectedWarehouse = bodega;
    selectedCollaborator = null;
    collaborators.clear();
    articles.clear();
    _allArticles.clear();
    notifyListeners();

    if (bodega != null && selectedCompany != null) {
      if (bodega.codigoBodega != 'ALL') {
        loadCollaborators(bodega.codigoBodega, selectedCompany!.codigo);
      }
    }
  }

  /// Consulta los colaboradores asociados a una [bodega] en una [empresa].
  Future<void> loadCollaborators(String bodega, String empresa) async {
    if (_transferRepository == null) {
      collaborators.clear();
      return;
    }

    isLoadingCollaborators = true;
    collaboratorErrorMessage = null;
    notifyListeners();

    try {
      collaborators = await _transferRepository.getPersonsByWarehouse(
        bodega: bodega,
        empresa: empresa,
      );
    } catch (e) {
      collaboratorErrorMessage = 'No se pudieron obtener colaboradores remotos.';
      collaborators.clear();
    } finally {
      isLoadingCollaborators = false;
      notifyListeners();
    }
  }

  /// Consulta los activos asignados al [collaborator] seleccionado en la bodega activa.
  /// Requiere que la empresa y la bodega hayan sido seleccionadas previamente.
  /// Si [collaborator] es null o 'ALL', limpia la lista de artículos.
  Future<void> selectCollaborator(TransferPersonModel? collaborator) async {
    selectedCollaborator = (collaborator == null || collaborator.cedula == 'ALL')
        ? null
        : collaborator;

    if (selectedCollaborator == null) {
      articles.clear();
      _allArticles.clear();
      notifyListeners();
      return;
    }

    final warehouseCode = selectedWarehouse?.codigoBodega;
    final companyCode = selectedCompany?.codigo;

    // Validación: la consulta de activos requiere empresa y bodega válidas
    if (_transferRepository == null ||
        warehouseCode == null ||
        warehouseCode.trim().isEmpty ||
        warehouseCode == 'ALL' ||
        companyCode == null ||
        companyCode.trim().isEmpty) {
      articles.clear();
      _allArticles.clear();
      notifyListeners();
      return;
    }

    _setState(InventoryState.loading);
    try {
      final remoteAssets = await _transferRepository.getAssetsByPerson(
        persona: selectedCollaborator!.cedula,
        bodega: warehouseCode.trim(),
        empresa: companyCode,
      );

      articles = remoteAssets.map((asset) {
        return ArticleModel(
          codigoActivo: asset.articulo,
          nombre: asset.nombre,
          placa: asset.placa ?? '',
          bodega: warehouseCode.trim(),
          responsable: selectedCollaborator!.nombreCompleto,
        );
      }).toList();
      _allArticles = List.from(articles);
      _setState(InventoryState.success);
    } catch (e) {
      articles.clear();
      _allArticles.clear();
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        _setError('Su sesión ha expirado o no tiene permisos. Por favor, vuelva a iniciar sesión.');
      } else {
        _setState(InventoryState.success);
      }
    }
  }

  // Refresca la lista de artículos del colaborador seleccionado manualmente
  Future<void> refreshArticles() async {
    if (selectedWarehouse != null &&
        selectedCompany != null &&
        selectedCollaborator != null &&
        selectedCollaborator!.cedula != 'ALL') {
      await selectCollaborator(selectedCollaborator);
    }
  }

  void _setState(InventoryState newState) {
    _state = newState;
    if (newState != InventoryState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = InventoryState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = InventoryState.initial;
    notifyListeners();
  }

  void updateArticleLocally(ArticleModel updated) {
    final index = articles.indexWhere(
      (a) =>
          (a.id != null && updated.id != null && a.id == updated.id) ||
          a.codigoActivo == updated.codigoActivo,
    );
    if (index != -1) {
      articles[index] = updated;
    }

    final allIndex = _allArticles.indexWhere(
      (a) =>
          (a.id != null && updated.id != null && a.id == updated.id) ||
          a.codigoActivo == updated.codigoActivo,
    );
    if (allIndex != -1) {
      _allArticles[allIndex] = updated;
    }

    if (index != -1 || allIndex != -1) {
      notifyListeners();
    }
  }

  void resetForm() {
    selectedCompany = null;
    selectedWarehouse = null;
    selectedCollaborator = null;
    warehouses.clear();
    collaborators.clear();
    articles.clear();
    _allArticles.clear();
    isLoadingCollaborators = false;
    collaboratorErrorMessage = null;
    _setState(InventoryState.initial);
  }
}

