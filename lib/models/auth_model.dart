import 'package:equatable/equatable.dart';

enum AppPermission {
  verificacionActivos('avac'),
  generacionQr('agqr'),
  generarTraspaso('agst'),
  aprobacionTraspaso('aatr'),
  aperturaConteo('aacf'),
  asignacionConteo('aacu'),
  realizarConteo('arcf'),
  sincronizarConteo('asin'),
  cerrarConteo('accf'),
  requisiciones('areq'),
  entregaInventario('aein');

  final String code;
  const AppPermission(this.code);

  static AppPermission? fromCode(String code) {
    try {
      return AppPermission.values.firstWhere((e) => e.code == code);
    } catch (_) {
      return null;
    }
  }
}

class Permiso extends Equatable {
  final String? usuario;
  final String? forma;
  final String? tipoRol;
  final String? tipoForma;
  final String? producto;

  const Permiso({
    this.usuario,
    this.forma,
    this.tipoRol,
    this.tipoForma,
    this.producto,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
      usuario: json['usuario'] as String?,
      forma: json['forma'] as String?,
      tipoRol: json['tipoRol'] as String?,
      tipoForma: json['tipoForma'] as String?,
      producto: json['producto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario': usuario,
      'forma': forma,
      'tipoRol': tipoRol,
      'tipoForma': tipoForma,
      'producto': producto,
    };
  }

  @override
  List<Object?> get props => [usuario, forma, tipoRol, tipoForma, producto];
}

class LoginRequest extends Equatable {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }

  @override
  List<Object?> get props => [username, password];
}

class LoginContadorRequest extends Equatable {
  final String documento;
  final String codigoTemporal;

  const LoginContadorRequest({
    required this.documento,
    required this.codigoTemporal,
  });

  Map<String, dynamic> toJson() {
    return {'documento': documento, 'codigoTemporal': codigoTemporal};
  }

  @override
  List<Object?> get props => [documento, codigoTemporal];
}

class AuthResponse extends Equatable {
  final String token;
  final String? refreshToken;
  final String? type;
  final String? username;
  final int? expiresIn;
  final List<Permiso>? permisos;

  const AuthResponse({
    required this.token,
    this.refreshToken,
    this.type,
    this.username,
    this.expiresIn,
    this.permisos,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: (json['token'] ?? json['accessToken'] ?? '') as String,
      refreshToken: json['refreshToken'] as String?,
      type: json['type'] as String?,
      username: json['username'] as String?,
      expiresIn: json['expiresIn'] as int?,
      permisos: json['permisos'] != null
          ? (json['permisos'] as List)
              .map((e) => Permiso.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, type, username, expiresIn, permisos];
}
