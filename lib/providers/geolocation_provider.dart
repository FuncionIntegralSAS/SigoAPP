import 'package:flutter/material.dart';
import '../models/geolocation_model.dart';
import '../repositories/geolocation_repository.dart';

enum GeolocationState { initial, loading, success, error }

class GeolocationProvider extends ChangeNotifier {
  final GeolocationRepository _repository;

  GeolocationState _state = GeolocationState.initial;
  String? _errorMessage;

  GeolocationState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == GeolocationState.loading;
  bool get hasError => _state == GeolocationState.error;

  GeolocationProvider(this._repository);

  /// Sincroniza la geolocalización de un activo en backend.
  /// Retorna `true` si la operación fue exitosa, o `false` si ocurrió un error controlado.
  Future<bool> syncGeolocation(int assetId, double lat, double lon) async {
    _state = GeolocationState.loading;
    _errorMessage = null;
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

      _state = GeolocationState.success;
      return true;
    } catch (e) {
      _state = GeolocationState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Obtiene la geolocalización de un activo directamente de la BD (backend).
  Future<GeolocationModel?> getGeolocation(int assetId) async {
    _state = GeolocationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getGeolocationByAssetId(assetId);
      _state = GeolocationState.success;
      return result;
    } catch (e) {
      _state = GeolocationState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      notifyListeners();
    }
  }

  /// Limpia el mensaje y estado de error.
  void clearError() {
    _errorMessage = null;
    _state = GeolocationState.initial;
    notifyListeners();
  }
}
