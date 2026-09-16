import 'package:flutter/material.dart';
import 'package:sigo_app/services/notification_service.dart';
import '../models/transfer_create_request.dart';
import '../models/transfer_request.dart';
import '../repositories/transfer_repository.dart';

class TransferRequestProvider extends ChangeNotifier {
  final TransferRepository repository;
  final NotificationService notificationService;

  bool _loading = false;
  bool get loading => _loading;

  TransferRequestProvider(this.repository, this.notificationService);

  Future<bool> createRequest({
    required String codigoActivo,
    required String nombreArticulo,
    required String responsableActual,
    required String responsablePropuesto,
    required String bodegaActual,
    required String bodegaPropuesta,
    required String motivoSolicitud,
    String? empresa,
    String? personaFuente,
    String? personaDestino,
    String? placa,
    List<TransferArticleItem>? articulos,
    String? tipoMovimiento,
  }) async {
    _setLoading(true);

    final resolvedFuente = personaFuente?.trim().isNotEmpty == true
        ? personaFuente!.trim()
        : responsableActual.trim();

    final resolvedDestino = personaDestino?.trim().isNotEmpty == true
        ? personaDestino!.trim()
        : responsablePropuesto.trim();

    final List<TransferArticleItem> items =
        (articulos != null && articulos.isNotEmpty)
        ? articulos
        : [TransferArticleItem(articulo: codigoActivo, placa: placa)];

    final request = TransferCreateRequest(
      empresa: empresa ?? '01',
      personaFuente: resolvedFuente,
      personaDestino: resolvedDestino,
      articulos: items,
      observacion: motivoSolicitud,
      tipoMovimiento: tipoMovimiento,
    );

    try {
      await repository.create(request);
      notificationService.success(
        'Solicitud de traspaso enviada correctamente',
      );
      return true;
    } catch (e) {
      final cleanError = e.toString().replaceAll('Exception: ', '');
      notificationService.error('Error al crear la solicitud: $cleanError');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
