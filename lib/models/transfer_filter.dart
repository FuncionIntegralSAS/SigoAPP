import 'transfer_request.dart';

class TransferFilter {
  final TransferStatus status;
  final String? proposedWarehouse; // null = todas
  final String? responsibleQuery;
  final DateTime? fromDate;
  final DateTime? toDate;

  const TransferFilter({
    this.status = TransferStatus.pending,
    this.proposedWarehouse,
    this.responsibleQuery,
    this.fromDate,
    this.toDate,
  });

  TransferFilter copyWith({
    TransferStatus? status,
    String? proposedWarehouse,
    String? responsibleQuery,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return TransferFilter(
      status: status ?? this.status,
      proposedWarehouse: proposedWarehouse,
      responsibleQuery: responsibleQuery ?? this.responsibleQuery,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}