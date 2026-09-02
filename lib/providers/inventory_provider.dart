import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../repositories/inventory_repository.dart';

enum InventoryState { initial, loading, error, success }

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;

  InventoryProvider(this._repository);

  InventoryState _state = InventoryState.initial;
  InventoryState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<CompanyModel> companies = [];
  List<WarehouseModel> warehouses = [];
  List<ArticleModel> articles = [];

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

  void selectCompany(CompanyModel? company) {
    selectedCompany = company;
    selectedWarehouse = null;
    warehouses.clear();
    articles.clear();
    notifyListeners();

    if (company != null) {
      _loadWarehouses(company.codigo);
    }
  }

  Future<void> _loadWarehouses(String companyId) async {
    _setState(InventoryState.loading);
    try {
      warehouses = await _repository.getWarehouses(companyId);
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
    articles.clear();
    notifyListeners();

    if (bodega != null && selectedCompany != null) {
      _loadArticles(bodega.codigoBodega, selectedCompany!.codigo);
    }
  }

  Future<void> _loadArticles(String idBodega, String companyId) async {
    _setState(InventoryState.loading);
    try {
      articles = await _repository.getArticles(idBodega, companyId);
      _setState(InventoryState.success);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        _setError('Su sesión ha expirado o no tiene permisos. Por favor, vuelva a iniciar sesión.');
      } else {
        _setError('Error al cargar artículos.');
      }
    }
  }
  
  // Refresca la lista de artículos manualmente
  Future<void> refreshArticles() async {
    if (selectedWarehouse != null && selectedCompany != null) {
      await _loadArticles(selectedWarehouse!.codigoBodega, selectedCompany!.codigo);
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
    _state = InventoryState.initial; // o success
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
      notifyListeners();
    }
  }

  void resetForm() {
    selectedCompany = null;
    selectedWarehouse = null;
    warehouses.clear();
    articles.clear();
    _setState(InventoryState.initial);
  }
}
