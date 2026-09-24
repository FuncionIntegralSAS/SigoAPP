import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/providers/inventory_provider.dart';
import 'package:sigo_app/modules/inventory/providers/geolocation_provider.dart';

/// Modal interactivo para actualizar el estado operativo, comentarios, foto
/// y coordenadas GPS de un activo en la vista de inventario.
class ArticleEditModal extends StatefulWidget {
  final ArticleModel article;
  final Color primaryColor;

  const ArticleEditModal({
    super.key,
    required this.article,
    this.primaryColor = Colors.deepPurple,
  });

  /// Método estático utilitario para abrir el modal en una sola invocación.
  static Future<void> show(
    BuildContext context,
    ArticleModel article, {
    Color primaryColor = Colors.deepPurple,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ArticleEditModal(
        article: article,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<ArticleEditModal> createState() => _ArticleEditModalState();
}

class _ArticleEditModalState extends State<ArticleEditModal> {
  late final TextEditingController _commentsController;
  late final ValueNotifier<String?> _editStatusNotifier;

  final List<String> _statusOptions = [
    'Operativo',
    'En Mantenimiento',
    'Dañado',
    'Baja',
  ];

  String? _selectedStatus;
  String? _rutaFoto;
  double? _currentLat;
  double? _currentLon;
  bool _isLocating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController(
      text: widget.article.comentarios ?? '',
    );
    _selectedStatus = widget.article.estado ?? 'Operativo';
    _rutaFoto = widget.article.rutaFoto;
    _currentLat = widget.article.latitud;
    _currentLon = widget.article.longitud;
    _editStatusNotifier = ValueNotifier<String?>(_selectedStatus);
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _editStatusNotifier.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    if (_currentLat != null && _currentLon != null) {
      final update = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Actualizar Ubicación'),
          content: const Text(
            'El activo ya cuenta con una ubicación registrada. ¿Desea reemplazarla por su ubicación actual?',
          ),
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
      if (update != true) return;
    }

    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentLat = position.latitude;
        _currentLon = position.longitude;
        _isLocating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error GPS: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _rutaFoto =
          'path/to/local/storage/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto capturada (Simulación: Cámara)'),
        ),
      );
    }
  }

  Future<void> _saveArticleData() async {
    setState(() => _isSaving = true);
    try {
      if (_currentLat != null &&
          _currentLon != null &&
          widget.article.id != null) {
        final geoProvider = context.read<GeolocationProvider>();
        final synced = await geoProvider.syncGeolocation(
          widget.article.id!,
          _currentLat!,
          _currentLon!,
        );
        if (!synced && mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Aviso de Sincronización'),
              content: Text(
                'No se pudo registrar la ubicación en el servidor:\n${geoProvider.errorMessage ?? "Error de red"}\n\nLos cambios locales continuarán.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      }

      final updatedArticle = widget.article.copyWith(
        latitud: _currentLat,
        longitud: _currentLon,
        estado: _selectedStatus,
        comentarios: _commentsController.text.trim(),
      );

      if (mounted) {
        context.read<InventoryProvider>().updateArticleLocally(updatedArticle);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos del activo actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actualizar Estado de Activo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Información del Activo (Sólo Lectura)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Placa: ${widget.article.placa}'),
                  Text('Bodega: ${widget.article.bodega}'),
                  Text(
                    'Responsable: ${widget.article.responsable ?? 'Sin responsable'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Estado
            DropdownButtonFormField2<String>(
              isExpanded: true,
              valueListenable: _editStatusNotifier,
              decoration: InputDecoration(
                labelText: 'Estado',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _statusOptions
                  .map(
                    (s) => DropdownItem<String>(
                      value: s,
                      child: Text(
                        s,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                _selectedStatus = v;
                _editStatusNotifier.value = v;
              },
            ),
            const SizedBox(height: 15),

            // Comentarios del Evento / Estado
            TextField(
              controller: _commentsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Comentarios del estado',
                prefixIcon: Icon(Icons.comment),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Captura de Foto
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _rutaFoto == null ? 'TOMAR FOTO' : 'CAMBIAR FOTO',
                    ),
                  ),
                ),
                if (_rutaFoto != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ],
            ),
            const SizedBox(height: 15),

            // Geolocalización
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Geolocalización',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              onPressed: _captureLocation,
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                    ],
                  ),
                  if (_currentLat != null)
                    Text(
                      'Lat: $_currentLat, Lon: $_currentLon',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                      ),
                    ),
                  if (_currentLat == null)
                    const Text(
                      'Sin coordenadas registradas',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isSaving ? null : _saveArticleData,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'ACTUALIZAR DATOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
