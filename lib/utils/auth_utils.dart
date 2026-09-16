import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'app_config.dart';
import 'app_logger.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/transfer_form_provider.dart';
import '../providers/transfer_approval_provider.dart';
import '../providers/transfer_delivery_provider.dart';
import '../providers/physical_count_provider.dart';
import '../providers/active_count_provider.dart';
import '../providers/requisition_approval_provider.dart';
import '../providers/asset_verification_provider.dart';
import '../main.dart';

/// Utilidades transversales de autenticación, sesión y navegación en SigoAPP.
class AuthUtils {
  AuthUtils._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final ValueNotifier<bool> isLoggingOutNotifier = ValueNotifier<bool>(false);

  /// Indica si actualmente se está ejecutando un proceso de logout (manual o forzado).
  static bool get isLoggingOut => isLoggingOutNotifier.value;

  static void _setLoggingOut(bool value) {
    if (isLoggingOutNotifier.value != value) {
      isLoggingOutNotifier.value = value;
    }
  }

  /// Permite resetear manualmente el semáforo en pruebas o recuperaciones de excepción.
  @visibleForTesting
  static void resetSemaphore() {
    _setLoggingOut(false);
  }

  /// Cierra la sesión activa en [AuthProvider], limpia todos los estados en memoria
  /// de los Providers y vacía por completo la pila de navegación redirigiendo a la
  /// pantalla raíz ([AuthWrapper]), garantizando que ninguna pantalla hija permanezca activa.
  static Future<void> logout(BuildContext context) async {
    if (isLoggingOut) return;
    _setLoggingOut(true);

    try {
      AppLogger.i('AuthUtils: Iniciando cierre de sesión manual por el usuario.');

      final effectiveContext = context.mounted
          ? context
          : AppConfig.navigatorKey.currentContext;

      if (effectiveContext != null && effectiveContext.mounted) {
        final authProvider = Provider.of<AuthProvider>(effectiveContext, listen: false);
        _resetProviders(effectiveContext);
        await authProvider.logout();
      } else {
        await _clearSecureStorage();
      }

      final navigator = AppConfig.navigatorKey.currentState ??
          (context.mounted ? Navigator.of(context, rootNavigator: true) : null);

      if (navigator != null) {
        // NOTA CRÍTICA: NO hacer `await` a pushAndRemoveUntil porque retorna newRoute.popped,
        // que solo se resuelve cuando la pantalla de destino es destruida o desapilada.
        // Dado que la pantalla de destino es la raíz (AuthWrapper), jamás se desapilaría,
        // congelando la ejecución y dejando el semáforo bloqueado en true para siempre.
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      AppLogger.e('AuthUtils: Error durante el logout manual', e);
    } finally {
      _setLoggingOut(false);
    }
  }

  /// Maneja de forma centralizada la expiración de sesión (HTTP 401).
  ///
  /// Se ejecuta desacoplado de un [BuildContext] específico mediante [AppConfig.navigatorKey]
  /// y [AppConfig.scaffoldMessengerKey]. Implementa control de concurrencia para evitar
  /// tormentas de ejecuciones repetidas si fallan múltiples peticiones simultáneamente.
  static Future<void> handleSessionExpired() async {
    if (isLoggingOut) {
      AppLogger.d('AuthUtils: Proceso de logout ya en ejecución. Ignorando 401 concurrente.');
      return;
    }
    _setLoggingOut(true);

    try {
      AppLogger.w('AuthUtils: Sesión expirada detectada (401). Iniciando expulsión controlada.');

      // 1. Mostrar notificación informativa formal al usuario
      final messengerState = AppConfig.scaffoldMessengerKey.currentState;
      if (messengerState != null) {
        messengerState.removeCurrentSnackBar();
        messengerState.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.timer_off_outlined, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // 2. Limpiar AuthProvider y demás providers globales
      final context = AppConfig.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _resetProviders(context);
        try {
          await authProvider.logout();
        } catch (e) {
          AppLogger.e('AuthUtils: Error al limpiar AuthProvider desde context', e);
          await _clearSecureStorage();
        }
      } else {
        await _clearSecureStorage();
      }

      // 3. Redirigir a AuthWrapper vaciando la pila de navegación
      final navigatorState = AppConfig.navigatorKey.currentState;
      if (navigatorState != null) {
        // NOTA CRÍTICA: NO hacer `await` a pushAndRemoveUntil para evitar congelar el finally
        navigatorState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      AppLogger.e('AuthUtils: Error durante handleSessionExpired', e);
    } finally {
      _setLoggingOut(false);
    }
  }

  /// Borra directamente las credenciales y tokens de [FlutterSecureStorage].
  static Future<void> _clearSecureStorage() async {
    try {
      await Future.wait([
        _storage.delete(key: 'auth_token'),
        _storage.delete(key: 'auth_cedula'),
        _storage.delete(key: 'auth_username'),
        _storage.delete(key: 'auth_refresh_token'),
        _storage.delete(key: 'auth_permissions'),
      ]).timeout(const Duration(seconds: 2));
    } catch (e) {
      AppLogger.e('AuthUtils: Error o timeout al limpiar credenciales en secure storage', e);
    }
  }

  /// Limpia los datos de sesión y formularios en los Providers globales.
  static void _resetProviders(BuildContext context) {
    try {
      Provider.of<InventoryProvider>(context, listen: false).resetForm();
    } catch (_) {}
    try {
      Provider.of<TransferFormProvider>(context, listen: false).resetForm();
    } catch (_) {}
    try {
      Provider.of<TransferApprovalProvider>(context, listen: false).reset();
    } catch (_) {}
    try {
      Provider.of<TransferDeliveryProvider>(context, listen: false).reset();
    } catch (_) {}
    try {
      Provider.of<PhysicalCountProvider>(context, listen: false).resetForm();
    } catch (_) {}
    try {
      Provider.of<ActiveCountProvider>(context, listen: false).resetState();
    } catch (_) {}
    try {
      Provider.of<RequisitionApprovalProvider>(context, listen: false).reset();
    } catch (_) {}
    try {
      Provider.of<AssetVerificationProvider>(context, listen: false).reset();
    } catch (_) {}
  }
}
