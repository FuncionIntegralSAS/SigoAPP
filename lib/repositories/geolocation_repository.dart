import '../models/geolocation_model.dart';

abstract class GeolocationRepository {
  Future<GeolocationModel?> getGeolocationByAssetId(int assetId);
  Future<void> createGeolocation(GeolocationModel model);
  Future<void> updateGeolocation(GeolocationModel model);
  Future<void> deleteGeolocation(int assetId);
}
