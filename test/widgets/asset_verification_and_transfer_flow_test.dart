import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/models/geolocation_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_person_model.dart';
import 'package:sigo_app/modules/inventory/providers/asset_verification_provider.dart';
import 'package:sigo_app/modules/inventory/providers/inventory_provider.dart';
import 'package:sigo_app/modules/inventory/providers/geolocation_provider.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_form_provider.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_request_provider.dart';
import 'package:sigo_app/modules/inventory/repositories/inventory_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/geolocation_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/mock_transfer_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/mock_catalog_repository.dart';
import 'package:sigo_app/modules/inventory/screens/asset_verification_screen.dart';
import 'package:sigo_app/modules/inventory/widgets/transfer_form_widget.dart';
import 'package:sigo_app/services/in_app_notification_service.dart';
import 'package:sigo_app/services/mock_inventory_service.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';

class _MockInventoryRepo implements InventoryRepository {
  List<CompanyModel> companiesToReturn = [
    const CompanyModel(codigo: '01', descripcion: 'Empresa Principal', nit: '900', estado: 'A'),
  ];
  List<WarehouseModel> warehousesToReturn = [
    const WarehouseModel(codigoBodega: 'B01', descripcionBodega: 'Bodega Principal', estadoBodega: 'A', tipo: 'PE'),
  ];
  List<ArticleModel> articlesToReturn = [];

  @override
  Future<List<CompanyModel>> getCompanies() async => companiesToReturn;

  @override
  Future<List<WarehouseModel>> getWarehouses(String companyId, {String tipo = 'PE'}) async => warehousesToReturn;

  @override
  Future<List<ArticleModel>> getArticles(String idBodega, [String? companyId]) async => articlesToReturn;
}

class _MockGeolocationRepo implements GeolocationRepository {
  @override
  Future<GeolocationModel?> getGeolocationByAssetId(int assetId) async => null;

  @override
  Future<List<GeolocationModel>> getAllGeolocations() async => [];

  @override
  Future<void> createGeolocation(GeolocationModel model) async {}

  @override
  Future<void> updateGeolocation(GeolocationModel model) async {}

  @override
  Future<void> deleteGeolocation(int assetId) async {}
}

