// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_delivery_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDeliveryRequest _$TransferDeliveryRequestFromJson(
  Map<String, dynamic> json,
) => TransferDeliveryRequest(
  transferId: json['transferId'] as String,
  firmaDespachadorBase64: json['firmaDespachadorBase64'] as String?,
  firmaReceptorBase64: json['firmaReceptorBase64'] as String?,
);

Map<String, dynamic> _$TransferDeliveryRequestToJson(
  TransferDeliveryRequest instance,
) => <String, dynamic>{
  'transferId': instance.transferId,
  'firmaDespachadorBase64': instance.firmaDespachadorBase64,
  'firmaReceptorBase64': instance.firmaReceptorBase64,
};
