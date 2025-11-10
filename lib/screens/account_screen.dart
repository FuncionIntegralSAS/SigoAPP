import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/mock_account_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final MockAccountService _service = MockAccountService();
  final TextEditingController _idController = TextEditingController();
  
  PersonModel? _searchResult;
  bool _isSearching = false;
  String _message = 'Ingrese el número de cédula y presione Buscar.';

  final Color primaryColor = Colors.blue.shade700;

  // 1. Lógica de búsqueda por cédula
  void _searchPerson() {
    final nationalId = _idController.text.trim();
    if (nationalId.isEmpty) {
      setState(() {
        _message = 'El campo de cédula no puede estar vacío.';
        _searchResult = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _message = 'Buscando persona con ID $nationalId...';
    });

    // Simular latencia de red para que se vea la búsqueda
    Future.delayed(const Duration(milliseconds: 800), () {
      final person = _service.searchPersonByNationalId(nationalId);
      setState(() {
        _isSearching = false;
        _searchResult = person;

        if (person == null) {
          _message = 'Persona no encontrada en el sistema de registro.';
        } else if (person.accountExists) {
          _message = '¡Cuenta existente encontrada!';
        } else {
          _message = 'Persona encontrada. La cuenta NO ha sido generada.';
        }
      });
    });
  }

  // 3. Lógica para generar la cuenta
  void _createAccount(PersonModel person) {
    setState(() {
      _isSearching = true;
      _message = 'Generando cuenta para ${person.fullName}...';
    });

    // Simular la creación de la cuenta
    Future.delayed(const Duration(milliseconds: 1500), () {
      final newAccount = _service.createAccount(person);
      
      // 5. Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ¡Cuenta creada con éxito para ${newAccount.fullName}!'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _isSearching = false;
        _searchResult = newAccount;
        _message = 'Cuenta creada. Usuario registrado por: ${newAccount.createdByUserId}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cuentas y Perfil'),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de Búsqueda
            _buildSearchField(),
            const SizedBox(height: 20),
            
            // Botón de Búsqueda
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchPerson,
              icon: _isSearching 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search, color: Colors.white),
              label: Text(_isSearching ? 'Buscando...' : 'Buscar Persona por Cédula', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            
            const SizedBox(height: 30),

            // Mensajes de Estado
            Text(_message, 
              textAlign: TextAlign.center, 
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
            
            const SizedBox(height: 20),

            // Contenido Condicional (Información/Creación/Error)
            if (_searchResult != null) 
              _buildPersonResultCard(_searchResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _idController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Número de Cédula (Ej: 1018420001)',
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        prefixIcon: const Icon(Icons.credit_card),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _idController.clear();
            setState(() {
              _searchResult = null;
              _message = 'Ingrese el número de cédula y presione Buscar.';
            });
          },
        ),
      ),
    );
  }
  
  Widget _buildPersonResultCard(PersonModel person) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(person.fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
            const Divider(height: 20),
            _buildDetailRow('Cédula', person.nationalId, Icons.badge),
            _buildDetailRow('Cuenta Registrada', person.accountExists ? 'SÍ' : 'NO', Icons.verified_user, color: person.accountExists ? Colors.green : Colors.red),
            
            // 4. Validación de existencia y estado activo
            _buildDetailRow('Estado Activo', person.isActive ? 'ACTIVO' : 'INACTIVO', Icons.circle, color: person.isActive ? Colors.green : Colors.red),
            
            if (person.accountExists) ...[
              const SizedBox(height: 15),
              Text('Metadata de Creación', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              _buildDetailRow('Fecha de Creación', person.creationDate!.toLocal().toString().split('.')[0], Icons.date_range),
              // 6. Registrar usuario, fecha y hora de creación
              _buildDetailRow('Creado por Usuario', person.createdByUserId!, Icons.person_pin),
            ],
            
            const SizedBox(height: 20),
            
            // Acción condicional (Crear cuenta)
            _buildConditionalAction(person),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value, style: TextStyle(color: color, fontWeight: color != null ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConditionalAction(PersonModel person) {
    if (person.accountExists && person.isActive) {
      return const Center(child: Text('La persona ya tiene una cuenta activa.', style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic)));
    }
    
    if (!person.isActive) {
      return const Center(child: Text('ERROR: La persona está INACTIVA en el sistema. No se puede generar cuenta.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    }
    
    // 3. Si no tiene cuenta, permitir generarla automáticamente.
    if (!person.accountExists && person.isActive) {
      return Column(
        children: [
          Padding( 
            padding: const EdgeInsets.only(bottom: 10),
            child: const Text('La cuenta no ha sido generada. ¿Desea crearla ahora?'),
          ),
          ElevatedButton.icon(
            onPressed: () => _createAccount(person),
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text('Generar Cuenta Automáticamente', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }
}