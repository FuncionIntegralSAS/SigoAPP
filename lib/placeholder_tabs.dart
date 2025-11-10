import 'package:flutter/material.dart';

// 2. Placeholder para la sección de Perfil/Ajustes (Índice 3)
class PlaceholderPerfil extends StatelessWidget {
  const PlaceholderPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 80, color: Colors.teal),
          SizedBox(height: 16),
          Text(
            'Pantalla 4: PERFIL Y AJUSTES', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          SizedBox(height: 8),
          Text('Aquí estarán las opciones de usuario, licencias, etc.', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}