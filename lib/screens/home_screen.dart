import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/auth_provider.dart';
import 'package:sigo_app/screens/account_screen.dart';
import 'package:sigo_app/screens/generator_screen.dart';
import 'package:sigo_app/screens/inventory_screen.dart';
import 'package:sigo_app/screens/scanner_screen.dart';
import 'package:sigo_app/screens/transfer_approval_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ScannerScreen(),
    GeneratorScreen(),
    InventoryScreen(),
    AccountScreen(),
    _LicensesTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'SIGAPP',
      applicationVersion: '1.0.0',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/LOGO_SIN_FONDO.png',
          width: 48,
          height: 48,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps, size: 48),
        ),
      ),
      applicationLegalese: '© 2026 Funcion Integral SAS. Todos los derechos reservados.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Gestión Administrativa'),
        backgroundColor: Colors.blueAccent,
      ),

      drawer: Drawer(
        child: SizedBox(
          width: screenWidth * 0.50,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                ),
                child: Text(
                  'Menú de Opciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuraciones'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.approval),
                title: const Text('Aprobación de Traspasos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransferApprovalScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Licencias de Código Abierto'),
                onTap: () {
                  Navigator.pop(context);
                  _openLicensePage(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),

      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Lector',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Generador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.policy_outlined),
            label: 'Licencias',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Vista provisional para consultar licencias de software y créditos
class _LicensesTab extends StatelessWidget {
  const _LicensesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/LOGO_SIN_FONDO.png',
                  height: 90,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SIGAPP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const Text(
                  'Versión 1.0.0 (Build 1)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gestión Administrativa y Conteo Físico',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const Divider(height: 32),
                const Text(
                  'Este software utiliza librerías y componentes de código abierto bajo licencias permisivas (MIT, BSD-3, BSD-2, Apache 2.0).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'SIGAPP',
                      applicationVersion: '1.0.0',
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/LOGO_SIN_FONDO.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.apps, size: 48),
                        ),
                      ),
                      applicationLegalese:
                          '© 2026 Funcion Integral SAS. Todos los derechos reservados.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text(
                    'Ver Licencias (showLicensePage)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
