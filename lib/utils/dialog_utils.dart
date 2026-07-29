import 'package:flutter/material.dart';
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
}
