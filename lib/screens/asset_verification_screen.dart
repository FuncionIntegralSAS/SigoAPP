import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../models/article_model.dart';
import '../widgets/transfer_form_widget.dart';
import '../providers/transfer_request_provider.dart';
import '../providers/geolocation_provider.dart';
import '../utils/dropdown_template.dart';
import 'scanner_screen.dart';
import 'generator_screen.dart';
import 'package:geolocator/geolocator.dart';

class AssetVerificationScreen extends StatefulWidget {
  const AssetVerificationScreen({super.key});

  @override
  State<AssetVerificationScreen> createState() =>
      _AssetVerificationScreenState();
}

class _AssetVerificationScreenState extends State<AssetVerificationScreen> {
  String? selectedResponsible;

  ArticleModel? verifiedArticle;
  bool? verificationResult;

  final ValueNotifier<String?> _responsibleNotifier = ValueNotifier(null);
  final TextEditingController _responsibleSearchController =
      TextEditingController();

  final List<String> responsibles = [
    'Juan Pérez',
    'Maria López',
    'Carlos Ruiz',
  ];

  @override
  void dispose() {
    _responsibleNotifier.dispose();
    _responsibleSearchController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ScannerScreen(expectedResponsible: selectedResponsible),
      ),
    );

    if (result != null) {
      final article = result['article'] as ArticleModel;
      setState(() {
        verifiedArticle = article;
        verificationResult = result['isValid'] as bool;
      });
      _checkGeolocation(article);
    }
  }

  Future<void> _checkGeolocation(ArticleModel article) async {
    if (article.id == null) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      return;
    }

    if (!mounted) return;
    final geoProvider = context.read<GeolocationProvider>();
    final storedLocation = await geoProvider.getGeolocation(article.id!);

    bool shouldUpdate = false;
    String dialogTitle = '';
    String dialogContent = '';

    if (storedLocation != null) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        storedLocation.latitud,
        storedLocation.longitud,
      );

      if (distance > 1) {
        shouldUpdate = true;
        dialogTitle = 'Actualizar Ubicación';
        dialogContent =
            'La ubicación actual del activo difiere de la registrada. ¿Desea actualizarla?';
      }
    } else {
      shouldUpdate = true;
      dialogTitle = 'Registrar Ubicación';
      dialogContent =
          'El activo no tiene ubicación registrada. ¿Desea guardar la ubicación actual?';
    }

    if (shouldUpdate && mounted) {
      final update = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí'),
            ),
          ],
        ),
      );

      if (update == true && mounted) {
        await geoProvider.syncGeolocation(
          article.id!,
          currentPosition.latitude,
          currentPosition.longitude,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ubicación guardada exitosamente')),
          );
        }
      }
    }
  }

  void _suggestTransfer() {
    if (verifiedArticle == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransferRequestProvider>(),
        child: TransferFormWidget(
          article: verifiedArticle!,
          users: responsibles,
          responsablePropuesto: verifiedArticle!.responsable,
          bodegaPropuesta: verifiedArticle!.bodega,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Activos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Responsable esperado (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField2<String>(
              isExpanded: true,
              valueListenable: _responsibleNotifier,
              hint: const Text('Seleccione un responsable'),
              items: responsibles
                  .map(
                    (r) => DropdownItem<String>(
                      value: r,
                      child: Text(
                        r,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedResponsible = value;
                  _responsibleNotifier.value = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
              dropdownSearchData: DropdownTemplates.searchData(
                controller: _responsibleSearchController,
                hintText: 'Buscar responsable...',
                searchMatchFn: (item, searchValue) {
                  return item.value!.toLowerCase().contains(
                    searchValue.toLowerCase(),
                  );
                },
              ),
              onMenuStateChange: (isOpen) {
                if (!isOpen) _responsibleSearchController.clear();
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear Activo'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GeneratorScreen()),
                  );
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Generar QR'),
              ),
            ),

            const SizedBox(height: 24),

            if (verifiedArticle != null) ...[
              const Divider(),
              const SizedBox(height: 12),

              Text(
                verifiedArticle!.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text('Placa: ${verifiedArticle!.placa}'),
              Text(
                'Responsable: ${verifiedArticle!.responsable ?? "No asignado"}',
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(
                    verificationResult == true
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: verificationResult == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      verificationResult == true
                          ? 'El activo corresponde al responsable seleccionado'
                          : 'El responsable del activo no coincide',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: verificationResult == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              // =============================
              // SUGERENCIA DE TRASPASO
              // =============================
              if (verificationResult == false) ...[
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Se sugiere realizar un traspaso'),
                    onPressed: _suggestTransfer,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
