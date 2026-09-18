import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../models/transfer_person_model.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/transfer_repository.dart';

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
      _loadArticles(bodega.codigoBodega, selectedCompany!.codigo);
      if (bodega.codigoBodega != 'ALL') {
        loadCollaborators(bodega.codigoBodega, selectedCompany!.codigo);
      }
    }
  }

  Future<void> _loadArticles(String idBodega, String companyId) async {
    _setState(InventoryState.loading);
    try {
      final fetched = await _repository.getArticles(idBodega, companyId);
      _allArticles = List.from(fetched);
      if (selectedCollaborator == null || selectedCollaborator!.cedula == 'ALL') {
        articles = List.from(fetched);
      }
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

  /// Consulta los colaboradores asociados a una [bodega] en una [empresa].
  Future<void> loadCollaborators(String bodega, String empresa) async {
    if (_transferRepository == null) {
      _extractCollaboratorsFromArticles();
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
      _extractCollaboratorsFromArticles();
    } finally {
      isLoadingCollaborators = false;
      notifyListeners();
    }
  }

  /// Filtra los artículos de la bodega según el [collaborator] seleccionado.
  /// Si [collaborator] es null o 'ALL', restablece la lista completa de artículos de la bodega.
  Future<void> selectCollaborator(TransferPersonModel? collaborator) async {
    selectedCollaborator = (collaborator == null || collaborator.cedula == 'ALL')
        ? null
        : collaborator;
    if (selectedCollaborator == null) {
      articles = List.from(_allArticles);
      notifyListeners();
      return;
    }

    final colName = selectedCollaborator!.nombreCompleto.toLowerCase().trim();
    final colCedula = selectedCollaborator!.cedula.toLowerCase().trim();

    final filtered = _allArticles.where((a) {
      final resp = a.responsable?.toLowerCase().trim() ?? '';
      if (resp.isEmpty) return false;
      return resp == colName ||
          resp.contains(colName) ||
          colName.contains(resp) ||
          (colCedula.isNotEmpty && resp.contains(colCedula));
    }).toList();

    if (filtered.isNotEmpty || _transferRepository == null) {
      articles = filtered;
      notifyListeners();
      return;
    }

    // Si no hay coincidencias locales y se dispone del repositorio de traspasos,
    // consultar activos asignados al colaborador por su cédula
    _setState(InventoryState.loading);
    try {
      final remoteAssets = await _transferRepository.getAssetsByPerson(
        persona: selectedCollaborator!.cedula,
        empresa: selectedCompany?.codigo,
      );

      articles = remoteAssets.map((asset) {
        final existing = _allArticles.where((a) {
          if (a.codigoActivo.trim().toLowerCase() !=
              asset.articulo.trim().toLowerCase()) {
            return false;
          }
          final aPlaca = a.placa.trim().toLowerCase();
          final assetPlaca = asset.placa?.trim().toLowerCase();
          final hasA = aPlaca.isNotEmpty && aPlaca != 'n/a';
          final hasAsset =
              assetPlaca != null && assetPlaca.isNotEmpty && assetPlaca != 'n/a';
          if (hasA || hasAsset) {
            return aPlaca == assetPlaca;
          }
          return true;
        }).firstOrNull;

        if (existing != null) return existing;
        return ArticleModel(
          codigoActivo: asset.articulo,
          nombre: asset.nombre,
          placa: asset.placa ?? '',
          bodega: selectedWarehouse?.codigoBodega ?? '',
          responsable: selectedCollaborator!.nombreCompleto,
        );
      }).toList();
      _setState(InventoryState.success);
    } catch (e) {
      articles = filtered;
      _setState(InventoryState.success);
    }
  }

  /// Fallback: extrae colaboradores únicos a partir de los artículos existentes.
  void _extractCollaboratorsFromArticles() {
    final Map<String, TransferPersonModel> map = {};
    for (final a in _allArticles) {
      final resp = a.responsable?.trim();
      if (resp != null &&
          resp.isNotEmpty &&
          resp.toUpperCase() != 'N/A' &&
          !map.containsKey(resp)) {
        map[resp] = TransferPersonModel(
          cedula: resp,
          nombre: resp,
          apellido: '',
        );
      }
    }
    collaborators = map.values.toList();
  }
  
  // Refresca la lista de artículos manualmente
  Future<void> refreshArticles() async {
    if (selectedWarehouse != null && selectedCompany != null) {
      final currentCollaborator = selectedCollaborator;
      await _loadArticles(selectedWarehouse!.codigoBodega, selectedCompany!.codigo);
      if (_state != InventoryState.error &&
          currentCollaborator != null &&
          currentCollaborator.cedula != 'ALL') {
        await selectCollaborator(currentCollaborator);
      }
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

