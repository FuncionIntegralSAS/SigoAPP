import 'package:flutter/material.dart';
import 'package:sigo_app/services/notification_service.dart';
import '../models/transfer_request.dart';
import '../repositories/transfer_repository.dart';

class TransferRequestProvider extends ChangeNotifier {
  final TransferRepository repository;
  final NotificationService notificationService;

  bool _loading = false;
  bool get loading => _loading;

  TransferRequestProvider(this.repository, this.notificationService);

  Future<void> createRequest({
    required String idArticulo,
    required String nombreArticulo,
    required String responsableActual,
    required String responsablePropuesto,
    required String bodegaActual,
    required String bodegaPropuesta,
    required String motivoSolicitud,
  }) async {
    _setLoading(true);

    final request = TransferRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idArticulo: idArticulo,
      nombreArticulo: nombreArticulo,
      responsableActual: responsableActual,
      responsablePropuesto: responsablePropuesto,
      bodegaActual: bodegaActual,
      bodegaPropuesta: bodegaPropuesta,
      motivoSolicitud: motivoSolicitud,
      fechaSolicitud: DateTime.now(),
    );

    try {
      await repository.create(request);
      notificationService.success(
        'Solicitud de traspaso enviada correctamente',
      );
    } catch (e) {
      notificationService.error(
        'Error al crear la solicitud: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
