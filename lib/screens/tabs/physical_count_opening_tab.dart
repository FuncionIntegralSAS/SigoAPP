import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';

class PhysicalCountOpeningTab extends StatefulWidget {
  const PhysicalCountOpeningTab({super.key});

  @override
  State<PhysicalCountOpeningTab> createState() =>
      _PhysicalCountOpeningTabState();
}

class _PhysicalCountOpeningTabState extends State<PhysicalCountOpeningTab> {
  // Clave del formulario para controlar el reseteo visual de los campos
  final _formKey = GlobalKey<FormState>();

  // Formateador de fecha extraído como campo para evitar re-instanciar en cada build
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  PhysicalCountState? _lastHandledState;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(PhysicalCountProvider provider) {
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
              // Reinicia el estado en el provider y resetea visualmente el Form
              provider.resetForm();
              _formKey.currentState?.reset();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(PhysicalCountProvider provider) async {
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
          } else if (provider.state == PhysicalCountState.creada) {
            _lastHandledState = provider.state;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSuccessDialog(provider);
              _lastHandledState = null;
            });
          }
        }

        final isLoading = provider.state == PhysicalCountState.enProceso;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<CompanyModel>(
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: provider.selectedCompany,
                      items: provider.companies.map((company) {
                        return DropdownMenuItem(
                          value: company,
                          child: Text(company.descripcion),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (val) => provider.selectCompany(val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WarehouseModel>(
                      decoration: const InputDecoration(
                        labelText: 'Bodega',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: provider.selectedWarehouse,
                      items: provider.warehouses.map((wh) {
                        return DropdownMenuItem(
                          value: wh,
                          child: Text(wh.bodeDesc),
                        );
                      }).toList(),
                      onChanged: isLoading || provider.warehouses.isEmpty
                          ? null
                          : (val) => provider.selectWarehouse(val),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: isLoading ? null : () => _selectDate(provider),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(provider.selectedDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ArticleModel>(
                      decoration: const InputDecoration(
                        labelText: 'Artículos',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: provider.selectedArticle,
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
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading
                          ? null
                          : () => provider.submitPhysicalCount(),
                      child: const Text(
                        'Generar Apertura de Conteo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
