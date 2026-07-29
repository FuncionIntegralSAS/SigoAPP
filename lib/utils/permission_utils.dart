import 'dart:convert';
import '../models/auth_model.dart';

class PermissionUtils {
  /// Deserializa la cadena JSON almacenada a una lista de permisos
  static List<Permiso> parsePermissions(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Permiso.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Serializa la lista de permisos a JSON para almacenarla
  static String encodePermissions(List<Permiso> permissions) {
    return jsonEncode(permissions.map((e) => e.toJson()).toList());
  }
}

/// Extensión para facilitar la verificación de permisos directamente sobre la lista
extension PermissionListExtension on List<Permiso> {
  bool hasPermission(AppPermission permission) {
    return any((p) => p.forma?.toLowerCase() == permission.code.toLowerCase());
  }

  bool hasAnyPermission(List<AppPermission> permissions) {
    for (var perm in permissions) {
      if (hasPermission(perm)) return true;
    }
    return false;
  }
}
