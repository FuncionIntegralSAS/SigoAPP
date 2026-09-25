import 'package:flutter/material.dart';

/// Tipos de renderizado para [AppErrorWidget].
enum AppErrorDisplayType {
  /// Contenedor en línea compacto para inputs o selectores.
  inline,

  /// Banner de bloque para secciones o tarjetas de formulario.
  banner,

  /// Vista completa centrada para estados de error de pantalla.
  view,
}

/// Widget estandarizado transversal para la renderización de errores en SigoAPP.
///
/// Sigue rigurosamente la Guía de Estilos y UI/UX del proyecto:
/// - Paleta cromática corporativa (fondos en `red.shade50` o `amber.shade50`).
/// - Bordes sutiles y sistema de radios formal (`r: 6` para inline, `r: 8` para banner y `r: 12` para vistas).
/// - Tipografía de alto contraste sin desbordamientos visuales.
/// - Soporte para acciones de reintento (`onRetry`) o inspección de detalles (`onShowDetails`).
class AppErrorWidget extends StatelessWidget {
  /// Mensaje principal descriptivo y amigable para el operador.
  final String message;

  /// Título opcional del error (utilizado en banner o view).
  final String? title;

  /// Icono ilustrativo opcional.
  final IconData? icon;

  /// Si es true, renderiza con paleta de advertencia ámbar en lugar de rojo corporativo.
  final bool isWarning;

  /// Callback opcional para reintentar la operación fallida.
  final VoidCallback? onRetry;

  /// Callback opcional para abrir el modal de detalles técnicos (desarrollador).
  final VoidCallback? onShowDetails;

  /// Etiqueta del botón de reintento (por defecto 'Reintentar').
  final String retryLabel;

  /// Tipo de visualización del widget.
  final AppErrorDisplayType displayType;

  /// Margen exterior opcional.
  final EdgeInsetsGeometry? margin;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.isWarning = false,
    this.onRetry,
    this.onShowDetails,
    this.retryLabel = 'Reintentar',
    this.displayType = AppErrorDisplayType.banner,
    this.margin,
  });

  /// Constructor canónico para mensajes de error compactos en línea (debajo de inputs o selectores).
  const AppErrorWidget.inline({
    super.key,
    required this.message,
    this.icon,
    this.isWarning = false,
    this.margin,
  })  : title = null,
        onRetry = null,
        onShowDetails = null,
        retryLabel = '',
        displayType = AppErrorDisplayType.inline;

  /// Constructor canónico para banners de error en tarjetas o formularios.
  const AppErrorWidget.banner({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.isWarning = false,
    this.onRetry,
    this.onShowDetails,
    this.retryLabel = 'Reintentar',
    this.margin,
  }) : displayType = AppErrorDisplayType.banner;

  /// Constructor canónico para vistas completas centradas de error de pantalla.
  const AppErrorWidget.view({
    super.key,
    required this.message,
    this.title = 'Ha ocurrido un error',
    this.icon,
    this.isWarning = false,
    this.onRetry,
    this.onShowDetails,
    this.retryLabel = 'Reintentar',
    this.margin,
  }) : displayType = AppErrorDisplayType.view;

  @override
  Widget build(BuildContext context) {
    switch (displayType) {
      case AppErrorDisplayType.inline:
        return _buildInline(context);
      case AppErrorDisplayType.banner:
        return _buildBanner(context);
      case AppErrorDisplayType.view:
        return _buildView(context);
    }
  }

  /// Renderizado compacto en línea.
  Widget _buildInline(BuildContext context) {
    final bgColor = isWarning ? Colors.amber.shade50 : Colors.red.shade50;
    final borderColor = isWarning ? Colors.amber.shade200 : Colors.red.shade200;
    final iconColor = isWarning ? Colors.amber.shade800 : Colors.red.shade700;
    final textColor = isWarning ? Colors.amber.shade900 : Colors.red.shade900;

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? (isWarning ? Icons.warning_amber_rounded : Icons.error_outline),
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renderizado de banner de bloque.
  Widget _buildBanner(BuildContext context) {
    final bgColor = isWarning ? Colors.amber.shade50 : Colors.red.shade50;
    final borderColor = isWarning ? Colors.amber.shade300 : Colors.red.shade300;
    final iconColor = isWarning ? Colors.amber.shade800 : Colors.red.shade700;
    final titleColor = isWarning ? Colors.amber.shade900 : Colors.red.shade900;
    final textColor = isWarning ? Colors.amber.shade900 : Colors.red.shade800;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon ?? (isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded),
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title!.trim().isNotEmpty) ...[
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onRetry != null || onShowDetails != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onShowDetails != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Ver detalle', style: TextStyle(fontSize: 11)),
                    onPressed: onShowDetails,
                  ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: iconColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: Text(
                      retryLabel.isNotEmpty ? retryLabel : 'Reintentar',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Renderizado de vista centrada completa (Full Screen Error View).
  Widget _buildView(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isWarning ? Colors.amber.shade800 : Colors.red.shade700;
    final iconBgColor = isWarning ? Colors.amber.shade50 : Colors.red.shade50;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded),
                size: 48,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            if (title != null && title!.isNotEmpty)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel.isNotEmpty ? retryLabel : 'Reintentar'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
