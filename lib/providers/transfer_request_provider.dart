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
    required String articleId,
    required String articleName,
    required String currentResponsible,
    required String proposedResponsible,
    required String currentWarehouse,
    required String proposedWarehouse,
    required String requestReason,
  }) async {
    _setLoading(true);

    final request = TransferRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      articleId: articleId,
      articleName: articleName,
      currentResponsible: currentResponsible,
      proposedResponsible: proposedResponsible,
      currentWarehouse: currentWarehouse,
      proposedWarehouse: proposedWarehouse,
      requestReason: requestReason,
      requestDate: DateTime.now(),
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
