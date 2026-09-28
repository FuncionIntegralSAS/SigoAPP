import 'package:flutter/material.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

/// Tarjeta visual reutilizable para representar un activo físico en la lista de inventario.
///
/// Soporta tanto el modo de visualización normal (con acceso a edición y traspaso rápido)
/// como el modo de selección múltiple (con checkboxes y resaltado visual).
class InventoryArticleTile extends StatelessWidget {
  final ArticleModel article;
  final bool isSelected;
  final bool isSelectionMode;
  final bool canCreateTransfer;
  final Color primaryColor;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleSelect;
  final VoidCallback? onTransfer;

  const InventoryArticleTile({
    super.key,
    required this.article,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.canCreateTransfer = false,
    this.primaryColor = Colors.deepPurple,
    this.onTap,
    this.onToggleSelect,
    this.onTransfer,
  });

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Operativo':
        return Colors.green;
      case 'En Mantenimiento':
        return Colors.orange;
      case 'Dañado':
        return Colors.red;
      case 'Baja':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(article.estado);
    final isEnTramite = article.enTramite;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: ListTile(
        onTap: (isSelectionMode && isEnTramite)
            ? () {
                DialogUtils.showWarningSnackBar(
                  context,
                  'El activo "${article.nombre}" se encuentra en trámite pendiente y no puede ser seleccionado.',
                );
              }
            : onTap,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            if (isSelectionMode) ...[
              const SizedBox(width: 8),
              Checkbox(
                value: isSelected,
                activeColor: primaryColor,
                onChanged: isEnTramite ? null : onToggleSelect,
              ),
            ],
          ],
        ),
        title: Text(
          article.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEnTramite ? Colors.grey.shade700 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placa: ${article.placa} • Resp: ${article.responsable ?? 'N/A'}',
              style: TextStyle(
                color: isEnTramite ? Colors.grey.shade600 : null,
              ),
            ),
            if (article.comentarios != null && article.comentarios!.isNotEmpty)
              Text(
                article.comentarios!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            Row(
              children: [
                Text(
                  'Estado: ${article.estado ?? "Operativo"}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isEnTramite) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock, size: 12, color: Colors.amber.shade900),
                    const SizedBox(width: 4),
                    Text(
                      'En trámite pendiente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: isSelectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canCreateTransfer)
                    IconButton(
                      icon: Icon(
                        Icons.swap_horiz,
                        color: isEnTramite ? Colors.grey.shade400 : Colors.orange,
                      ),
                      tooltip: isEnTramite
                          ? 'Activo en trámite pendiente'
                          : 'Traspasar Activo',
                      onPressed: isEnTramite
                          ? () {
                              DialogUtils.showWarningSnackBar(
                                context,
                                'El activo "${article.nombre}" ya tiene una solicitud de traspaso en trámite pendiente.',
                              );
                            }
                          : onTransfer,
                    ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
      ),
    );
  }
}
