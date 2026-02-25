import '../models/requisition_model.dart';
import '../repositories/requisition_repository.dart';

class MockRequisitionService implements RequisitionRepository {
  // Añade este método dentro de tu clase MockRequisitionService
  @override
  Future<bool> processBatch(Map<String, int> selectedItems, String targetStatus) async {

    await Future.delayed(const Duration(seconds: 2));
    
    // Aquí es donde en el futuro harás un POST a tu API de Oracle.
    
    // Simulamos que la operación fue exitosa
    return true; 
  }

  @override
  Future<List<RequisitionModel>> getRequisitionsByStatus(String status) async {
    // Simulamos latencia de red de 1 segundo
    await Future.delayed(const Duration(seconds: 1));

    final allRequisitions = [
      RequisitionModel(
        id: 'REQ-001',
        articulo: 'ART-001 - Disco Solido SSD 1TB',
        solicita: 'EMP-40 - Carlos Rodriguez',
        cantidadSolicitada: 10,
        cantidadAprobada: 0,
        cantidadEntregada: 0,
        estado: 'in',
        empresa: 'Tech Corp S.A.',
        tipoDocumento: 'REQ - Requisición Interna',
        numero: '000451',
        fecha: '23-Feb-2026',
        bodega: 'BOD-01 - Bodega Central',
        unidad: 'UND - Unidades',
        observacion: 'Actualización del departamento de finanzas.',
      ),
      RequisitionModel(
        id: 'REQ-002',
        articulo: 'ART-002 - Memoria RAM 16GB',
        solicita: 'EMP-41 - Ana Gomez',
        cantidadSolicitada: 5,
        cantidadAprobada: 0,
        cantidadEntregada: 0,
        estado: 'ap',
        empresa: 'Tech Corp S.A.',
        tipoDocumento: 'REQ - Requisición Interna',
        numero: '000452',
        fecha: '22-Feb-2026',
        bodega: 'BOD-01 - Bodega Central',
        unidad: 'UND - Unidades',
        observacion: 'Reparación de equipos.',
      ),
      RequisitionModel(
        id: 'REQ-003',
        articulo: 'ART-003 - Tarjeta grafica AMD',
        solicita: 'EMP-40 - Carlos Rodriguez',
        cantidadSolicitada: 10,
        cantidadAprobada: 0,
        cantidadEntregada: 0,
        estado: 'in',
        empresa: 'Tech Corp S.A.',
        tipoDocumento: 'REQ - Requisición Interna',
        numero: '000451',
        fecha: '23-Feb-2026',
        bodega: 'BOD-01 - Bodega Central',
        unidad: 'UND - Unidades',
        observacion: 'Actualización del departamento de finanzas.',
      ),
    ];

    // El backend (o en este caso el mock) se encarga de filtrar
    return allRequisitions.where((req) => req.estado == status).toList();
  }
}