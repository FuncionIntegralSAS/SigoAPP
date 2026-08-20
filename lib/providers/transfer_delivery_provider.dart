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

  List<TransferRequest> getAssignedTransfers(String userIdentifier) {
    return _transfers.where((t) {
      // Solo mostramos los aprobados ('ap')
      if (t.status != TransferStatus.approved) return false;

      // Y que estén asignados al usuario (como actual o propuesto)
      // userIdentifier puede ser la cédula o nombre
      return t.currentResponsible.contains(userIdentifier) || 
             t.proposedResponsible.contains(userIdentifier);
    }).toList();
  }

  Future<bool> submitDelivery(String transferId, {String? dispatcherBase64, String? receiverBase64}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final request = TransferDeliveryRequest(
        transferId: transferId,
        dispatcherSignatureBase64: dispatcherBase64,
        receiverSignatureBase64: receiverBase64,
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
