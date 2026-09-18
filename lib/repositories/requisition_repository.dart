import '../models/company_model.dart';
import '../models/requisition_model.dart';

/// Contrato abstracto para el Módulo de Requisiciones de Suministro.
///
/// Define las operaciones de consulta por terna, aprobación, entrega física,
/// anulación, firma digital y registro de salida definitiva en ERP.
abstract class RequisitionRepository {
  /// Consulta el catálogo maestro de empresas disponibles (GET /api/v1/empresas).
  Future<List<CompanyModel>> getCompanies();

  /// Consulta las requisiciones en la bandeja y aplana sus líneas para la UI.
  Future<List<RequisitionModel>> getRequisitionsByStatus(
    String status, {
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  });

  /// Procesa la aprobación o entrega masiva de los ítems seleccionados.
  Future<bool> processBatch(
    Map<String, int> selectedItems,
    String targetStatus, {
    List<RequisitionModel>? requisitions,
  });

  /// Consulta los tipos de documento gestionables en EQUIVALE (GET /tipos).
  Future<List<RequisicionTipoDocumento>> getDocumentTypes();

  /// Consulta la bandeja de requisiciones (GET /api/v1/requisiciones).
  Future<List<RequisicionResumen>> getRequisitions({
    String? estado,
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  });

  /// Obtiene el detalle completo de una requisición por terna (GET /{empresa}/{tipo}/{num}).
  Future<RequisicionDetalle> getRequisitionDetail(
    String empresa,
    String tipoDocumento,
    String numero,
  );

  /// Autoriza cantidades de una o más líneas (PUT /{empresa}/{tipo}/{num}/aprobar).
  Future<void> approveLines(
    String empresa,
    String tipoDocumento,
    String numero,
    List<RequisicionLineaItem> lineas,
  );

  /// Sella entrega física y asigna placas (PUT /{empresa}/{tipo}/{num}/entregar).
  Future<void> deliverLines(
    String empresa,
    String tipoDocumento,
    String numero,
    List<RequisicionLineaItem> lineas,
  );

  /// Anula saldo aprobado de líneas sin entrega (PUT /{empresa}/{tipo}/{num}/anular).
  Future<void> annulLines(
    String empresa,
    String tipoDocumento,
    String numero,
    List<RequisicionLineaKey> lineas,
  );

  /// Guarda firma manuscrita digital SA o RE (PUT /{empresa}/{tipo}/{num}/firmar).
  Future<void> signRequisition(
    String empresa,
    String tipoDocumento,
    String numero,
    RequisicionFirmaRequest request,
  );

  /// Asienta la salida definitiva en inventario ERP (PUT /{empresa}/{tipo}/{num}/registrar).
  Future<Map<String, dynamic>> registerExit(
    String empresa,
    String tipoDocumento,
    String numero, {
    RequisicionRegistrarRequest? request,
  });
}