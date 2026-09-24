import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/auth/repositories/auth_repository.dart';
import 'package:sigo_app/utils/app_config.dart';
import 'package:sigo_app/utils/auth_utils.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthUtils.resetSemaphore();
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'Bearer test_token',
      'auth_username': 'test_user',
    });
  });

  group('AuthUtils Lifecycle and Concurrency', () {
    test('isLoggingOut debe iniciar en false', () {
      expect(AuthUtils.isLoggingOut, isFalse);
      expect(AuthUtils.isLoggingOutNotifier.value, isFalse);
    });

    test('resetSemaphore debe garantizar retorno a false', () {
      AuthUtils.isLoggingOutNotifier.value = true;
      expect(AuthUtils.isLoggingOut, isTrue);

      AuthUtils.resetSemaphore();
      expect(AuthUtils.isLoggingOut, isFalse);
    });

    testWidgets('logout debe completar y dejar el semáforo en false sin bloquearse', (tester) async {
      final fakeRepo = _FakeAuthRepository();
      final authProvider = AuthProvider(fakeRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            navigatorKey: AppConfig.navigatorKey,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AuthUtils.logout(context),
                child: const Text('Logout Button'),
              ),
            ),
          ),
        ),
      );

      // Verificamos estado inicial
      expect(AuthUtils.isLoggingOut, isFalse);

      // Ejecutamos logout
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Debe haber finalizado y el semáforo debe quedar libre en false
      expect(AuthUtils.isLoggingOut, isFalse);
      expect(authProvider.isAuthenticated, isFalse);

      // Un segundo llamado debe ejecutarse sin quedar bloqueado
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(AuthUtils.isLoggingOut, isFalse);
    });

    testWidgets('handleSessionExpired debe completar y dejar el semáforo en false', (tester) async {
      final fakeRepo = _FakeAuthRepository();
      final authProvider = AuthProvider(fakeRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            navigatorKey: AppConfig.navigatorKey,
            home: const Scaffold(body: Text('Test Body')),
          ),
        ),
      );

      await AuthUtils.handleSessionExpired();
      await tester.pumpAndSettle();

      expect(AuthUtils.isLoggingOut, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
    });
  });
}
