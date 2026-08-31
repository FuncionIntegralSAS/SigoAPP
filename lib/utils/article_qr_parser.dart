import '../models/article_model.dart';

class ArticleQrParser {
  static ArticleModel fromQr(String qrData) {
    final parts = qrData.split('|');

    final map = <String, String>{};
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        map[kv[0]] = kv[1];
      }
    }

    return ArticleModel(
      codigoActivo: map['Código'] ?? map['ID'] ?? '',
      nombre: map['Nombre'] ?? map['NAME'] ?? '',
      placa: map['Placa'] ?? map['PLATE'] ?? '',
      bodega: map['Bodega'] ?? map['WH'] ?? '',
      responsable: (map['RESP'] == 'N/A' || map['Responsable'] == 'N/A')
          ? null
          : (map['Responsable'] ?? map['RESP']),
      latitud: map['Lat'] != null && map['Lat'] != 'No disp.'
          ? double.tryParse(map['Lat']!)
          : (map['LAT'] != null && map['LAT'] != 'No disp.'
              ? double.tryParse(map['LAT']!)
              : null),
      longitud: map['Lon'] != null && map['Lon'] != 'No disp.'
          ? double.tryParse(map['Lon']!)
          : (map['LON'] != null && map['LON'] != 'No disp.'
              ? double.tryParse(map['LON']!)
              : null),
    );
  }
}
