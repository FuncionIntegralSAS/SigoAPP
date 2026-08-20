// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_delivery_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDeliveryRequest _$TransferDeliveryRequestFromJson(
  Map<String, dynamic> json,
) => TransferDeliveryRequest(
  transferId: json['transferId'] as String,
  dispatcherSignatureBase64: json['dispatcherSignatureBase64'] as String?,
  receiverSignatureBase64: json['receiverSignatureBase64'] as String?,
);

Map<String, dynamic> _$TransferDeliveryRequestToJson(
  TransferDeliveryRequest instance,
) => <String, dynamic>{
  'transferId': instance.transferId,
  'dispatcherSignatureBase64': instance.dispatcherSignatureBase64,
  'receiverSignatureBase64': instance.receiverSignatureBase64,
};
