import '../models/requisition_model.dart';

abstract class RequisitionRepository {
  /// Obtiene las requisiciones filtradas por su estado (ej. 'in')
  Future<List<RequisitionModel>> getRequisitionsByStatus(String status);
  
  // Aquí agregaremos luego el método para procesar/aprobar en lote
}