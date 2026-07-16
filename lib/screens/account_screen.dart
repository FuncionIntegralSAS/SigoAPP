import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/active_count_provider.dart';
import 'active_count_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final Color primaryColor = Colors.blue.shade800;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.currentCedula != null) {
        context.read<ActiveCountProvider>().loadLocalActiveCount(auth.currentCedula!);
      }
    });
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, AuthProvider authProvider) async {
    final cedula = _cedulaController.text.trim();
    final codigo = _codigoController.text.trim();

    if (cedula.isEmpty || codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu cédula y código temporal.'),
        ),
      );
      return;
    }

    final success = await authProvider.loginContador(cedula, codigo);
    if (!context.mounted) return;
    if (success) {
      context.read<ActiveCountProvider>().loadLocalActiveCount(cedula);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error al iniciar sesión'),
        ),
      );
    }
  }

  void _descargarPendientes(
    BuildContext context,
    AuthProvider auth,
    ActiveCountProvider activeCount,
  ) async {
    try {
      final pendientes = await auth.descargarPendientes();
      if (!context.mounted) return;

      if (pendientes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes artículos pendientes por contar.'),
          ),
        );
        return;
      }

      await activeCount.guardarPendientesLocales(pendientes);
      await activeCount.loadLocalActiveCount(auth.currentCedula!);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pendientes.length} artículos descargados exitosamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ActiveCountProvider>(
      builder: (context, authProvider, activeCountProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Módulo de Contadores',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (authProvider.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () {
                    authProvider.logout();
                  },
                ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
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
                padding: const EdgeInsets.all(32.0),
                child: authProvider.isAuthenticated
                    ? _buildAuthenticatedMenu(
                        context,
                        authProvider,
                        activeCountProvider,
                      )
                    : _buildLoginForm(context, authProvider),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthProvider authProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.qr_code_scanner, size: 80, color: primaryColor),
        const SizedBox(height: 20),
        Text(
          'Autenticación de Conteo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ingresa los datos proporcionados por correo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _cedulaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Cédula',
            prefixIcon: const Icon(Icons.badge),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          enabled: !authProvider.isLoading,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _codigoController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Código Temporal',
            prefixIcon: const Icon(Icons.password),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          enabled: !authProvider.isLoading,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () => _handleLogin(context, authProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: authProvider.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'INGRESAR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedMenu(
    BuildContext context,
    AuthProvider authProvider,
    ActiveCountProvider activeCountProvider,
  ) {
    final bool hasDownloadedCounts = activeCountProvider.hasActiveCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.verified_user, size: 80, color: Colors.green.shade600),
        const SizedBox(height: 20),
        Text(
          '¡Hola, ${authProvider.currentUsername ?? authProvider.currentCedula}!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 30),

        // Botón Descargar Asignaciones
        ElevatedButton.icon(
          onPressed: authProvider.isLoading
              ? null
              : () => _descargarPendientes(
                  context,
                  authProvider,
                  activeCountProvider,
                ),
          icon: authProvider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_download),
          label: const Text('Descargar Asignaciones (Offline)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            side: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
        ),

        const SizedBox(height: 20),

        // Botón Iniciar Conteo Físico
        ElevatedButton.icon(
          onPressed: !hasDownloadedCounts
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActiveCountScreen(),
                    ),
                  );
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar / Continuar Conteo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasDownloadedCounts
                ? Colors.green.shade600
                : Colors.grey.shade300,
            foregroundColor: hasDownloadedCounts
                ? Colors.white
                : Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        if (!hasDownloadedCounts)
          const Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Text(
              'Debes descargar asignaciones primero antes de iniciar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 10),

        // Botón Limpiar Datos Locales
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Limpiar almacenamiento local'),
                content: const Text(
                  'Esta acción borrará todas las asignaciones y conteos descargados de este dispositivo local. ¿Deseas continuar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              await activeCountProvider.clearLocalDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Almacenamiento local limpiado con éxito.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.delete_sweep, color: Colors.red),
          label: const Text(
            'Limpiar Datos Locales',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
