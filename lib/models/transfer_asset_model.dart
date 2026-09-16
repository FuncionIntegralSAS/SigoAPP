import 'package:equatable/equatable.dart';
import 'transfer_request.dart';

/// Modelo que representa un activo asignado a un colaborador
/// obtenido del endpoint `GET /api/v1/traspasos/activos`.
class TransferAssetModel extends Equatable {
  final String articulo;
  final String? placa;
  final String nombre;
  final String? centroInformacion;
  final String? tercero;
  final bool enTramite;

  const TransferAssetModel({
    required this.articulo,
    this.placa,
    required this.nombre,
    this.centroInformacion,
    this.tercero,
    this.enTramite = false,
  });

  factory TransferAssetModel.fromJson(Map<String, dynamic> json) {
    return TransferAssetModel(
      articulo: (json['articulo'] ?? json['idArticulo'] ?? json['codigo'] ?? '').toString().trim(),
      placa: json['placa']?.toString().trim(),
      nombre: (json['nombre'] ?? json['descripcion'] ?? '').toString().trim(),
      centroInformacion: json['centroInformacion']?.toString().trim(),
      tercero: json['tercero']?.toString().trim(),
      enTramite: json['enTramite'] == true ||
          json['enTramite'] == 1 ||
          json['enTramite']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
        'articulo': articulo,
        if (placa != null) 'placa': placa,
        'nombre': nombre,
        if (centroInformacion != null) 'centroInformacion': centroInformacion,
        if (tercero != null) 'tercero': tercero,
        'enTramite': enTramite,
      };

  /// Convierte este modelo al ítem requerido por el trámite de traspaso.
  TransferArticleItem toTransferArticleItem() {
    return TransferArticleItem(
      articulo: articulo,
      placa: placa,
      nombre: nombre,
    );
  }

  @override
  List<Object?> get props => [
        articulo,
        placa,
        nombre,
        centroInformacion,
        tercero,
        enTramite,
      ];

  @override
  String toString() => '$nombre [$articulo] (CI: $centroInformacion, Tercero: $tercero, enTramite: $enTramite)';
}
