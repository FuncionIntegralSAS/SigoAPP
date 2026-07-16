import 'package:equatable/equatable.dart';

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

  const AuthResponse({
    required this.token,
    this.refreshToken,
    this.type,
    this.username,
    this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: (json['token'] ?? json['accessToken'] ?? '') as String,
      refreshToken: json['refreshToken'] as String?,
      type: json['type'] as String?,
      username: json['username'] as String?,
      expiresIn: json['expiresIn'] as int?,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, type, username, expiresIn];
}
