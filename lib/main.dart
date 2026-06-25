import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:sigo_app/repositories/mock_transfer_repository.dart';
import 'package:sigo_app/services/in_app_notification_service.dart';
import 'package:sigo_app/services/notification_service.dart';

// Providers
import 'providers/transfer_request_provider.dart';
import 'providers/transfer_approval_provider.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/asset_verification_provider.dart';

// Imports para el módulo de Requisiciones
import 'package:sigo_app/providers/requisition_approval_provider.dart';
import 'package:sigo_app/services/mock_requisition_service.dart';

// Imports para el módulo de Conteo Físico
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/providers/active_count_provider.dart';
import 'package:sigo_app/services/physical_count_service.dart';
import 'package:dio/dio.dart';

// Services
import 'services/mock_inventory_service.dart';
import 'services/mock_auth_service.dart';

// Screens
import 'screens/auth_screen.dart';
import 'package:sigo_app/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final inventoryService = MockInventoryService();
  final transferRepository = MockTransferRepository(inventoryService);

  // Instanciamos el servicio mock de requisiciones
  final requisitionService = MockRequisitionService();

  // Instanciamos el servicio de Conteo Físico con Dio
  final backendDio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_URL'] ?? 'https://api.tu-servidor.com',
    ),
  );

  final physicalCountService = PhysicalCountService(backendDio);

  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final notificationService = InAppNotificationService(messengerKey);
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    MultiProvider(
      providers: [
        // Servicio de notificaciones (singleton)
        Provider<NotificationService>.value(value: notificationService),

        // Providers de dominio
        ChangeNotifierProvider(
          create: (_) =>
              TransferRequestProvider(transferRepository, notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferApprovalProvider(transferRepository),
        ),
        ChangeNotifierProvider(create: (_) => AssetVerificationProvider()),

        // Registramos el nuevo Provider de Requisiciones
        ChangeNotifierProvider(
          create: (_) => RequisitionApprovalProvider(requisitionService),
        ),

        // Registramos el nuevo Provider de Conteo Físico (Apertura)
        ChangeNotifierProvider(
          create: (_) => PhysicalCountProvider(physicalCountService),
        ),

        // Provider local offline para la Ejecución del Conteo Físico (Piso)
        ChangeNotifierProvider(create: (_) => ActiveCountProvider()),
      ],
      child: MyApp(messengerKey),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  const MyApp(this.messengerKey, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Gestión Administrativa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      scaffoldMessengerKey: messengerKey,
    );
  }
}

// Wrapper de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: MockAuthService.instance.currentUser,
      builder: (context, user, child) {
        if (user != null) {
          return const DashboardScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
