import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/printer_provider.dart';

class PrinterConnectionDialog extends StatefulWidget {
  const PrinterConnectionDialog({super.key});

  @override
  State<PrinterConnectionDialog> createState() => _PrinterConnectionDialogState();
}

class _PrinterConnectionDialogState extends State<PrinterConnectionDialog> {
  @override
  void initState() {
    super.initState();
    // Scan devices when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().scanDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Conectar Impresora'),
              if (provider.isScanning) 
                const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.scanDevices(),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                if (provider.isConnected && provider.selectedDevice != null)
                  Container(
                    color: Colors.green.shade50,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conectado a:\n${provider.selectedDevice!.name.isNotEmpty ? provider.selectedDevice!.name : (provider.selectedDevice!.address ?? '')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.link_off, color: Colors.red),
                          onPressed: () => provider.disconnect(),
                        )
                      ],
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: provider.devices.isEmpty && !provider.isScanning
                      ? const Center(child: Text('No se encontraron dispositivos.'))
                      : ListView.builder(
                          itemCount: provider.devices.length,
                          itemBuilder: (context, index) {
                            final device = provider.devices[index];
                            final isSelected = provider.selectedDevice?.address == device.address;
                            return ListTile(
                              leading: const Icon(Icons.print),
                              title: Text(device.name.isNotEmpty ? device.name : 'Dispositivo Desconocido'),
                              subtitle: Text(device.address ?? ''),
                              trailing: isSelected
                                  ? const Icon(Icons.bluetooth_connected, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.connect(device);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
