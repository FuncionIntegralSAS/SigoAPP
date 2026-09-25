import 'package:flutter/material.dart';
import 'package:sigo_app/exceptions/transfer_business_exception.dart';
import 'package:sigo_app/services/notification_service.dart';
import 'package:sigo_app/modules/inventory/models/transfer_create_request.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/modules/inventory/repositories/transfer_repository.dart';

class TransferRequestProvider extends ChangeNotifier {
  final TransferRepository repository;
  final NotificationService notificationService;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _technicalDetails;
  String? get technicalDetails => _technicalDetails;

  int? _statusCode;
  int? get statusCode => _statusCode;

  String? _endpoint;
  String? get endpoint => _endpoint;

  TransferRequestProvider(this.repository, this.notificationService);

  void clearError() {
    _errorMessage = null;
    _technicalDetails = null;
    _statusCode = null;
    _endpoint = null;
    notifyListeners();
  }

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
    _errorMessage = null;
    _technicalDetails = null;
    _statusCode = null;
    _endpoint = null;

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
    } on TransferBusinessException catch (e) {
      _errorMessage = e.message;
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
      _endpoint = e.endpoint;
      notificationService.error(e.message);
      return false;
    } catch (e) {
      final cleanError = e.toString().replaceAll('Exception: ', '');
      _errorMessage = 'Error al crear la solicitud: $cleanError';
      _technicalDetails = e.toString();
      notificationService.error(_errorMessage!);
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
