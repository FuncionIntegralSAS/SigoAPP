import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'account_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Mock login controllers
  final TextEditingController _mockEmailController = TextEditingController(
    text: 'operador@inventario.com',
  );
  final TextEditingController _mockPasswordController = TextEditingController(
    text: '123456',
  );

  // Real login controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color primaryColor = Colors.orange.shade700;
  final Color mockColor = Colors.blueGrey.shade700;

  void _handleRealLogin() async {
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.login(email, password);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Credenciales inválidas.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMockLogin() async {
    final authProvider = context.read<AuthProvider>();
    final email = _mockEmailController.text.trim();
    final password = _mockPasswordController.text;

    final success = await authProvider.mockLogin(email, password);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Credenciales inválidas.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final mockForm = _buildMockLoginForm();
                final realForm = _buildRealLoginForm();

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!kReleaseMode) ...[
                        _buildCard(mockForm),
                        const SizedBox(width: 32),
                      ],
                      _buildCard(realForm),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      if (!kReleaseMode) ...[
                        _buildCard(mockForm),
                        const SizedBox(height: 32),
                      ],
                      _buildCard(realForm),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400),
      child: child,
    );
  }

  Widget _buildRealLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(Icons.lock_open, size: 80, color: primaryColor),
        const SizedBox(height: 10),
        Text(
          'Bienvenido a SIGAPP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Conexión directa al API',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Usuario',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          enabled: !context.watch<AuthProvider>().isLoading,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          enabled: !context.watch<AuthProvider>().isLoading,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: context.watch<AuthProvider>().isLoading
              ? null
              : _handleRealLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: context.watch<AuthProvider>().isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'INICIAR SESIÓN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 10),
        const Divider(),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            );
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Acceso para Contadores (Conteo Físico)'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
        ),
      ],
    );
  }

  Widget _buildMockLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(Icons.build_circle, size: 80, color: mockColor),
        const SizedBox(height: 10),
        Text(
          'Entorno de Pruebas (Mock)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: mockColor,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Simulación local (sin backend)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _mockEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Usuario Mock',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          enabled: !context.watch<AuthProvider>().isLoading,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _mockPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Contraseña Mock',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          enabled: !context.watch<AuthProvider>().isLoading,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: context.watch<AuthProvider>().isLoading
              ? null
              : _handleMockLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: mockColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: context.watch<AuthProvider>().isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'INICIAR SESIÓN MOCK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
