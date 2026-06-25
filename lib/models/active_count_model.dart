class ActiveCountModel {
  final String id; // ID del Conteo Físico
  final String warehouseId;
  final DateTime syncDate;
  final bool isCompleted;

  ActiveCountModel({
    required this.id,
    required this.warehouseId,
    required this.syncDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'syncDate': syncDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory ActiveCountModel.fromMap(Map<String, dynamic> map) {
    return ActiveCountModel(
      id: map['id'],
      warehouseId: map['warehouseId'],
      syncDate: DateTime.parse(map['syncDate']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
