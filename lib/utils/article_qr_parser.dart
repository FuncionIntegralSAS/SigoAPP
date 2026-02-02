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
      id: map['ID'] ?? '',
      name: map['NAME'] ?? '',
      licensePlate: map['PLATE'] ?? '',
      warehouse: map['WH'] ?? '',
      responsible: map['RESP'] == 'N/A' ? null : map['RESP'],
      latitude: map['LAT'] != null && map['LAT'] != 'No disp.'
          ? double.tryParse(map['LAT']!)
          : null,
      longitude: map['LON'] != null && map['LON'] != 'No disp.'
          ? double.tryParse(map['LON']!)
          : null,
    );
  }
}
