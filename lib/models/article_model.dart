// Modelo de datos para un Artículo o Activo
class ArticleModel {
  final String code;
  final String licensePlate; // Placa
  final String name;
  final String responsible; // Responsable
  final String costCenter; // Centro de Costos / Bodega ID

  ArticleModel({
    required this.code,
    required this.licensePlate,
    required this.name,
    required this.responsible,
    required this.costCenter,
  });

  // Método que genera la cadena que se codificará en el QR
  // Usamos el código y la placa como datos de identificación
  String get qrData {
    return 'Código:$code|Placa:$licensePlate|Nombre:$name';
  }
  
  // Opcional: Para poder imprimir el objeto en la consola
  @override
  String toString() {
    return 'ArticleModel(Code: $code, Plate: $licensePlate, Name: $name)';
  }
}