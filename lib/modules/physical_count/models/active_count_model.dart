class ActiveCountModel {
  final String id; // ID del Conteo Físico
  final String idBodega;
  final DateTime fechaSincronizacion;
  final bool estaCompletado;

  ActiveCountModel({
    required this.id,
    required this.idBodega,
    required this.fechaSincronizacion,
    this.estaCompletado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouseId': idBodega,
      'syncDate': fechaSincronizacion.toIso8601String(),
      'isCompleted': estaCompletado ? 1 : 0,
    };
  }

  factory ActiveCountModel.fromMap(Map<String, dynamic> map) {
    return ActiveCountModel(
      id: map['id']?.toString() ?? '',
      idBodega: (map['warehouseId'] ?? map['idBodega'])?.toString() ?? '',
      fechaSincronizacion: DateTime.parse((map['syncDate'] ?? map['fechaSincronizacion']).toString()),
      estaCompletado: (map['isCompleted'] ?? map['estaCompletado']) == 1 || (map['isCompleted'] ?? map['estaCompletado']) == true,
    );
  }
}
