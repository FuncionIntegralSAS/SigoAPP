import 'package:json_annotation/json_annotation.dart';

part 'transfer_delivery_request.g.dart';

@JsonSerializable()
class TransferDeliveryRequest {
  final String transferId;
  final String? dispatcherSignatureBase64;
  final String? receiverSignatureBase64;

  TransferDeliveryRequest({
    required this.transferId,
    this.dispatcherSignatureBase64,
    this.receiverSignatureBase64,
  });

  factory TransferDeliveryRequest.fromJson(Map<String, dynamic> json) => 
      _$TransferDeliveryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransferDeliveryRequestToJson(this);
}
