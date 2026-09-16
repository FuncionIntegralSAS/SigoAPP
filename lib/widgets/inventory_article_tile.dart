import 'package:flutter/material.dart';
import '../models/article_model.dart';

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

    return Card(
      elevation: isSelected ? 3 : 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isSelected ? primaryColor.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: primaryColor, width: 1.5)
            : BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
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
                onChanged: onToggleSelect,
              ),
            ],
          ],
        ),
        title: Text(
          article.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placa: ${article.placa} • Resp: ${article.responsable ?? 'N/A'}',
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
        trailing: isSelectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canCreateTransfer)
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                      tooltip: 'Traspasar Activo',
                      onPressed: onTransfer,
                    ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
      ),
    );
  }
}
