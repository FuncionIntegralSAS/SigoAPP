import 'dart:async';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

class BluetoothPrinterService {
  final PrinterManager _printerManager = PrinterManager.instance;
  
  Stream<PrinterDevice> scanDevices() {
    return _printerManager.discovery(type: PrinterType.bluetooth, isBle: false);
  }

  Future<bool> connect(PrinterDevice device) async {
    if (device.address == null) return false;
    return await _printerManager.connect(
      type: PrinterType.bluetooth, 
      model: BluetoothPrinterInput(
        name: device.name,
        address: device.address!,
        isBle: false,
        autoConnect: false
      )
    );
  }

  Future<bool> disconnect() async {
    return await _printerManager.disconnect(type: PrinterType.bluetooth);
  }

  Future<bool> printBytes(List<int> bytes) async {
    return await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }
}
