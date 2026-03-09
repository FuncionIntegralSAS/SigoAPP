import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/models/person_model.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:dio/dio.dart'; // Asegúrate de omitir si tu proyecto usa http en vez de dio. Si es necesario quita la dependencia.

class PhysicalCountService {
  // Simula un cliente HTTP o base de datos.
  // Podrías inyectar 'NetworkClient' aquí si existe.

  Future<List<CompanyModel>> getCompanies() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const CompanyModel(id: 'C1', name: 'Empresa Principal S.A.'),
      const CompanyModel(id: 'C2', name: 'Sucursal Norte Ltda.'),
    ];
  }

  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const WarehouseModel(id: 'All', name: 'Todas'),
      const WarehouseModel(id: 'W1', name: 'Bodega Central'),
      const WarehouseModel(id: 'W2', name: 'Bodega Secundaria'),
    ];
  }

  Future<List<ArticleModel>> getArticles(String warehouseId) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const ArticleModel(
        id: 'All',
        name: 'Todos',
        licensePlate: '',
        warehouse: 'All',
      ),
      const ArticleModel(
        id: 'A1',
        name: 'Computador Portátil',
        licensePlate: 'P-001',
        warehouse: 'W1',
      ),
      const ArticleModel(
        id: 'A2',
        name: 'Silla Ergonómica',
        licensePlate: 'S-005',
        warehouse: 'W1',
      ),
    ];
  }

  Future<List<PersonModel>> searchPersons(String query) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final allPersons = [
      PersonModel(nationalId: 101, fullName: 'Juan Perez', isActive: true),
      PersonModel(nationalId: 102, fullName: 'Maria Rodriguez', isActive: true),
      PersonModel(nationalId: 103, fullName: 'Carlos Sanchez', isActive: true),
      PersonModel(nationalId: 104, fullName: 'Ana Gomez', isActive: true),
    ];

    if (query.isEmpty) return allPersons;

    return allPersons.where((p) {
      final q = query.toLowerCase();
      return p.fullName.toLowerCase().contains(q) || p.nationalId.toString().contains(q);
    }).toList();
  }

  Future<void> createPhysicalCount(PhysicalCountRequest request) async {
    // Simular latencia de red
    await Future.delayed(const Duration(seconds: 2));

    // Descomentar para simular errores:
    // throw DioException(
    //   requestOptions: RequestOptions(path: '/api/physical-count'),
    //   response: Response(statusCode: 409, requestOptions: RequestOptions(path: '')),
    //   type: DioExceptionType.badResponse,
    // );
    
    // Acá iría la lógica real usando tu cliente de red.
    // final response = await networkClient.post('/api/physical-count', data: request.toJson());
    // if (response.statusCode != 200) { throw Exception(...); }

    return; // Si no hay error, retorna exitosamente.
  }
}