void main() {
  group('AssetVerificationScreen & TransferFormWidget Integration Tests', () {
    late MockInventoryService inventoryService;
    late MockTransferRepository transferRepo;
    late MockCatalogRepository catalogRepo;
    late _MockInventoryRepo inventoryRepo;
    late _MockGeolocationRepo geoRepo;
    late InventoryProvider inventoryProvider;
    late TransferFormProvider formProvider;
    late TransferRequestProvider requestProvider;
    late AssetVerificationProvider verificationProvider;

    setUp(() {
      inventoryService = MockInventoryService();
      transferRepo = MockTransferRepository(inventoryService);
      catalogRepo = MockCatalogRepository();
      inventoryRepo = _MockInventoryRepo();
      geoRepo = _MockGeolocationRepo();

      inventoryProvider = InventoryProvider(
        inventoryRepo,
        transferRepository: transferRepo,
      );

      formProvider = TransferFormProvider(
        transferRepo,
        catalogRepository: catalogRepo,
      );

      verificationProvider = AssetVerificationProvider();

      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      final notificationService = InAppNotificationService(messengerKey);
      requestProvider = TransferRequestProvider(transferRepo, notificationService);
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<InventoryProvider>.value(value: inventoryProvider),
          ChangeNotifierProvider<TransferFormProvider>.value(value: formProvider),
          ChangeNotifierProvider<TransferRequestProvider>.value(value: requestProvider),
          ChangeNotifierProvider<AssetVerificationProvider>.value(value: verificationProvider),
          ChangeNotifierProvider<GeolocationProvider>(
            create: (_) => GeolocationProvider(geoRepo),
          ),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('AssetVerificationScreen carga colaboradores reales desde InventoryProvider',
        (tester) async {
      // Configuramos colaboradores en InventoryProvider
      inventoryProvider.collaborators = [
        const TransferPersonModel(
          cedula: '11111',
          nombre: 'Carlos',
          apellido: 'Ruiz',
        ),
        const TransferPersonModel(
          cedula: '22222',
          nombre: 'Maria',
          apellido: 'López',
        ),
      ];

      await tester.pumpWidget(createTestApp(const AssetVerificationScreen()));
      await tester.pumpAndSettle();

      // Verificar que el dropdown contiene colaboradores reales
      expect(find.text('Seleccione un responsable'), findsOneWidget);
      await tester.tap(find.text('Seleccione un responsable'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Carlos Ruiz'), findsWidgets);
      expect(find.text('Maria López'), findsWidgets);
    });

    testWidgets(
        'TransferFormWidget en modo contextualizado auto-preselecciona bodega destino y colaborador propuesto',
        (tester) async {
      // Bodegas disponibles
      inventoryProvider.warehouses = [
        const WarehouseModel(
          codigoBodega: 'B01',
          descripcionBodega: 'Bodega Principal',
          estadoBodega: 'A',
          tipo: 'PE',
        ),
        const WarehouseModel(
          codigoBodega: 'B02',
          descripcionBodega: 'Bodega Secundaria',
          estadoBodega: 'A',
          tipo: 'PE',
        ),
      ];

      final testArticle = ArticleModel(
        codigoActivo: 'ACT-001',
        nombre: 'Laptop Dell Latitude',
        placa: 'PLA-1234',
        bodega: 'B01',
        responsable: 'JUAN CAMILO DIAZ GOMEZ',
        centroInformacion: 'CI-01',
        tercero: 'TER-01',
        enTramite: false,
      );

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: TransferFormWidget(
              article: testArticle,
              bodegaPropuesta: 'B01',
              responsablePropuesto: 'MARIA PAULA GOMEZ SANCHEZ',
            ),
          ),
        ),
      );

      // Avanzar tiempo para completar las operaciones asíncronas con Future.delayed
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // 1. Origen fijo y activo precargado
      expect(find.text('Origen del Traspaso'), findsOneWidget);
      expect(find.textContaining('PLA-1234'), findsOneWidget);

      // 2. Colaborador fuente resuelto
      expect(formProvider.selectedOriginPerson, isNotNull);
      expect(formProvider.selectedOriginPerson!.cedula, equals('PI26055'));

      // 3. Destino pre-seleccionado con responsablePropuesto
      expect(formProvider.selectedDestinationBodega, equals('B01'));
      expect(formProvider.selectedDestinationPerson, isNotNull);
      expect(formProvider.selectedDestinationPerson!.cedula, equals('1045678901'));
      expect(formProvider.selectedDestinationPerson!.nombreCompleto,
          equals('MARIA PAULA GOMEZ SANCHEZ'));

      // 4. Activo precargado con metadata intacta
      expect(formProvider.selectedAssets.length, equals(1));
      expect(formProvider.selectedAssets.first.articulo, equals('ACT-001'));
      expect(formProvider.selectedAssets.first.centroInformacion, equals('CI-01'));
      expect(formProvider.selectedAssets.first.tercero, equals('TER-01'));
      expect(formProvider.selectedAssets.first.enTramite, isFalse);
    });

    testWidgets(
        'AssetVerificationScreen bloquea _suggestTransfer si verifiedArticle.enTramite == true',
        (tester) async {
      await tester.pumpWidget(createTestApp(const AssetVerificationScreen()));
      await tester.pumpAndSettle();

      // Acceder al estado directamente para simular artículo en trámite escaneado
      final state = tester.state(find.byType(AssetVerificationScreen))
          as dynamic;

      final tramiteArticle = ArticleModel(
        codigoActivo: 'ACT-999',
        nombre: 'Servidor Blade',
        placa: 'PLA-999',
        bodega: 'B01',
        responsable: 'Carlos Ruiz',
        enTramite: true,
      );

      state.setState(() {
        state.verifiedArticle = tramiteArticle;
        state.verificationResult = false; // Discrepancia de responsable
      });

      await tester.pumpAndSettle();

      // Verificar que el banner de activo en trámite se muestra
      expect(
        find.text(
          'Activo en trámite de traspaso pendiente. No se pueden generar nuevas solicitudes.',
        ),
        findsOneWidget,
      );

      // Intentar pulsar el botón de sugerencia de traspaso
      final suggestButton = find.text('Se sugiere realizar un traspaso');
      expect(suggestButton, findsOneWidget);
      await tester.ensureVisible(suggestButton);
      await tester.tap(suggestButton);
      await tester.pumpAndSettle();

      // Verificar que no se abrió TransferFormWidget modal
      expect(find.byType(TransferFormWidget), findsNothing);

      // Verificar que se mostró el SnackBar de advertencia
      expect(
        find.text('El activo ya se encuentra en un trámite de traspaso pendiente.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'AssetVerificationScreen renderiza lista de activos esperados y actualiza estado visual al verificar',
        (tester) async {
      final article1 = ArticleModel(
        codigoActivo: 'ACT-001',
        nombre: 'Laptop Dell Latitude',
        placa: 'PLA-100',
        bodega: 'B01',
        responsable: 'Carlos Ruiz',
      );
      final article2 = ArticleModel(
        codigoActivo: 'ACT-002',
        nombre: 'Monitor LG 27"',
        placa: '',
        bodega: 'B01',
        responsable: 'Carlos Ruiz',
      );

      inventoryProvider.collaborators = [
        const TransferPersonModel(cedula: '11111', nombre: 'Carlos', apellido: 'Ruiz'),
      ];
      inventoryProvider.selectedCollaborator = inventoryProvider.collaborators.first;
      inventoryProvider.articles = [article1, article2];

      await tester.pumpWidget(createTestApp(const AssetVerificationScreen()));
      await tester.pumpAndSettle();

      // Verificar cabecera y conteos
      expect(find.text('Activos Asignados (2)'), findsOneWidget);

      // Verificar formato estricto: código - placa - nombre
      expect(find.text('ACT-001 - PLA-100 - Laptop Dell Latitude'), findsOneWidget);
      expect(find.text('ACT-002 - SIN PLACA - Monitor LG 27"'), findsOneWidget);

      // Ambos inician como 'Pendiente'
      expect(find.text('Pendiente'), findsNWidgets(2));
      expect(find.text('Verificado'), findsNothing);

      // Simular verificación del primer artículo
      verificationProvider.verifyAsset(article1, inventoryProvider.articles);
      await tester.pumpAndSettle();

      // Ahora 1 Verificado y 1 Pendiente
      expect(find.text('Verificado'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets(
        'AssetVerificationScreen despliega sección de conflicto con sugerencia de traspaso',
        (tester) async {
      final expectedArticle = ArticleModel(
        codigoActivo: 'ACT-001',
        nombre: 'Laptop Dell',
        placa: 'PLA-100',
        bodega: 'B01',
      );
      final conflictArticle = ArticleModel(
        codigoActivo: 'ACT-999',
        nombre: 'Impresora Láser',
        placa: '',
        bodega: 'B02',
        responsable: 'Maria López',
        enTramite: false,
      );

      inventoryProvider.collaborators = [
        const TransferPersonModel(cedula: '11111', nombre: 'Carlos', apellido: 'Ruiz'),
      ];
      inventoryProvider.selectedCollaborator = inventoryProvider.collaborators.first;
      inventoryProvider.articles = [expectedArticle];

      await tester.pumpWidget(createTestApp(const AssetVerificationScreen()));
      await tester.pumpAndSettle();

      // Simular escaneo de activo en conflicto
      verificationProvider.verifyAsset(conflictArticle, inventoryProvider.articles);
      await tester.pumpAndSettle();

      // Sección de conflicto visible
      expect(find.textContaining('Activos en Conflicto / No Esperados (1)'), findsOneWidget);
      expect(find.text('ACT-999 - SIN PLACA - Impresora Láser'), findsOneWidget);
      expect(find.text('Responsable actual: Maria López'), findsOneWidget);
      expect(find.text('Se sugiere realizar un traspaso'), findsOneWidget);
    });
  });
}
