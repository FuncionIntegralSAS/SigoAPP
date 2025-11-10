import 'package:flutter/material.dart';

// 1. Vista Genérica para el Lector/Scanner
class TabLector extends StatelessWidget {
  const TabLector({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Pantalla 1: LECTOR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}

// 2. Vista Genérica para el Generador
class TabGenerador extends StatelessWidget {
  const TabGenerador({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Pantalla 2: GENERADOR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}

// 3. Vista Genérica 3
class TabInventario extends StatelessWidget {
  const TabInventario({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Pantalla 3: INVENTARIO (Próximamente)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}

// 4. Vista Genérica 4
class TabPerfil extends StatelessWidget {
  const TabPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Pantalla 4: PERFIL/AJUSTES', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}