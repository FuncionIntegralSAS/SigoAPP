import 'package:flutter/material.dart';
import 'package:sigo_app/repositories/mock_transfer_repository.dart';
import 'package:sigo_app/services/in_app_notification_service.dart';
import 'package:sigo_app/services/notification_service.dart';

// Providers
import 'providers/transfer_request_provider.dart';
import 'providers/transfer_approval_provider.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/asset_verification_provider.dart';

// Nuevos imports para el módulo de Requisiciones
import 'package:sigo_app/providers/requisition_approval_provider.dart';
import 'package:sigo_app/services/mock_requisition_service.dart';

// Nuevos imports para el módulo de Conteo Físico
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/services/physical_count_service.dart';

// Services
import 'services/mock_inventory_service.dart';
import 'services/mock_auth_service.dart';

// Screens
import 'screens/auth_screen.dart';
import 'package:sigo_app/screens/dashboard_screen.dart';

void main() {
  final inventoryService = MockInventoryService();
  final transferRepository = MockTransferRepository(inventoryService);
  
  // Instanciamos el servicio mock de requisiciones
  final requisitionService = MockRequisitionService();

  // Instanciamos el servicio de Conteo Físico
  final physicalCountService = PhysicalCountService();

  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final notificationService = InAppNotificationService(messengerKey);

  runApp(
    MultiProvider(
      providers: [
        // 🔔 Servicio de notificaciones (singleton)
        Provider<NotificationService>.value(
          value: notificationService,
        ),

        // 📦 Providers de dominio
        ChangeNotifierProvider(
          create: (_) => TransferRequestProvider(
            transferRepository,
            notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferApprovalProvider(transferRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AssetVerificationProvider(),
        ),
        
        // Registramos el nuevo Provider de Requisiciones
        ChangeNotifierProvider(
          create: (_) => RequisitionApprovalProvider(requisitionService),
        ),
        
        // Registramos el nuevo Provider de Conteo Físico
        ChangeNotifierProvider(
          create: (_) => PhysicalCountProvider(physicalCountService),
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
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
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