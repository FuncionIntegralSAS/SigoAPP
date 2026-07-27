import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';

class PhysicalCountAssignmentTab extends StatefulWidget {
  const PhysicalCountAssignmentTab({super.key});

  @override
  State<PhysicalCountAssignmentTab> createState() =>
      _PhysicalCountAssignmentTabState();
}

class _PhysicalCountAssignmentTabState
    extends State<PhysicalCountAssignmentTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _clearSearchFields() {
    _nameController.clear();
    _lastNameController.clear();
    _nationalIdController.clear();
  }

  void _performSearch(PhysicalCountProvider provider) {
    provider.searchPersons(
      nombre: _nameController.text,
      apellido: _lastNameController.text,
      cedula: _nationalIdController.text,
    );
  }

  PhysicalCountState? _lastHandledState;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhysicalCountProvider>(
      builder: (context, provider, child) {
        if (provider.state != _lastHandledState) {
          if (provider.state == PhysicalCountState.error &&
              provider.errorMessage != null) {
            _lastHandledState = provider.state;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorSnackBar(provider.errorMessage!);
              provider.clearError();
              _lastHandledState = null;
            });
          }
        }

        final isLoading = provider.state == PhysicalCountState.enProceso;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Asignación de Participantes (Contadores)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Búsqueda Avanzada de Personal'),
                    leading: const Icon(Icons.person_search),
                    initiallyExpanded: true,
                    childrenPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nationalIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cédula',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _clearSearchFields,
                            child: const Text('Limpiar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _performSearch(provider),
                            icon: const Icon(Icons.search),
                            label: const Text('Buscar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (provider.foundPersons.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: provider.foundPersons.length,
                        itemBuilder: (context, index) {
                          final person = provider.foundPersons[index];
                          final isSelected = provider.selectedPersons.any(
                            (p) => p.perscodi == person.perscodi,
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                person.persnomb.isNotEmpty
                                    ? person.persnomb
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(
                              '${person.persnomb} ${person.persapel}'.trim(),
                            ),
                            subtitle: Text('Cédula: ${person.perscodi}'),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                provider.togglePersonSelection(person);
                              },
                            ),
                            onTap: () => provider.togglePersonSelection(person),
                          );
                        },
                      ),
                    ),
                  if (provider.foundPersons.isEmpty &&
                      provider.state != PhysicalCountState.initial &&
                      provider.state !=
                          PhysicalCountState
                              .error) // asume error si no encontro y habia error
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No se encontraron resultados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (provider.selectedPersons.isNotEmpty) ...[
                    const Text(
                      'Participantes Seleccionados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: provider.selectedPersons
                          .map(
                            (p) => Chip(
                              label: Text('${p.persnomb} ${p.persapel}'.trim()),
                              avatar: const Icon(Icons.person, size: 16),
                              onDeleted: () => provider.removePerson(p),
                              deleteIconColor: Colors.red,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}
