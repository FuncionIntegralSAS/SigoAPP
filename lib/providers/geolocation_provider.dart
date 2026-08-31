import 'package:flutter/material.dart';
import '../models/geolocation_model.dart';
import '../repositories/geolocation_repository.dart';

class GeolocationProvider extends ChangeNotifier {
  final GeolocationRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  GeolocationProvider(this._repository);

  /// Sincroniza la geolocalización de un activo.
  /// Primero intenta obtenerla; si no existe, la crea. Si existe, la actualiza.
  Future<void> syncGeolocation(int assetId, double lat, double lon) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existingGeo = await _repository.getGeolocationByAssetId(assetId);

      final model = GeolocationModel(
        idRegistro: assetId,
        latitud: lat,
        longitud: lon,
      );

      if (existingGeo == null) {
        // No existe, hacer POST
        await _repository.createGeolocation(model);
      } else {
        // Existe, hacer PUT
        await _repository.updateGeolocation(model);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene la geolocalización de un activo directamente de la BD (backend).
  Future<GeolocationModel?> getGeolocation(int assetId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      return await _repository.getGeolocationByAssetId(assetId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
