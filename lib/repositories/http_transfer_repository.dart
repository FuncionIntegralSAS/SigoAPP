import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transfer_request.dart';

abstract class TransferRepository {
  Future<TransferRequest> create(TransferRequest request);
  
  // Convertimos a Future
  Future<List<TransferRequest>> getAllTransfers();
  
  Future<bool> approveTransfer(String transferId);
  
  // Convertimos a Future y mantenemos que reciba el objeto TransferRequest
  Future<void> applyTransfer(TransferRequest request);
  
  // Convertimos a Future
  Future<void> rejectTransfer({required String requestId, required String rejectionReason});
}

class HttpTransferRepository implements TransferRepository {
  final String baseUrl;
  final http.Client client;

  HttpTransferRepository({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  // --- 1. CREAR
  @override
  Future<TransferRequest> create(TransferRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/traspasos');
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(request.toJson()), 
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'] ?? jsonDecode(response.body);
        return TransferRequest.fromJson(data);
      } else {
        throw Exception('Error al crear traspaso: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Excepción de red al crear: $e');
    }
  }

  // --- 2. OBTENER TODOS ---
  @override
  Future<List<TransferRequest>> getAllTransfers() async {
    final url = Uri.parse('$baseUrl/api/v1/traspasos');
    try {
      final response = await client.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body)['data'] ?? [];
        return dataList.map((json) => TransferRequest.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener traspasos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Excepción de red al consultar: $e');
    }
  }

  // --- 3. APROBAR (Mapeado a PUT /procesar con 'ap') ---
  @override
  Future<bool> approveTransfer(String transferId) async {
    final url = Uri.parse('$baseUrl/api/v1/traspasos/$transferId/procesar');
    try {
      final response = await client.put( // Cambio a PUT
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'decision': 'ap', // Decisión 'ap' según backend
          'observacion': 'Aprobado vía App' // Opcional: Podrías pasar esto como parámetro si la UI lo pide
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Excepción al aprobar: $e');
    }
  }

  // --- 4.RECHAZAR (Mapeado a PUT /procesar con 'na') ---
  @override
  Future<void> rejectTransfer({required String requestId, required String rejectionReason}) async {
    final url = Uri.parse('$baseUrl/api/v1/traspasos/$requestId/procesar');
    try {
      final response = await client.put( // Cambio a PUT
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'decision': 'na', // Decisión 'na' según backend
          'observacion': rejectionReason // La observación es obligatoria en el rechazo
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor al rechazar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Excepción de red al rechazar: $e');
    }
  }

  // --- 5. APLICAR (El método redundante) ---
  @override
  Future<void> applyTransfer(TransferRequest request) async {
    // Como el backend actualiza ACTIFIJO automáticamente al aprobar ('ap'),
    // este método ya no necesita hacer una petición HTTP independiente.
    // Solo retornamos un Future exitoso para no romper el contrato/UI actual.
    // En el futuro, podríamos eliminar este método del abstract class.
    return Future.value(); 
  }
}