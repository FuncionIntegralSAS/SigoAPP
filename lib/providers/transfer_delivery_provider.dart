import 'package:flutter/material.dart';
import '../models/transfer_request.dart';
import '../models/transfer_delivery_request.dart';
import '../repositories/transfer_repository.dart';

class TransferDeliveryProvider extends ChangeNotifier {
  final TransferRepository repository;

  TransferDeliveryProvider(this.repository);

  List<TransferRequest> _transfers = [];
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadTransfers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _transfers = await repository.getAllTransfers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<TransferRequest> getAssignedTransfers([String? userIdentifier]) {
    return _transfers.where((t) {
      // Solo mostramos los aprobados ('ap')
      if (t.estado != TransferStatus.approved) return false;

      // Si no se especifica identificador o viene vacío, mostramos todos los aprobados
      if (userIdentifier == null || userIdentifier.trim().isEmpty) {
        return true;
      }

      final query = userIdentifier.trim().toLowerCase();
      return t.responsableActual.toLowerCase().contains(query) ||
          t.responsablePropuesto.toLowerCase().contains(query);
    }).toList();
  }

  Future<bool> submitDelivery(String transferId, {String? dispatcherBase64, String? receiverBase64}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final request = TransferDeliveryRequest(
        transferId: transferId,
        firmaDespachadorBase64: dispatcherBase64,
        firmaReceptorBase64: receiverBase64,
      );
      await repository.applyTransferDelivery(request);
      await loadTransfers();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
