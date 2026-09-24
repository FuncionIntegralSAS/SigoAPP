import 'package:sigo_app/modules/inventory/models/transfer_request.dart';

/// Payload requerido para la creación de un nuevo trámite de traspaso
/// en `POST /api/v1/traspasos/crear` con soporte multi-artículo.
class TransferCreateRequest {
  final String empresa;
  final String personaFuente;
  final String personaDestino;
  final List<TransferArticleItem> articulos;
  final String observacion;
  final String? tipoMovimiento;
  final String? bodegaOrigen;
  final String? bodegaDestino;

  TransferCreateRequest({
    required this.empresa,
    required this.personaFuente,
    required this.personaDestino,
    required this.articulos,
    required this.observacion,
    this.tipoMovimiento,
    this.bodegaOrigen,
    this.bodegaDestino,
  });

  factory TransferCreateRequest.fromJson(Map<String, dynamic> json) {
    List<TransferArticleItem> items = [];
    if (json['articulos'] is List) {
      items = (json['articulos'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => TransferArticleItem.fromJson(a))
          .toList();
    } else if (json['elemento'] != null) {
      items = [
        TransferArticleItem(
          articulo: json['elemento'].toString(),
          placa: json['placa']?.toString(),
        )
      ];
    }

    return TransferCreateRequest(
      empresa: (json['empresa'] ?? '01').toString(),
      personaFuente: (json['personaFuente'] ?? '').toString(),
      personaDestino: (json['personaDestino'] ?? '').toString(),
      articulos: items,
      observacion: (json['observacion'] ?? '').toString(),
      tipoMovimiento: json['tipoMovimiento']?.toString(),
      bodegaOrigen: (json['bodegaOrigen'] ??
              json['bodegaFuente'] ??
              json['bodegaActual'] ??
              json['bodega'])
          ?.toString(),
      bodegaDestino: (json['bodegaDestino'] ?? json['bodegaPropuesta'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'empresa': empresa,
        'personaFuente': personaFuente,
        'personaDestino': personaDestino,
        'articulos': articulos.map((a) => a.toJson()).toList(),
        'observacion': observacion,
        if (tipoMovimiento != null) 'tipoMovimiento': tipoMovimiento,
      };
}
