import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';

class PhysicalCountScreen extends StatefulWidget {
  const PhysicalCountScreen({super.key});

  @override
  State<PhysicalCountScreen> createState() => _PhysicalCountScreenState();
}

class _PhysicalCountScreenState extends State<PhysicalCountScreen> {
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

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Conteo Creado'),
        content: const Text(
          'Se ha generado la apertura de conteo físico exitosamente para la bodega seleccionada.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PhysicalCountProvider>().resetForm();
              Navigator.of(context).pop();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    PhysicalCountProvider provider,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.updateDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apertura de Conteo Físico')),
      body: Consumer<PhysicalCountProvider>(
        builder: (context, provider, child) {
          if (provider.state == PhysicalCountState.ERROR &&
              provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorSnackBar(context, provider.errorMessage!);
              provider.clearError();
            });
          }

          if (provider.state == PhysicalCountState.CREADA) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSuccessDialog(context);
              provider.clearError();
            });
          }

          final isLoading = provider.state == PhysicalCountState.EN_PROCESO;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Empresa
                    DropdownButtonFormField<CompanyModel>(
                      decoration: const InputDecoration(labelText: 'Empresa'),
                      value: provider.selectedCompany,
                      items: provider.companies.map((company) {
                        return DropdownMenuItem(
                          value: company,
                          child: Text(company.name),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (val) => provider.selectCompany(val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<WarehouseModel>(
                      decoration: const InputDecoration(labelText: 'Bodega'),
                      value: provider.selectedWarehouse,
                      items: provider.warehouses.map((wh) {
                        return DropdownMenuItem(
                          value: wh,
                          child: Text(wh.name),
                        );
                      }).toList(),
                      onChanged: isLoading || provider.warehouses.isEmpty
                          ? null
                          : (val) => provider.selectWarehouse(val),
                    ),
                    const SizedBox(height: 16),

                    // Fecha
                    InkWell(
                      onTap: isLoading
                          ? null
                          : () => _selectDate(context, provider),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(provider.selectedDate),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<ArticleModel>(
                      decoration: const InputDecoration(labelText: 'Artículos'),
                      value: provider.selectedArticle,
                      items: provider.articles.map((art) {
                        return DropdownMenuItem(
                          value: art,
                          child: Text(art.name),
                        );
                      }).toList(),
                      onChanged: isLoading || provider.articles.isEmpty
                          ? null
                          : (val) => provider.selectArticle(val),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Verificar existencia física'),
                      subtitle: const Text(
                        'Solo tener en cuenta artículos físicamente en la bodega',
                      ),
                      value: provider.verifyExistence,
                      onChanged: isLoading ? null : provider.setVerifyExistence,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Personas Participantes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: const Text('Búsqueda Avanzada de Participantes'),
                      leading: const Icon(Icons.person_search),
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
                    const SizedBox(height: 8),

                    // Resultados de búsqueda
                    if (provider.foundPersons.isNotEmpty)
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: provider.foundPersons.length,
                          itemBuilder: (context, index) {
                            final person = provider.foundPersons[index];
                            final isSelected = provider.selectedPersons.any(
                              (p) => p.nationalId == person.nationalId,
                            );
                            return ListTile(
                              title: Text(person.fullName),
                              subtitle: Text('Cédula: ${person.nationalId}'),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  provider.togglePersonSelection(person);
                                },
                              ),
                              onTap: () =>
                                  provider.togglePersonSelection(person),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    if (provider.selectedPersons.isNotEmpty) ...[
                      const Text(
                        'Seleccionados:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: provider.selectedPersons
                            .map(
                              (p) => Chip(
                                label: Text(p.fullName),
                                onDeleted: () => provider.removePerson(p),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isLoading
                          ? null
                          : () => provider.submitPhysicalCount(),
                      child: const Text(
                        'Generar Apertura de Conteo',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
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
      ),
    );
  }
}
