// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferRequest _$TransferRequestFromJson(Map<String, dynamic> json) =>
    TransferRequest(
      id: json['id'] as String,
      articleId: json['articleId'] as String,
      articleName: json['articleName'] as String,
      currentResponsible: json['currentResponsible'] as String,
      proposedResponsible: json['proposedResponsible'] as String,
      requestReason: json['requestReason'] as String,
      requestDate: DateTime.parse(json['requestDate'] as String),
      currentWarehouse: json['currentWarehouse'] as String,
      proposedWarehouse: json['proposedWarehouse'] as String,
      status:
          $enumDecodeNullable(_$TransferStatusEnumMap, json['status']) ??
          TransferStatus.pending,
      rejectionReason: json['rejectionReason'] as String?,
      appliedDate: json['appliedDate'] == null
          ? null
          : DateTime.parse(json['appliedDate'] as String),
    );

Map<String, dynamic> _$TransferRequestToJson(TransferRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'articleId': instance.articleId,
      'articleName': instance.articleName,
      'currentResponsible': instance.currentResponsible,
      'proposedResponsible': instance.proposedResponsible,
      'currentWarehouse': instance.currentWarehouse,
      'proposedWarehouse': instance.proposedWarehouse,
      'requestReason': instance.requestReason,
      'requestDate': instance.requestDate.toIso8601String(),
      'appliedDate': instance.appliedDate?.toIso8601String(),
      'status': _$TransferStatusEnumMap[instance.status]!,
      'rejectionReason': instance.rejectionReason,
    };

const _$TransferStatusEnumMap = {
  TransferStatus.pending: 'pe',
  TransferStatus.approved: 'ap',
  TransferStatus.rejected: 'na',
  TransferStatus.completed: 'pr',
};
