class ModeloPresupuesto {
  final int? id;
  final int idCategoria;
  final double montoLimite;
  final int mes;  // 1-12
  final int anio;

  // Campos extra para consultas con JOIN
  final String? nombreCategoria;
  final String? iconoCategoria;
  final String? colorCategoria;
  final double? montoGastado; // calculado en tiempo de ejecución

  ModeloPresupuesto({
    this.id,
    required this.idCategoria,
    required this.montoLimite,
    required this.mes,
    required this.anio,
    this.nombreCategoria,
    this.iconoCategoria,
    this.colorCategoria,
    this.montoGastado,
  });

  /// Convierte el objeto a un mapa para guardar en la base de datos
  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'id_categoria': idCategoria,
      'monto_limite': montoLimite,
      'mes': mes,
      'anio': anio,
    };
  }

  /// Crea un objeto desde un mapa de la base de datos
  factory ModeloPresupuesto.desdeMapa(Map<String, dynamic> mapa) {
    return ModeloPresupuesto(
      id: mapa['id'],
      idCategoria: mapa['id_categoria'],
      montoLimite: mapa['monto_limite'] is int
          ? (mapa['monto_limite'] as int).toDouble()
          : mapa['monto_limite'],
      mes: mapa['mes'],
      anio: mapa['anio'],
      nombreCategoria: mapa['nombre_categoria'],
      iconoCategoria: mapa['icono_categoria'],
      colorCategoria: mapa['color_categoria'],
    );
  }

  ModeloPresupuesto copiarCon({
    int? id,
    int? idCategoria,
    double? montoLimite,
    int? mes,
    int? anio,
    double? montoGastado,
  }) {
    return ModeloPresupuesto(
      id: id ?? this.id,
      idCategoria: idCategoria ?? this.idCategoria,
      montoLimite: montoLimite ?? this.montoLimite,
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      montoGastado: montoGastado ?? this.montoGastado,
    );
  }

  /// Proporción gastada del presupuesto (0.0 a 1.0+)
  double get proporcionUsada =>
      montoGastado != null && montoLimite > 0
          ? montoGastado! / montoLimite
          : 0.0;

  /// Verdadero si se superó el 80% del límite
  bool get cercaDelLimite => proporcionUsada >= 0.8;

  /// Verdadero si se superó el límite total
  bool get superaElLimite => proporcionUsada > 1.0;

  @override
  String toString() =>
      'ModeloPresupuesto(id: $id, idCategoria: $idCategoria, limite: $montoLimite, $mes/$anio)';
}
