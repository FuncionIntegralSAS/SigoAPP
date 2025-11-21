// Modelo de datos para una Bodega o Centro de Costos
class WarehouseModel {
  final String id; // ID que se usará para filtrar los artículos
  final String name;

  const WarehouseModel({
    required this.id,
    required this.name,
  });
}