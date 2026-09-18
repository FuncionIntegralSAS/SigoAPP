/// Catálogo de Estados del Traspaso (Spring Boot / FI_MOVITRAS):
/// - `pe`: Pendiente de aprobación administrativa.
/// - `ap`: Aprobado. Habilitado para que las partes firmen (no afecta inventario aún).
/// - `na`: Rechazado con motivo obligatorio.
/// - `re`: Recibido. Ambas partes han firmado y se genera el inventario en ERP.
/// - `pr`: Estado agrupador de procesados en consultas (`ap`, `na`, `re`).
enum TransferStatus {
  pending,
  approved,
  rejected,
  received,
  completed,
  // Compatibilidad con registros o simulaciones previas
  sourceSigned,
  targetSigned,
}

/// Representa un artículo individual dentro de un trámite multi-artículo
class TransferArticleItem {
  final String articulo;
  final String? placa;
  final String? nombre;

  const TransferArticleItem({
    required this.articulo,
    this.placa,
    this.nombre,
  });

  factory TransferArticleItem.fromJson(Map<String, dynamic> json) {
    return TransferArticleItem(
      articulo: (json['articulo'] ?? json['elemento'] ?? json['idArticulo'] ?? '').toString(),
      placa: (json['placa'] ?? json['placaElemento'])?.toString(),
      nombre: (json['nombre'] ?? json['descripcion'] ?? json['nombreElemento'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'articulo': articulo,
        if (placa != null) 'placa': placa,
        if (nombre != null) 'nombre': nombre,
      };

  TransferArticleItem copyWith({
    String? articulo,
    String? placa,
    String? nombre,
  }) {
    return TransferArticleItem(
      articulo: articulo ?? this.articulo,
      placa: placa ?? this.placa,
      nombre: nombre ?? this.nombre,
    );
  }

  @override
  String toString() => 'TransferArticleItem(articulo: $articulo, placa: $placa, nombre: $nombre)';
}

/// Representa una firma digital capturada en la entidad FI_MOTRFIRM
class TransferFirmItem {
  final int posicion; // 1: Fuente (FU) / Entrega, 2: Destino (DE) / Recibe
  final String tipo; // "FU" o "DE"
  final DateTime? fechaFirma;
  final bool firmada;
  final String? firma; // Base64 de la imagen

  const TransferFirmItem({
    required this.posicion,
    required this.tipo,
    this.fechaFirma,
    this.firmada = false,
    this.firma,
  });

  factory TransferFirmItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedFecha;
    final rawFecha = json['fechaFirma'];
    if (rawFecha is String) {
      parsedFecha = DateTime.tryParse(rawFecha);
    }

    final rawPos = json['posicion'];
    final pos = rawPos is int
        ? rawPos
        : (int.tryParse(rawPos?.toString() ?? '1') ?? 1);

    final rawTipo = (json['tipo'] ?? (pos == 1 ? 'FU' : 'DE')).toString();
    final bool isFirmada = json['firmada'] == true ||
        (json['firma'] != null && json['firma'].toString().isNotEmpty);

    return TransferFirmItem(
      posicion: pos,
      tipo: rawTipo,
      fechaFirma: parsedFecha,
      firmada: isFirmada,
      firma: json['firma']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'posicion': posicion,
        'tipo': tipo,
        if (fechaFirma != null) 'fechaFirma': fechaFirma!.toIso8601String(),
        'firmada': firmada,
        if (firma != null) 'firma': firma,
      };
}

/// Modelo de datos para una Solicitud o Trámite de Traspaso.
///
/// Soporta trámites multi-artículo agrupados bajo [id] (`numeroTramite` / `MOTRNUTR`),
/// así como la bandeja ligera (`GET /list`) y el detalle completo (`GET /get/{id}`).
class TransferRequest {
  /// Número de trámite que agrupa todos los artículos (MOTRNUTR)
  final String id;
  final String? empresaDocumento;
  final String? tipoDocumento;
  final int? numeroDocumento;
  final String responsableActual; // personaFuente
  final String responsablePropuesto; // personaDestino
  /// Código o cédula original de quien entrega (personaFuente en backend/ERP)
  final String? personaFuente;

  /// Código o cédula original de quien recibe (personaDestino en backend/ERP)
  final String? personaDestino;

  final String bodegaActual;
  final String bodegaPropuesta;
  final String motivoSolicitud; // observacion
  final String? motivoRechazo;
  final DateTime fechaSolicitud; // fechaCreacion
  final DateTime? fechaAplicacion;
  final DateTime? fechaAprobacion;
  final DateTime? fechaRecibe;
  final String? usuarioCreacion;
  final String? usuarioAprobacion;
  final TransferStatus estado;

  /// Lista estructurada de artículos incluidos en este trámite
  final List<TransferArticleItem> articulos;

  /// Lista estructurada de firmas (posición 1: Fuente, posición 2: Destino)
  final List<TransferFirmItem> firmas;

  // Propiedades auxiliares para retrocompatibilidad
  final String? firmaDespachadorBase64;
  final String? firmaReceptorBase64;
  final String? _legacyIdArticulo;
  final String? _legacyNombreArticulo;
  final String? _legacyPlaca;

  TransferRequest({
    required this.id,
    String? idArticulo,
    String? nombreArticulo,
    this.responsableActual = '',
    this.responsablePropuesto = '',
    String? personaFuente,
    String? personaDestino,
    this.bodegaActual = '',
    this.bodegaPropuesta = '',
    this.motivoSolicitud = '',
    required this.fechaSolicitud,
    this.empresaDocumento,
    this.tipoDocumento,
    this.numeroDocumento,
    this.fechaAplicacion,
    this.fechaAprobacion,
    this.fechaRecibe,
    this.usuarioCreacion,
    this.usuarioAprobacion,
    this.estado = TransferStatus.pending,
    this.motivoRechazo,
    this.articulos = const [],
    this.firmas = const [],
    this.firmaDespachadorBase64,
    this.firmaReceptorBase64,
    String? placa,
  })  : personaFuente = (personaFuente != null && personaFuente.trim().isNotEmpty)
            ? personaFuente.trim()
            : (responsableActual.trim().isNotEmpty ? responsableActual.trim() : null),
        personaDestino = (personaDestino != null && personaDestino.trim().isNotEmpty)
            ? personaDestino.trim()
            : (responsablePropuesto.trim().isNotEmpty ? responsablePropuesto.trim() : null),
        _legacyIdArticulo = idArticulo,
        _legacyNombreArticulo = nombreArticulo,
        _legacyPlaca = placa;

  // --- GETTERS INTELIGENTES PARA UI Y COMPATIBILIDAD ---

  /// Código o cédula de quien entrega con fallback a responsableActual
  String get codigoFuente =>
      (personaFuente != null && personaFuente!.trim().isNotEmpty)
          ? personaFuente!.trim()
          : responsableActual.trim();

  /// Código o cédula de quien recibe con fallback a responsablePropuesto
  String get codigoDestino =>
      (personaDestino != null && personaDestino!.trim().isNotEmpty)
          ? personaDestino!.trim()
          : responsablePropuesto.trim();

  /// Código del primer artículo o del legacy si no hay lista
  String get idArticulo =>
      articulos.isNotEmpty ? articulos.first.articulo : (_legacyIdArticulo ?? id);

  /// Título o resumen de artículos para la tarjeta
  String get nombreArticulo {
    if (articulos.isNotEmpty) {
      final firstDesc = articulos.first.nombre;
      final displayFirst = (firstDesc != null && firstDesc.trim().isNotEmpty)
          ? firstDesc.trim()
          : articulos.first.articulo;
      if (articulos.length == 1) {
        return displayFirst;
      }
      return '$displayFirst (+${articulos.length - 1} artículos más)';
    }
    if (_legacyNombreArticulo != null && _legacyNombreArticulo.isNotEmpty) {
      return _legacyNombreArticulo;
    }
    if (numeroDocumento != null) {
      return '${tipoDocumento ?? "TR"} #$numeroDocumento';
    }
    return 'Trámite #$id';
  }

  /// Placa del primer artículo si existe
  String? get placa =>
      articulos.isNotEmpty ? articulos.first.placa : _legacyPlaca;

  /// Indica si la parte despachadora / fuente (FU) ya firmó
  bool get isSourceSigned =>
      firmas.any((f) => f.tipo == 'FU' && f.firmada) ||
      (firmaDespachadorBase64 != null && firmaDespachadorBase64!.isNotEmpty) ||
      estado == TransferStatus.sourceSigned ||
      estado == TransferStatus.received;

  /// Indica si la parte receptora / destino (DE) ya firmó
  bool get isTargetSigned =>
      firmas.any((f) => f.tipo == 'DE' && f.firmada) ||
      (firmaReceptorBase64 != null && firmaReceptorBase64!.isNotEmpty) ||
      estado == TransferStatus.targetSigned ||
      estado == TransferStatus.received;

  /// Indica si ambas partes ya firmaron y el trámite está listo para confirmar recepción ERP
  bool get bothSigned => isSourceSigned && isTargetSigned;

  /// Retorna la firma Base64 de la fuente si existe
  String? get sourceSignatureBase64 {
    for (final f in firmas) {
      if (f.tipo == 'FU' && f.firmada && f.firma != null) return f.firma;
    }
    return firmaDespachadorBase64;
  }

  /// Retorna la firma Base64 del destino si existe
  String? get targetSignatureBase64 {
    for (final f in firmas) {
      if (f.tipo == 'DE' && f.firmada && f.firma != null) return f.firma;
    }
    return firmaReceptorBase64;
  }

  TransferRequest copyWith({
    TransferStatus? estado,
    String? motivoRechazo,
    DateTime? fechaAplicacion,
    DateTime? fechaAprobacion,
    DateTime? fechaRecibe,
    String? firmaDespachadorBase64,
    String? firmaReceptorBase64,
    String? placa,
    List<TransferArticleItem>? articulos,
    List<TransferFirmItem>? firmas,
    String? bodegaActual,
    String? bodegaPropuesta,
    String? responsableActual,
    String? responsablePropuesto,
    String? personaFuente,
    String? personaDestino,
  }) {
    return TransferRequest(
      id: id,
      idArticulo: _legacyIdArticulo,
      nombreArticulo: _legacyNombreArticulo,
      responsableActual: responsableActual ?? this.responsableActual,
      responsablePropuesto: responsablePropuesto ?? this.responsablePropuesto,
      personaFuente: personaFuente ?? this.personaFuente,
      personaDestino: personaDestino ?? this.personaDestino,
      bodegaActual: bodegaActual ?? this.bodegaActual,
      bodegaPropuesta: bodegaPropuesta ?? this.bodegaPropuesta,
      motivoSolicitud: motivoSolicitud,
      fechaSolicitud: fechaSolicitud,
      empresaDocumento: empresaDocumento,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      fechaRecibe: fechaRecibe ?? this.fechaRecibe,
      usuarioCreacion: usuarioCreacion,
      usuarioAprobacion: usuarioAprobacion,
      estado: estado ?? this.estado,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      articulos: articulos ?? this.articulos,
      firmas: firmas ?? this.firmas,
      firmaDespachadorBase64:
          firmaDespachadorBase64 ?? this.firmaDespachadorBase64,
      firmaReceptorBase64: firmaReceptorBase64 ?? this.firmaReceptorBase64,
      placa: placa ?? _legacyPlaca,
    );
  }

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    // Mapeo tolerante de estados
    final String rawStatus =
        (json['estado'] ?? json['status'] ?? 'pe').toString().toLowerCase();
    TransferStatus resolvedStatus;
    switch (rawStatus) {
      case 'ap':
        resolvedStatus = TransferStatus.approved;
        break;
      case 'na':
        resolvedStatus = TransferStatus.rejected;
        break;
      case 're':
        resolvedStatus = TransferStatus.received;
        break;
      case 'pr':
        resolvedStatus = TransferStatus.completed;
        break;
      case 'af':
        resolvedStatus = TransferStatus.sourceSigned;
        break;
      case 'ad':
        resolvedStatus = TransferStatus.targetSigned;
        break;
      case 'pe':
      default:
        resolvedStatus = TransferStatus.pending;
        break;
    }

    DateTime parsedFechaSolicitud;
    final rawFecha = json['fechaCreacion'] ?? json['fechaSolicitud'];
    if (rawFecha is String) {
      parsedFechaSolicitud = DateTime.tryParse(rawFecha) ?? DateTime.now();
    } else {
      parsedFechaSolicitud = DateTime.now();
    }

    DateTime? parsedFechaAplicacion;
    final rawFechaApp =
        json['fechaAprobacion'] ?? json['fechaRecibe'] ?? json['fechaAplicacion'];
    if (rawFechaApp is String) {
      parsedFechaAplicacion = DateTime.tryParse(rawFechaApp);
    }

    DateTime? parsedFechaAprobacion;
    if (json['fechaAprobacion'] is String) {
      parsedFechaAprobacion = DateTime.tryParse(json['fechaAprobacion']);
    }

    DateTime? parsedFechaRecibe;
    if (json['fechaRecibe'] is String) {
      parsedFechaRecibe = DateTime.tryParse(json['fechaRecibe']);
    }

    // Parseo de lista estructurada de artículos (multi-artículo)
    List<TransferArticleItem> parsedArticulos = [];
    if (json['articulos'] is List) {
      parsedArticulos = (json['articulos'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => TransferArticleItem.fromJson(a))
          .toList();
    } else if (json['elemento'] != null || json['idArticulo'] != null) {
      parsedArticulos = [
        TransferArticleItem(
          articulo: (json['elemento'] ?? json['idArticulo']).toString(),
          placa: (json['placa'] ?? json['placaElemento'])?.toString(),
          nombre: (json['nombreElemento'] ?? json['nombreArticulo'] ?? json['nombre'] ?? json['descripcion'])?.toString(),
        )
      ];
    }

    // Parseo de lista estructurada de firmas
    List<TransferFirmItem> parsedFirmas = [];
    if (json['firmas'] is List) {
      parsedFirmas = (json['firmas'] as List)
          .whereType<Map<String, dynamic>>()
          .map((f) => TransferFirmItem.fromJson(f))
          .toList();
    }

    final rawNumDoc = json['numeroDocumento'];
    final int? parsedNumDoc = rawNumDoc is int
        ? rawNumDoc
        : (int.tryParse(rawNumDoc?.toString() ?? ''));

    final dynamic rawId = json['id'] ??
        json['numeroTramite'] ??
        json['tramite'] ??
        json['motrnutr'] ??
        json['MOTRNUTR'];
    final String idStr = (rawId ?? '').toString();

    final String rawFuente =
        (json['personaFuente'] ?? json['responsableActual'] ?? '').toString();
    final String rawDestino =
        (json['personaDestino'] ?? json['responsablePropuesto'] ?? '').toString();

    return TransferRequest(
      id: idStr,
      empresaDocumento: json['empresaDocumento']?.toString(),
      tipoDocumento: json['tipoDocumento']?.toString(),
      numeroDocumento: parsedNumDoc,
      idArticulo: (json['elemento'] ?? json['idArticulo'] ?? (parsedArticulos.isNotEmpty ? parsedArticulos.first.articulo : idStr)).toString(),
      nombreArticulo: (json['nombreElemento'] ?? json['nombreArticulo'])?.toString(),
      responsableActual: rawFuente,
      responsablePropuesto: rawDestino,
      personaFuente: (json['personaFuente']?.toString().isNotEmpty == true)
          ? json['personaFuente'].toString()
          : (rawFuente.isNotEmpty ? rawFuente : null),
      personaDestino: (json['personaDestino']?.toString().isNotEmpty == true)
          ? json['personaDestino'].toString()
          : (rawDestino.isNotEmpty ? rawDestino : null),
      bodegaActual: (json['bodegaFuente'] ?? json['bodegaOrigen'] ?? json['bodegaActual'] ?? json['bodega'] ?? '').toString(),
      bodegaPropuesta: (json['bodegaDestino'] ?? json['bodegaPropuesta'] ?? '').toString(),
      motivoSolicitud: (json['observacion'] ?? json['motivoSolicitud'] ?? '').toString(),
      fechaSolicitud: parsedFechaSolicitud,
      fechaAplicacion: parsedFechaAplicacion,
      fechaAprobacion: parsedFechaAprobacion,
      fechaRecibe: parsedFechaRecibe,
      usuarioCreacion: json['usuarioCreacion']?.toString(),
      usuarioAprobacion: json['usuarioAprobacion']?.toString(),
      estado: resolvedStatus,
      motivoRechazo: json['motivoRechazo']?.toString(),
      articulos: parsedArticulos,
      firmas: parsedFirmas,
      firmaDespachadorBase64: (json['firmaFuente'] ?? json['firmaDespachadorBase64'])?.toString(),
      firmaReceptorBase64: (json['firmaDestino'] ?? json['firmaReceptorBase64'])?.toString(),
      placa: (json['placaElemento'] ?? json['placa'] ?? (parsedArticulos.isNotEmpty ? parsedArticulos.first.placa : null))?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (empresaDocumento != null) 'empresaDocumento': empresaDocumento,
      if (tipoDocumento != null) 'tipoDocumento': tipoDocumento,
      if (numeroDocumento != null) 'numeroDocumento': numeroDocumento,
      'personaFuente': (personaFuente != null && personaFuente!.isNotEmpty)
          ? personaFuente
          : responsableActual,
      'personaDestino': (personaDestino != null && personaDestino!.isNotEmpty)
          ? personaDestino
          : responsablePropuesto,
      'bodegaFuente': bodegaActual,
      'bodegaDestino': bodegaPropuesta,
      'observacion': motivoSolicitud,
      'fechaCreacion': fechaSolicitud.toIso8601String(),
      if (fechaAprobacion != null)
        'fechaAprobacion': fechaAprobacion!.toIso8601String(),
      if (fechaRecibe != null) 'fechaRecibe': fechaRecibe!.toIso8601String(),
      if (usuarioCreacion != null) 'usuarioCreacion': usuarioCreacion,
      if (usuarioAprobacion != null) 'usuarioAprobacion': usuarioAprobacion,
      'estado': _statusToString(estado),
      if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
      'articulos': articulos.map((a) => a.toJson()).toList(),
      'firmas': firmas.map((f) => f.toJson()).toList(),
      if (firmaDespachadorBase64 != null)
        'firmaFuente': firmaDespachadorBase64,
      if (firmaReceptorBase64 != null)
        'firmaDestino': firmaReceptorBase64,
      if (placa != null) 'placa': placa,
    };
  }

  static String _statusToString(TransferStatus s) {
    switch (s) {
      case TransferStatus.approved:
        return 'ap';
      case TransferStatus.rejected:
        return 'na';
      case TransferStatus.received:
        return 're';
      case TransferStatus.completed:
        return 'pr';
      case TransferStatus.sourceSigned:
        return 'af';
      case TransferStatus.targetSigned:
        return 'ad';
      case TransferStatus.pending:
        return 'pe';
    }
  }
}