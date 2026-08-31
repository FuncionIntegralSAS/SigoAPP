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
import 'providers/transfer_delivery_provider.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/asset_verification_provider.dart';

// Imports para el módulo de Requisiciones
import 'package:sigo_app/providers/requisition_approval_provider.dart';
import 'package:sigo_app/services/mock_requisition_service.dart';

// Imports para el módulo de Conteo Físico
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/providers/active_count_provider.dart';
import 'package:sigo_app/repositories/http_physical_count_repository.dart';
import 'package:sigo_app/repositories/http_catalog_repository.dart';
import 'package:sigo_app/providers/auth_provider.dart';
import 'package:sigo_app/providers/transfer_form_provider.dart';
import 'package:sigo_app/providers/printer_provider.dart';
import 'package:sigo_app/repositories/http_auth_repository.dart';
import 'package:sigo_app/utils/app_config.dart';
import 'package:sigo_app/repositories/http_geolocation_repository.dart';
import 'package:sigo_app/providers/geolocation_provider.dart';

// Services
import 'services/mock_inventory_service.dart';

// Screens
import 'screens/auth_screen.dart';
import 'package:sigo_app/screens/dashboard_screen.dart';
import 'package:sigo_app/screens/domain_scanner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Inicializamos la configuración de la app (ej. cargar dominio guardado)
  await AppConfig.init();

  final inventoryService = MockInventoryService();
  final transferRepository = MockTransferRepository(inventoryService);

  // Instanciamos el servicio mock de requisiciones
  final requisitionService = MockRequisitionService();

  // Instancia centralizada de Dio con configuración de producción
  final backendDio = AppConfig.createDio();

  final physicalCountRepository = HttpPhysicalCountRepository(backendDio);

  // Repositorio de catálogos para el formulario de traspasos
  final catalogRepository = HttpCatalogRepository(backendDio);

  // Inyectamos el mismo Dio al repositorio de autenticación
  final authRepository = HttpAuthRepository(backendDio);

  // Inyectamos Dio al repositorio de geolocalización
  final geolocationRepository = HttpGeolocationRepository(backendDio);

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
        ChangeNotifierProvider(
          create: (_) => TransferDeliveryProvider(transferRepository),
        ),
        ChangeNotifierProvider(create: (_) => AssetVerificationProvider()),

        // Provider del formulario de creación de traspasos (carga en cascada)
        ChangeNotifierProvider(
          create: (_) => TransferFormProvider(catalogRepository),
        ),

        // Registramos el nuevo Provider de Requisiciones
        ChangeNotifierProvider(
          create: (_) => RequisitionApprovalProvider(requisitionService),
        ),

        // Registramos el nuevo Provider de Conteo Físico (Apertura)
        ChangeNotifierProvider(
          create: (_) => PhysicalCountProvider(physicalCountRepository),
        ),

        // Provider local offline para la Ejecución del Conteo Físico (Piso)
        ChangeNotifierProvider(
          create: (_) => ActiveCountProvider(physicalCountRepository),
        ),

        // Provider para el login alterno y descarga offline de contadores
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),

        // Provider para impresión por Bluetooth
        ChangeNotifierProvider(create: (_) => PrinterProvider()),

        // Provider de geolocalización
        ChangeNotifierProvider(
          create: (_) => GeolocationProvider(geolocationRepository),
        ),
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
    return ValueListenableBuilder<bool>(
      valueListenable: AppConfig.domainConfiguredNotifier,
      builder: (context, hasDomain, child) {
        if (!hasDomain) {
          return const DomainScannerScreen();
        }

        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isAuthenticated &&
                authProvider.currentCedula == null) {
              // Si está autenticado y no es un contador (no tiene cédula), va al dashboard
              return const DashboardScreen();
            } else {
              return const AuthScreen();
            }
          },
        );
      },
    );
  }
}
