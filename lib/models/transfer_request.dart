enum TransferStatus { pending, approved, rejected, completed }

class TransferRequest {
  final String id;
  final String articleId;
  final String articleName;
  final String currentResponsible;  
  final String proposedResponsible;
  final String currentWarehouse;
  final String proposedWarehouse;
  final String requestReason;
  final DateTime requestDate;
  final DateTime? appliedDate;
  final TransferStatus status;
  final String? rejectionReason;

  TransferRequest({
    required this.id,
    required this.articleId,
    required this.articleName,
    required this.currentResponsible,
    required this.proposedResponsible,
    required this.requestReason,
    required this.requestDate,
    required this.currentWarehouse,
    required this.proposedWarehouse,
    this.status = TransferStatus.pending,
    this.rejectionReason,
    this.appliedDate,
  });

  TransferRequest copyWith({
    TransferStatus? status,
    String? rejectionReason,
  }) {
    return TransferRequest(
      id: id,
      articleId: articleId,
      articleName: articleName,
      currentResponsible: currentResponsible,
      proposedResponsible: proposedResponsible,
      currentWarehouse: currentWarehouse,
      proposedWarehouse: proposedWarehouse,
      requestReason: requestReason,
      requestDate: requestDate,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }


  // Helper para convertir a Map (útil para bases de datos/servicios)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'articleId': articleId,
      'articleName': articleName,
      'currentResponsible': currentResponsible,
      'proposedResponsible': proposedResponsible,
      'currentWarehouse' : currentWarehouse,
      'proposedWarehouse' : proposedWarehouse,
      'requestReason': requestReason,
      'requestDate': requestDate.toIso8601String(),
      'status': status.name,
      'rejectionReason': rejectionReason,
      'appliedDate': appliedDate ?? this.appliedDate,
    };
  }
}