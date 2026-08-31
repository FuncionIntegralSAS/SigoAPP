// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferRequest _$TransferRequestFromJson(Map<String, dynamic> json) =>
    TransferRequest(
      id: json['id'] as String,
      idArticulo: json['idArticulo'] as String,
      nombreArticulo: json['nombreArticulo'] as String,
      responsableActual: json['responsableActual'] as String,
      responsablePropuesto: json['responsablePropuesto'] as String,
      motivoSolicitud: json['motivoSolicitud'] as String,
      fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      bodegaActual: json['bodegaActual'] as String,
      bodegaPropuesta: json['bodegaPropuesta'] as String,
      estado:
          $enumDecodeNullable(_$TransferStatusEnumMap, json['status']) ??
          TransferStatus.pending,
      motivoRechazo: json['motivoRechazo'] as String?,
      fechaAplicacion: json['fechaAplicacion'] == null
          ? null
          : DateTime.parse(json['fechaAplicacion'] as String),
      firmaDespachadorBase64: json['firmaDespachadorBase64'] as String?,
      firmaReceptorBase64: json['firmaReceptorBase64'] as String?,
    );

Map<String, dynamic> _$TransferRequestToJson(TransferRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'idArticulo': instance.idArticulo,
      'nombreArticulo': instance.nombreArticulo,
      'responsableActual': instance.responsableActual,
      'responsablePropuesto': instance.responsablePropuesto,
      'bodegaActual': instance.bodegaActual,
      'bodegaPropuesta': instance.bodegaPropuesta,
      'motivoSolicitud': instance.motivoSolicitud,
      'fechaSolicitud': instance.fechaSolicitud.toIso8601String(),
      'fechaAplicacion': instance.fechaAplicacion?.toIso8601String(),
      'status': _$TransferStatusEnumMap[instance.estado]!,
      'motivoRechazo': instance.motivoRechazo,
      'firmaDespachadorBase64': instance.firmaDespachadorBase64,
      'firmaReceptorBase64': instance.firmaReceptorBase64,
    };

const _$TransferStatusEnumMap = {
  TransferStatus.pending: 'pe',
  TransferStatus.approved: 'ap',
  TransferStatus.rejected: 'na',
  TransferStatus.completed: 'pr',
};
