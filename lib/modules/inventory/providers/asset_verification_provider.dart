import 'package:flutter/material.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';

class AssetVerificationProvider extends ChangeNotifier {
  String? _selectedWarehouse;
  String? _selectedOwner;

  final Set<String> _verifiedAssetCodes = <String>{};
  final List<ArticleModel> _conflictAssets = <ArticleModel>[];

  String? get selectedWarehouse => _selectedWarehouse;
  String? get selectedOwner => _selectedOwner;

  /// Conjunto de códigos y placas de activos que han sido verificados satisfactoriamente
  Set<String> get verifiedAssetCodes => Set.unmodifiable(_verifiedAssetCodes);

  /// Lista de activos escaneados que no pertenecen al responsable esperado
  List<ArticleModel> get conflictAssets => List.unmodifiable(_conflictAssets);

  void selectWarehouse(String bodega) {
    _selectedWarehouse = bodega;
    notifyListeners();
  }

  void selectOwner(String? owner) {
    _selectedOwner = owner;
    notifyListeners();
  }

  bool hasResponsibleConflict({
    required String? articleResponsible,
  }) {
    if (_selectedOwner == null || _selectedOwner!.isEmpty) {
      return false;
    }

    return articleResponsible != _selectedOwner;
  }

  /// Verifica si un artículo específico ya fue escaneado y validado
  bool isVerified(ArticleModel article) {
    final code = article.codigoActivo.trim().toLowerCase();
    final plate = article.placa.trim().toLowerCase();
    return (code.isNotEmpty && _verifiedAssetCodes.contains(code)) ||
        (plate.isNotEmpty && _verifiedAssetCodes.contains(plate));
  }

  /// Evalúa un activo escaneado contra la lista de activos esperados.
  /// Si coincide por código o placa, se marca como verificado y se limpia de conflictos.
  /// Si difiere, se clasifica como activo en conflicto.
  bool verifyAsset(ArticleModel scannedAsset, List<ArticleModel> expectedAssets) {
    final scannedCode = scannedAsset.codigoActivo.trim().toLowerCase();
    final scannedPlate = scannedAsset.placa.trim().toLowerCase();

    final matchIndex = expectedAssets.indexWhere((expected) {
      final expCode = expected.codigoActivo.trim().toLowerCase();
      final expPlate = expected.placa.trim().toLowerCase();
      final matchByCode = expCode.isNotEmpty && scannedCode.isNotEmpty && expCode == scannedCode;
      final matchByPlate = expPlate.isNotEmpty && scannedPlate.isNotEmpty && expPlate == scannedPlate;
      return matchByCode || matchByPlate;
    });

    if (matchIndex != -1) {
      final matched = expectedAssets[matchIndex];
      if (matched.codigoActivo.trim().isNotEmpty) {
        _verifiedAssetCodes.add(matched.codigoActivo.trim().toLowerCase());
      }
      if (scannedCode.isNotEmpty) {
        _verifiedAssetCodes.add(scannedCode);
      }
      if (matched.placa.trim().isNotEmpty) {
        _verifiedAssetCodes.add(matched.placa.trim().toLowerCase());
      }
      if (scannedPlate.isNotEmpty) {
        _verifiedAssetCodes.add(scannedPlate);
      }

      _conflictAssets.removeWhere((c) {
        final cCode = c.codigoActivo.trim().toLowerCase();
        final cPlate = c.placa.trim().toLowerCase();
        return (cCode.isNotEmpty &&
                (cCode == scannedCode ||
                    (matched.codigoActivo.trim().isNotEmpty &&
                        cCode == matched.codigoActivo.trim().toLowerCase()))) ||
            (cPlate.isNotEmpty &&
                (cPlate == scannedPlate ||
                    (matched.placa.trim().isNotEmpty &&
                        cPlate == matched.placa.trim().toLowerCase())));
      });

      notifyListeners();
      return true;
    } else {
      final alreadyInConflict = _conflictAssets.any((c) {
        final cCode = c.codigoActivo.trim().toLowerCase();
        final cPlate = c.placa.trim().toLowerCase();
        return (scannedCode.isNotEmpty && cCode == scannedCode) ||
            (scannedPlate.isNotEmpty && cPlate == scannedPlate);
      });

      if (!alreadyInConflict) {
        _conflictAssets.add(scannedAsset);
      }
      notifyListeners();
      return false;
    }
  }

  /// Limpia los estados de verificación y conflictos (al cambiar de responsable)
  void resetVerification() {
    _verifiedAssetCodes.clear();
    _conflictAssets.clear();
    notifyListeners();
  }

  /// Limpia los filtros y selecciones de verificación al cerrar sesión
  void reset() {
    _selectedWarehouse = null;
    _selectedOwner = null;
    resetVerification();
  }
}

