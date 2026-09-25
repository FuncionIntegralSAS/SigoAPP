/// Modelos de dominio y DTOs para el Módulo de Requisiciones de Suministro.
///
/// Basado en la especificación técnica de PKG_FI_REQUISICION y RequisicionController.
library;

/// Tipo de documento de requisición gestionable (configurado en EQUIVALE).
class RequisicionTipoDocumento {
  final String codigo;
  final String nombre;

  const RequisicionTipoDocumento({
    required this.codigo,
    required this.nombre,
  });

  factory RequisicionTipoDocumento.fromJson(Map<String, dynamic> json) {
    return RequisicionTipoDocumento(
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre': nombre,
  };
}

/// Clave identificadora de línea dentro de una requisición.
class RequisicionLineaKey {
  final String articulo;
  final String bodega;
  final num secuencia;

  const RequisicionLineaKey({
    required this.articulo,
    required this.bodega,
    required this.secuencia,
  });

  factory RequisicionLineaKey.fromJson(Map<String, dynamic> json) {
    return RequisicionLineaKey(
      articulo: json['articulo']?.toString() ?? '',
      bodega: json['bodega']?.toString() ?? '',
      secuencia: json['secuencia'] is num
          ? json['secuencia'] as num
          : num.tryParse(json['secuencia']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'articulo': articulo,
    'bodega': bodega,
    'secuencia': secuencia,
  };
}

/// DTO de línea para operaciones de Aprobación, Entrega y Registro.
class RequisicionLineaItem {
  final String articulo;
  final String bodega;
  final num secuencia;
  final double cantidad;
  final List<String>? placas;

  const RequisicionLineaItem({
    required this.articulo,
    required this.bodega,
    required this.secuencia,
    required this.cantidad,
    this.placas,
  });

  factory RequisicionLineaItem.fromJson(Map<String, dynamic> json) {
    return RequisicionLineaItem(
      articulo: json['articulo']?.toString() ?? '',
      bodega: json['bodega']?.toString() ?? '',
      secuencia: json['secuencia'] is num
          ? json['secuencia'] as num
          : num.tryParse(json['secuencia']?.toString() ?? '0') ?? 0,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      placas: (json['placas'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'articulo': articulo,
    'bodega': bodega,
    'secuencia': secuencia,
    'cantidad': cantidad,
    if (placas != null && placas!.isNotEmpty) 'placas': placas,
  };
}

/// Detalle de una línea dentro de una requisición consultada por terna.
class RequisicionDetalleLinea {
  final String articulo;
  final String bodega;
  final num secuencia;
  final String descripcion;
  final String unidad;
  final String estado;
  final double solicitada;
  final double aprobada;
  final double entregada;
  final double anulada;
  final double recibida;
  final double pendiente;
  final String? usuarioAprueba;
  final String? fechaAprobacion;
  final List<String> placas;

  const RequisicionDetalleLinea({
    required this.articulo,
    required this.bodega,
    required this.secuencia,
    required this.descripcion,
    required this.unidad,
    required this.estado,
    required this.solicitada,
    required this.aprobada,
    required this.entregada,
    required this.anulada,
    required this.recibida,
    required this.pendiente,
    this.usuarioAprueba,
    this.fechaAprobacion,
    this.placas = const [],
  });

  factory RequisicionDetalleLinea.fromJson(Map<String, dynamic> json) {
    return RequisicionDetalleLinea(
      articulo: json['articulo']?.toString() ?? '',
      bodega: json['bodega']?.toString() ?? '',
      secuencia: json['secuencia'] is num
          ? json['secuencia'] as num
          : num.tryParse(json['secuencia']?.toString() ?? '0') ?? 0,
      descripcion: json['descripcion']?.toString() ?? '',
      unidad: json['unidad']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      solicitada: (json['solicitada'] as num?)?.toDouble() ?? 0.0,
      aprobada: (json['aprobada'] as num?)?.toDouble() ?? 0.0,
      entregada: (json['entregada'] as num?)?.toDouble() ?? 0.0,
      anulada: (json['anulada'] as num?)?.toDouble() ?? 0.0,
      recibida: (json['recibida'] as num?)?.toDouble() ?? 0.0,
      pendiente: (json['pendiente'] as num?)?.toDouble() ?? 0.0,
      usuarioAprueba: json['usuarioAprueba']?.toString(),
      fechaAprobacion: json['fechaAprobacion']?.toString(),
      placas: (json['placas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'articulo': articulo,
    'bodega': bodega,
    'secuencia': secuencia,
    'descripcion': descripcion,
    'unidad': unidad,
    'estado': estado,
    'solicitada': solicitada,
    'aprobada': aprobada,
    'entregada': entregada,
    'anulada': anulada,
    'recibida': recibida,
    'pendiente': pendiente,
    'usuarioAprueba': usuarioAprueba,
    'fechaAprobacion': fechaAprobacion,
    'placas': placas,
  };
}

/// Estado y metadatos de una firma digital en la requisición.
class RequisicionFirma {
  final int posicion;
  final String tipo; // SA (Salida) o RE (Recibo)
  final String? persona;
  final String? nombre;
  final String? fecha;
  final bool firmada;
  final String? firma;

  const RequisicionFirma({
    this.posicion = 0,
    required this.tipo,
    this.persona,
    this.nombre,
    this.fecha,
    required this.firmada,
    this.firma,
  });

  /// Getter de compatibilidad con código existente.
  String? get fechaFirma => fecha;

  factory RequisicionFirma.fromJson(Map<String, dynamic> json) {
    final rawFecha = json['fecha']?.toString() ?? json['fechaFirma']?.toString();
    final hasFecha = rawFecha != null && rawFecha.trim().isNotEmpty;
    final isExplicitFirmada = json['firmada'] == true || json['firmada']?.toString() == 'true';

    return RequisicionFirma(
      posicion: json['posicion'] is int
          ? json['posicion'] as int
          : int.tryParse(json['posicion']?.toString() ?? '0') ?? 0,
      tipo: json['tipo']?.toString() ?? '',
      persona: json['persona']?.toString(),
      nombre: json['nombre']?.toString() ?? json['nombrePersona']?.toString(),
      fecha: rawFecha,
      firmada: hasFecha || isExplicitFirmada,
      firma: json['firma']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'posicion': posicion,
    'tipo': tipo,
    if (persona != null) 'persona': persona,
    if (nombre != null) 'nombre': nombre,
    if (fecha != null) 'fecha': fecha,
    if (fecha != null) 'fechaFirma': fecha,
    'firmada': firmada,
    if (firma != null) 'firma': firma,
  };
}

/// Detalle completo de requisición (Cabecera, Líneas y Firmas).
class RequisicionDetalle {
  final String empresa;
  final String tipoDocumento;
  final dynamic numero;
  final String estado;
  final String fecha;
  final String? fechaRequerida;
  final String? observacion;
  final String bodega;
  final String? bodegaDestino;
  final String? centroInformacion;
  final String? tercero;
  final String? responsableBodega;
  final String? responsableBodegaDestino;
  final List<RequisicionDetalleLinea> lineas;
  final List<RequisicionFirma> firmas;

  const RequisicionDetalle({
    required this.empresa,
    required this.tipoDocumento,
    required this.numero,
    required this.estado,
    required this.fecha,
    this.fechaRequerida,
    this.observacion,
    required this.bodega,
    this.bodegaDestino,
    this.centroInformacion,
    this.tercero,
    this.responsableBodega,
    this.responsableBodegaDestino,
    this.lineas = const [],
    this.firmas = const [],
  });

  RequisicionDetalle copyWith({
    String? empresa,
    String? tipoDocumento,
    dynamic numero,
    String? estado,
    String? fecha,
    String? fechaRequerida,
    String? observacion,
    String? bodega,
    String? bodegaDestino,
    String? centroInformacion,
    String? tercero,
    String? responsableBodega,
    String? responsableBodegaDestino,
    List<RequisicionDetalleLinea>? lineas,
    List<RequisicionFirma>? firmas,
  }) {
    return RequisicionDetalle(
      empresa: empresa ?? this.empresa,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numero: numero ?? this.numero,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      fechaRequerida: fechaRequerida ?? this.fechaRequerida,
      observacion: observacion ?? this.observacion,
      bodega: bodega ?? this.bodega,
      bodegaDestino: bodegaDestino ?? this.bodegaDestino,
      centroInformacion: centroInformacion ?? this.centroInformacion,
      tercero: tercero ?? this.tercero,
      responsableBodega: responsableBodega ?? this.responsableBodega,
      responsableBodegaDestino: responsableBodegaDestino ?? this.responsableBodegaDestino,
      lineas: lineas ?? this.lineas,
      firmas: firmas ?? this.firmas,
    );
  }

  factory RequisicionDetalle.fromJson(Map<String, dynamic> json) {
    return RequisicionDetalle(
      empresa: json['empresa']?.toString() ?? '',
      tipoDocumento: json['tipoDocumento']?.toString() ?? '',
      numero: json['numero'] ?? '',
      estado: json['estado']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      fechaRequerida: json['fechaRequerida']?.toString(),
      observacion: json['observacion']?.toString(),
      bodega: json['bodega']?.toString() ?? '',
      bodegaDestino: json['bodegaDestino']?.toString(),
      centroInformacion: json['centroInformacion']?.toString(),
      tercero: json['tercero']?.toString(),
      responsableBodega: json['responsableBodega']?.toString(),
      responsableBodegaDestino: json['responsableBodegaDestino']?.toString(),
      lineas: (json['lineas'] as List<dynamic>?)
              ?.map((e) => RequisicionDetalleLinea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      firmas: (json['firmas'] as List<dynamic>?)
              ?.map((e) => RequisicionFirma.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'empresa': empresa,
    'tipoDocumento': tipoDocumento,
    'numero': numero,
    'estado': estado,
    'fecha': fecha,
    'fechaRequerida': fechaRequerida,
    'observacion': observacion,
    'bodega': bodega,
    'bodegaDestino': bodegaDestino,
    'centroInformacion': centroInformacion,
    'tercero': tercero,
    'responsableBodega': responsableBodega,
    'responsableBodegaDestino': responsableBodegaDestino,
    'lineas': lineas.map((e) => e.toJson()).toList(),
    'firmas': firmas.map((e) => e.toJson()).toList(),
  };
}

/// Resumen de bandeja de requisición (GET /api/v1/requisiciones).
class RequisicionResumen {
  final String empresa;
  final String tipoDocumento;
  final dynamic numero;
  final String estado;
  final String fecha;
  final String bodega;
  final int lineas;

  const RequisicionResumen({
    required this.empresa,
    required this.tipoDocumento,
    required this.numero,
    required this.estado,
    required this.fecha,
    required this.bodega,
    required this.lineas,
  });

  RequisicionResumen copyWith({
    String? empresa,
    String? tipoDocumento,
    dynamic numero,
    String? estado,
    String? fecha,
    String? bodega,
    int? lineas,
  }) {
    return RequisicionResumen(
      empresa: empresa ?? this.empresa,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numero: numero ?? this.numero,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      bodega: bodega ?? this.bodega,
      lineas: lineas ?? this.lineas,
    );
  }

  factory RequisicionResumen.fromJson(Map<String, dynamic> json) {
    return RequisicionResumen(
      empresa: json['empresa']?.toString() ?? '',
      tipoDocumento: json['tipoDocumento']?.toString() ?? '',
      numero: json['numero'] ?? '',
      estado: json['estado']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      bodega: json['bodega']?.toString() ?? '',
      lineas: json['lineas'] is int
          ? json['lineas'] as int
          : int.tryParse(json['lineas']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'empresa': empresa,
    'tipoDocumento': tipoDocumento,
    'numero': numero,
    'estado': estado,
    'fecha': fecha,
    'bodega': bodega,
    'lineas': lineas,
  };
}

/// Petición para registrar firma en la requisición.
class RequisicionFirmaRequest {
  final String tipo; // SA o RE
  final String persona;
  final String firma; // Imagen Base64

  const RequisicionFirmaRequest({
    required this.tipo,
    required this.persona,
    required this.firma,
  });

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'persona': persona,
    'firma': firma,
  };
}

/// Petición opcional para registrar salida ERP con discrepancia/parcial.
class RequisicionRegistrarRequest {
  final List<RequisicionLineaItem>? lineas;

  const RequisicionRegistrarRequest({this.lineas});

  Map<String, dynamic> toJson() => {
    if (lineas != null && lineas!.isNotEmpty)
      'lineas': lineas!.map((e) => e.toJson()).toList(),
  };
}

/// Modelo de ítem de requisición consumido por las tarjetas y vistas de la UI.
///
/// Preserva compatibilidad completa con [RequisitionActionCard] y las pestañas
/// actuales mientras conecta directamente con la terna y líneas de Spring Boot.
class RequisitionModel {
  final String id;
  final String articulo;
  final String solicita;
  final int cantidadSolicitada;
  final int cantidadAprobada;
  final int cantidadEntregada;
  final String estado;
  final String empresa;
  final String tipoDocumento;
  final String numero;
  final String fecha;
  final String bodega;
  final String unidad;
  final String observacion;
  final num secuencia;
  final List<String> placas;

  const RequisitionModel({
    required this.id,
    required this.articulo,
    required this.solicita,
    required this.cantidadSolicitada,
    required this.cantidadAprobada,
    required this.cantidadEntregada,
    required this.estado,
    required this.empresa,
    required this.tipoDocumento,
    required this.numero,
    required this.fecha,
    required this.bodega,
    required this.unidad,
    required this.observacion,
    this.secuencia = 1,
    this.placas = const [],
  });

  factory RequisitionModel.fromJson(Map<String, dynamic> json) {
    return RequisitionModel(
      id: json['id']?.toString() ?? '',
      articulo: json['articulo']?.toString() ?? '',
      solicita: json['solicita']?.toString() ?? '',
      cantidadSolicitada: (json['cantidadSolicitada'] as num?)?.toInt() ?? 0,
      cantidadAprobada: (json['cantidadAprobada'] as num?)?.toInt() ?? 0,
      cantidadEntregada: (json['cantidadEntregada'] as num?)?.toInt() ?? 0,
      estado: json['estado']?.toString() ?? '',
      empresa: json['empresa']?.toString() ?? '',
      tipoDocumento: json['tipoDocumento']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      bodega: json['bodega']?.toString() ?? '',
      unidad: json['unidad']?.toString() ?? '',
      observacion: json['observacion']?.toString() ?? '',
      secuencia: json['secuencia'] is num
          ? json['secuencia'] as num
          : num.tryParse(json['secuencia']?.toString() ?? '1') ?? 1,
      placas: (json['placas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  factory RequisitionModel.fromDetalleLinea({
    required RequisicionDetalle detalle,
    required RequisicionDetalleLinea linea,
  }) {
    final composite =
        '${detalle.empresa}_${detalle.tipoDocumento}_${detalle.numero}_${linea.bodega}_${linea.articulo}_${linea.secuencia}';
    final descArticulo = linea.descripcion.isNotEmpty
        ? '${linea.articulo} - ${linea.descripcion}'
        : linea.articulo;
    return RequisitionModel(
      id: composite,
      articulo: descArticulo,
      solicita: detalle.tercero ?? '',
      cantidadSolicitada: linea.solicitada.round(),
      cantidadAprobada: linea.aprobada.round(),
      cantidadEntregada: linea.entregada.round(),
      estado: linea.estado.isNotEmpty ? linea.estado : detalle.estado,
      empresa: detalle.empresa,
      tipoDocumento: detalle.tipoDocumento,
      numero: detalle.numero.toString(),
      fecha: detalle.fecha,
      bodega: linea.bodega,
      unidad: linea.unidad,
      observacion: detalle.observacion ?? '',
      secuencia: linea.secuencia,
      placas: linea.placas,
    );
  }

  String get compositeId =>
      '${empresa}_${tipoDocumento}_${numero}_${bodega}_$articulo';

  String get lineKey =>
      '${empresa}_${tipoDocumento}_${numero}_${bodega}_${articulo}_$secuencia';
}
