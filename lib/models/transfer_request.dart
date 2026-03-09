import 'package:json_annotation/json_annotation.dart';

// Es fundamental que esta línea coincida exactamente con el nombre de tu archivo
part 'transfer_request.g.dart'; 

// Mapeamos tu enum local a los valores exactos (Strings) que espera y devuelve Spring Boot
enum TransferStatus { 
  @JsonValue('pe') pending, 
  @JsonValue('ap') approved, 
  @JsonValue('na') rejected, 
  @JsonValue('pr') completed 
}

@JsonSerializable()
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

  // Mantenemos tu método copyWith intacto. Es una excelente práctica para inmutabilidad.
  TransferRequest copyWith({
  TransferStatus? status,
  String? rejectionReason,
  DateTime? appliedDate,
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
      appliedDate: appliedDate ?? this.appliedDate,
    );
  }

  // Sustituimos tu antiguo toMap() por la generación automática
  factory TransferRequest.fromJson(Map<String, dynamic> json) => 
      _$TransferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransferRequestToJson(this);
}