import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/geolocation_model.dart';
import 'package:sigo_app/providers/geolocation_provider.dart';
import 'package:sigo_app/repositories/geolocation_repository.dart';
import 'package:sigo_app/exceptions/geolocation_business_exception.dart';

class FakeGeolocationRepository implements GeolocationRepository {
  final Map<int, GeolocationModel> database = {};
  bool shouldThrow = false;

  @override
  Future<GeolocationModel?> getGeolocationByAssetId(int assetId) async {
    if (shouldThrow) {
      throw GeolocationBusinessException('Fallo de conexión al servidor');
    }
    return database[assetId];
  }

  @override
  Future<void> createGeolocation(GeolocationModel model) async {
    if (shouldThrow) {
      throw GeolocationBusinessException('Error al crear registro');
    }
    database[model.idRegistro] = model;
  }

  @override
  Future<void> updateGeolocation(GeolocationModel model) async {
    if (shouldThrow) {
      throw GeolocationBusinessException('Error al actualizar registro');
    }
    database[model.idRegistro] = model;
  }

  @override
  Future<void> deleteGeolocation(int assetId) async {
    database.remove(assetId);
  }
}

void main() {
  group('GeolocationProvider Tests', () {
    late FakeGeolocationRepository repository;
    late GeolocationProvider provider;

    setUp(() {
      repository = FakeGeolocationRepository();
      provider = GeolocationProvider(repository);
    });

    test('Estado inicial debe ser initial', () {
      expect(provider.state, equals(GeolocationState.initial));
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
    });

    test('syncGeolocation crea nuevo registro si no existía y retorna true', () async {
      final success = await provider.syncGeolocation(10, 4.6097, -74.0817);

      expect(success, isTrue);
      expect(provider.state, equals(GeolocationState.success));
      expect(provider.errorMessage, isNull);
      expect(repository.database[10]?.latitud, equals(4.6097));
    });

    test('syncGeolocation actualiza registro si ya existía y retorna true', () async {
      repository.database[10] = const GeolocationModel(
        idRegistro: 10,
        latitud: 1.0,
        longitud: 2.0,
      );

      final success = await provider.syncGeolocation(10, 5.0, 6.0);

      expect(success, isTrue);
      expect(provider.state, equals(GeolocationState.success));
      expect(repository.database[10]?.latitud, equals(5.0));
      expect(repository.database[10]?.longitud, equals(6.0));
    });

    test('syncGeolocation captura excepción sin colapsar y retorna false', () async {
      repository.shouldThrow = true;

      final success = await provider.syncGeolocation(10, 4.0, -74.0);

      expect(success, isFalse);
      expect(provider.state, equals(GeolocationState.error));
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('Fallo de conexión'));
    });

    test('getGeolocation retorna modelo o captura error controlado', () async {
      repository.database[25] = const GeolocationModel(
        idRegistro: 25,
        latitud: 10.5,
        longitud: -75.2,
      );

      final model = await provider.getGeolocation(25);
      expect(model?.latitud, equals(10.5));

      repository.shouldThrow = true;
      final failedModel = await provider.getGeolocation(25);
      expect(failedModel, isNull);
      expect(provider.hasError, isTrue);
    });
  });
}
