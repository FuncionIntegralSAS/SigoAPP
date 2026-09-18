import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';

class DialogUtils {
  static void showPendingWarehousesErrorDialog(
      BuildContext context, PhysicalCountProvider provider) {
    final message = provider.pendingWarehousesErrorMessage ??
        'Ocurrió un error al obtener las bodegas pendientes.';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: const Text(
          'ERROR EN BODEGAS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const StadiumBorder(),
              elevation: 2,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              provider.clearPendingWarehousesError();
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Extrae un mensaje amigable y conciso a partir de una traza cruda de error
  /// proveniente de la base de datos (Oracle / PL/SQL) o de Spring Boot / JDBC.
  static String extractFriendlyMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Ha ocurrido un error inesperado.';

    // 1. Detectar error ORA con pipe de negocio (ej: 121|Bodega Destino [2612] o Bodega Fuente [F571] Deben ser de Tipo Personal)
    final pipeRegex = RegExp(
      r'ORA-\d{5}:.*?\|\s*(.+?)(?=\s+ORA-\d{5}|\s+https?:\/\/|\]\s*\[Hikari|\r?\n|$)',
      dotAll: true,
    );
    final pipeMatch = pipeRegex.firstMatch(trimmed);
    if (pipeMatch != null) {
      final candidate = pipeMatch.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    // 2. Detectar error ORA-20xxx estándar (errores de aplicación de negocio)
    final appErrorRegex = RegExp(
      r'ORA-20\d{3}:(?:\s*(?:package body|line|línea)\s+[^:]+?:)?\s*(?:.*?\d+\|)?\s*(.+?)(?=\s+ORA-\d{5}|\s+https?:\/\/|\]\s*\[Hikari|\r?\n|$)',
      dotAll: true,
    );
    final appMatch = appErrorRegex.firstMatch(trimmed);
    if (appMatch != null) {
      final candidate = appMatch.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    // 3. Detectar cualquier otro ORA-xxxxx
    final anyOraRegex = RegExp(
      r'(ORA-\d{5}:\s*.+?)(?=\s+ORA-\d{5}|\s+https?:\/\/|\]\s*\[Hikari|\r?\n|$)',
      dotAll: true,
    );
    final anyOraMatch = anyOraRegex.firstMatch(trimmed);
    if (anyOraMatch != null) {
      final candidate = anyOraMatch.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    // 4. Limpieza de prefijos técnicos comunes de Spring Boot / JDBC / CallableStatement
    var cleaned = trimmed;
    cleaned = cleaned.replaceAll(RegExp(r'^Error al realizar el proceso:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^Error ejecutando [^:]+:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^Error calling CallableStatement[^:]*:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[HikariProxyCallableStatement[^\]]*\]', caseSensitive: false), '');

    cleaned = cleaned.trim();
    return cleaned.isNotEmpty ? cleaned : 'Ha ocurrido un error en la operación.';
  }

  /// Muestra un modal de error amigable y conciso para el usuario final,
  /// incorporando una sección expandible con el código de error y los detalles
  /// técnicos identificables para el desarrollador, junto con la opción de copiar.
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? technicalDetails,
    int? statusCode,
    String? endpoint,
    String buttonText = 'Aceptar',
    VoidCallback? onAccept,
    VoidCallback? onRetry,
  }) async {
    bool isExpanded = false;

    final displayFriendlyMessage = extractFriendlyMessage(message);
    final bool isTechnicalError = displayFriendlyMessage != message.trim();

    final effectiveTechnicalDetails = technicalDetails ??
        (isTechnicalError
            ? [
                if (endpoint != null) 'Endpoint: $endpoint',
                if (statusCode != null) 'Código HTTP: $statusCode',
                'Detalle técnico:\n$message',
              ].join('\n')
            : (statusCode != null || endpoint != null
                ? [
                    if (endpoint != null) 'Endpoint: $endpoint',
                    if (statusCode != null) 'Código HTTP: $statusCode',
                  ].join('\n')
                : null));

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusCode == 500 ? Icons.dns_outlined : Icons.error_outline,
                  color: Colors.red.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayFriendlyMessage,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                if (statusCode != null ||
                    effectiveTechnicalDetails != null ||
                    endpoint != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isExpanded
                                  ? 'Ocultar detalles técnicos'
                                  : 'Ver detalles técnicos (Desarrollador)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            effectiveTechnicalDetails ??
                                'Endpoint: ${endpoint ?? "N/A"}\nCódigo: ${statusCode ?? "N/A"}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copiar detalle',
                                  style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                final textToCopy = effectiveTechnicalDetails ??
                                    'Endpoint: ${endpoint ?? "N/A"}\nCódigo: ${statusCode ?? "N/A"}';
                                Clipboard.setData(
                                    ClipboardData(text: textToCopy));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Detalles técnicos copiados al portapapeles'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            if (onRetry != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRetry();
                },
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onAccept != null) onAccept();
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
