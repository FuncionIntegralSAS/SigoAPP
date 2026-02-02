import 'package:flutter/material.dart';
import 'package:sigo_app/repositories/mock_transfer_repository.dart';

// Providers
import 'providers/transfer_request_provider.dart';
import 'providers/transfer_approval_provider.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/asset_verification_provider.dart';

// Services
import 'services/mock_inventory_service.dart';
import 'services/mock_auth_service.dart';

// Screens
import 'screens/auth_screen.dart';
import 'package:sigo_app/screens/dashboard_screen.dart';

void main() {
  final inventoryService = MockInventoryService();
  final transferRepository = MockTransferRepository(inventoryService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransferRequestProvider(transferRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferApprovalProvider(transferRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AssetVerificationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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