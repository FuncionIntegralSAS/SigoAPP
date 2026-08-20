import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../services/bluetooth_printer_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterProvider extends ChangeNotifier {
  final BluetoothPrinterService _service = BluetoothPrinterService();
  
  List<PrinterDevice> _devices = [];
  List<PrinterDevice> get devices => _devices;

  PrinterDevice? _selectedDevice;
  PrinterDevice? get selectedDevice => _selectedDevice;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void scanDevices() async {
    await requestPermissions();
    _isScanning = true;
    _devices.clear();
    _errorMessage = null;
    notifyListeners();

    _service.scanDevices().listen((device) {
      if (device.address != null && !_devices.any((d) => d.address == device.address)) {
        _devices.add(device);
        notifyListeners();
      }
    }, onDone: () {
      _isScanning = false;
      notifyListeners();
    }, onError: (error) {
      _isScanning = false;
      _errorMessage = error.toString();
      notifyListeners();
    });
  }

  Future<void> connect(PrinterDevice device) async {
    try {
      _errorMessage = null;
      notifyListeners();
      final success = await _service.connect(device);
      if (success) {
        _selectedDevice = device;
        _isConnected = true;
      } else {
        _errorMessage = "No se pudo conectar a la impresora.";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    _isConnected = false;
    _selectedDevice = null;
    notifyListeners();
  }

  Future<bool> printQrTicket(String qrData, String name, String licensePlate) async {
    if (!_isConnected) {
      _errorMessage = "No hay impresora conectada";
      notifyListeners();
      return false;
    }
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Placa: $licensePlate', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);
      bytes += generator.qrcode(qrData, size: QRSize.size4);
      bytes += generator.feed(2);

      return await _service.printBytes(bytes);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
