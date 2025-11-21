import 'package:flutter/material.dart';

// Importaciones de las Pantallas de la Barra de Navegación
import 'screens/scanner_screen.dart'; 
import 'screens/generator_screen.dart'; 
import 'screens/inventory_screen.dart'; 
import 'screens/account_screen.dart'; 

// Importaciones del Mock Auth y Pantalla de Login
import 'services/mock_auth_service.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Gestión Administrativa',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      // CAMBIO CLAVE: Usamos AuthWrapper para decidir si mostrar Login o Home.
      // Esto mantiene tu HomeScreen como la definición de la navegación por pestañas.
      home: const AuthWrapper(), 
    );
  }
}

// NUEVO: Widget que maneja el estado de autenticación y decide qué pantalla mostrar.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder escucha los cambios en el servicio de autenticación.
    return ValueListenableBuilder(
      valueListenable: MockAuthService.instance.currentUser,
      builder: (context, user, child) {
        if (user != null) {
          // Si el usuario existe, muestra la estructura de navegación principal (las pestañas).
          return const HomeScreen();
        } else {
          // Si no hay usuario, muestra la pantalla de inicio de sesión.
          return const AuthScreen();
        }
      },
    );
  }
}

// HomeScreen se mantiene como tu versión original, gestionando la navegación por pestañas.
// Convertimos HomeScreen a StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado que guarda el índice de la pestaña seleccionada (0, 1, 2, o 3)
  int _selectedIndex = 0;

  // Lista de los Widgets (Pantallas) que corresponden a cada pestaña
  static const List<Widget> _widgetOptions = <Widget>[
    ScannerScreen(),   // Índice 0: Lector
    GeneratorScreen(), // Índice 1: Generador
    InventoryScreen(), // Índice 2: Inventario
    AccountScreen(),   // Índice 3: Perfil
  ];

  // Función que se llama cuando se toca un ícono en la barra
  void _onItemTapped(int index) {
    setState(() {
      // Usamos setState para actualizar el estado
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // RESTAURADO: Tu AppBar original
      appBar: AppBar(
        title: const Text('App Gestion Administrativa'),
        backgroundColor: Colors.blueAccent,
      ),
      
      // 1. El cuerpo (body) cambia según el índice seleccionado
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // 2. Definición del BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        // Los 4 items/secciones
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
        ],
        // El índice que está actualmente seleccionado
        currentIndex: _selectedIndex,
        // La función que se llama al tocar un item
        onTap: _onItemTapped,
        // Propiedades de estilo
        selectedItemColor: Colors.blueAccent, // Color del ícono seleccionado
        unselectedItemColor: Colors.grey,   // Color del ícono no seleccionado
        type: BottomNavigationBarType.fixed, // Asegura que todas las etiquetas sean visibles
      ),
    );
  }
}