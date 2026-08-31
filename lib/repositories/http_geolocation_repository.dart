import 'package:dio/dio.dart';
import '../models/geolocation_model.dart';
import '../repositories/geolocation_repository.dart';
import '../exceptions/geolocation_business_exception.dart';

class HttpGeolocationRepository implements GeolocationRepository {
  final Dio dio;

  HttpGeolocationRepository(this.dio);

  @override
  Future<GeolocationModel?> getGeolocationByAssetId(int assetId) async {
    try {
      final response = await dio.get(
        '/api/v1/geolocalizacion-activos/$assetId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return GeolocationModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      _handleDioError(e, 'Error al obtener la geolocalización');
      return null;
    }
  }

  @override
  Future<void> createGeolocation(GeolocationModel model) async {
    try {
      await dio.post(
        '/api/v1/geolocalizacion-activos',
        data: model.toJson(),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Error al crear la geolocalización');
    }
  }

  @override
  Future<void> updateGeolocation(GeolocationModel model) async {
    try {
      await dio.put(
        '/api/v1/geolocalizacion-activos/${model.idRegistro}',
        data: {
          'latitud': model.latitud,
          'longitud': model.longitud,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Error al actualizar la geolocalización');
    }
  }

  @override
  Future<void> deleteGeolocation(int assetId) async {
    try {
      await dio.delete('/api/v1/geolocalizacion-activos/$assetId');
    } on DioException catch (e) {
      _handleDioError(e, 'Error al eliminar la geolocalización');
    }
  }

  void _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        throw GeolocationBusinessException(
          data['message'] ?? defaultMessage,
          code: data['code']?.toString(),
        );
      }
    }
    throw GeolocationBusinessException(
      '$defaultMessage: ${e.response?.statusCode ?? e.message}',
    );
  }
}
