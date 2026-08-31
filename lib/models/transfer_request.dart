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
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'idArticulo')
  final String idArticulo;
  @JsonKey(name: 'nombreArticulo')
  final String nombreArticulo;
  @JsonKey(name: 'responsableActual')
  final String responsableActual;  
  @JsonKey(name: 'responsablePropuesto')
  final String responsablePropuesto;
  @JsonKey(name: 'bodegaActual')
  final String bodegaActual;
  @JsonKey(name: 'bodegaPropuesta')
  final String bodegaPropuesta;
  @JsonKey(name: 'motivoSolicitud')
  final String motivoSolicitud;
  @JsonKey(name: 'fechaSolicitud')
  final DateTime fechaSolicitud;
  @JsonKey(name: 'fechaAplicacion')
  final DateTime? fechaAplicacion;
  @JsonKey(name: 'status')
  final TransferStatus estado;
  @JsonKey(name: 'motivoRechazo')
  final String? motivoRechazo;
  @JsonKey(name: 'firmaDespachadorBase64')
  final String? firmaDespachadorBase64;
  @JsonKey(name: 'firmaReceptorBase64')
  final String? firmaReceptorBase64;

  TransferRequest({
    required this.id,
    required this.idArticulo,
    required this.nombreArticulo,
    required this.responsableActual,
    required this.responsablePropuesto,
    required this.motivoSolicitud,
    required this.fechaSolicitud,
    required this.bodegaActual,
    required this.bodegaPropuesta,
    this.estado = TransferStatus.pending,
    this.motivoRechazo,
    this.fechaAplicacion,
    this.firmaDespachadorBase64,
    this.firmaReceptorBase64,
  });

  // Mantenemos tu método copyWith intacto. Es una excelente práctica para inmutabilidad.
  TransferRequest copyWith({
  TransferStatus? estado,
  String? motivoRechazo,
  DateTime? fechaAplicacion,
  String? firmaDespachadorBase64,
  String? firmaReceptorBase64,
  }) {
    return TransferRequest(
      id: id,
      idArticulo: idArticulo,
      nombreArticulo: nombreArticulo,
      responsableActual: responsableActual,
      responsablePropuesto: responsablePropuesto,
      bodegaActual: bodegaActual,
      bodegaPropuesta: bodegaPropuesta,
      motivoSolicitud: motivoSolicitud,
      fechaSolicitud: fechaSolicitud,
      estado: estado ?? this.estado,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      firmaDespachadorBase64: firmaDespachadorBase64 ?? this.firmaDespachadorBase64,
      firmaReceptorBase64: firmaReceptorBase64 ?? this.firmaReceptorBase64,
    );
  }

  // Sustituimos tu antiguo toMap() por la generación automática
  factory TransferRequest.fromJson(Map<String, dynamic> json) => 
      _$TransferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransferRequestToJson(this);
}