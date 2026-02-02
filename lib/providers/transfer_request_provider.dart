import 'package:flutter/material.dart';
import '../models/transfer_request.dart';
import '../repositories/transfer_repository.dart';

class TransferRequestProvider extends ChangeNotifier {
  final TransferRepository repository;

  bool _loading = false;
  bool get loading => _loading;

  TransferRequestProvider(this.repository);

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

    // Simulación mínima (opcional, útil para UX)
    await Future.delayed(const Duration(milliseconds: 300));

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

    // ✅ MÉTODO CORRECTO
    repository.create(request);

    _setLoading(false);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
