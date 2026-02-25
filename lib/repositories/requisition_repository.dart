import '../models/requisition_model.dart';

abstract class RequisitionRepository {
  Future<List<RequisitionModel>> getRequisitionsByStatus(String status);
  
  Future<bool> processBatch(Map<String, int> selectedItems, String targetStatus);
}