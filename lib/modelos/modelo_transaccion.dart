/// Tipo de movimiento financiero
enum TipoTransaccion { ingreso, gasto }

class ModeloTransaccion {
  final int? id;
  final String descripcion;
  final double monto;
  final TipoTransaccion tipo;
  final int idCategoria;
  final DateTime fecha;
  final String? nota;

  // Campos extra para consultas con JOIN (no se guardan en BD)
  final String? nombreCategoria;
  final String? iconoCategoria;
  final String? colorCategoria;

  ModeloTransaccion({
    this.id,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    required this.idCategoria,
    required this.fecha,
    this.nota,
    this.nombreCategoria,
    this.iconoCategoria,
    this.colorCategoria,
  });

  /// Convierte el objeto a un mapa para guardar en la base de datos
  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'tipo': tipo.name, // 'ingreso' o 'gasto'
      'id_categoria': idCategoria,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
    };
  }

  /// Crea un objeto desde un mapa de la base de datos
  factory ModeloTransaccion.desdeMapa(Map<String, dynamic> mapa) {
    return ModeloTransaccion(
      id: mapa['id'],
      descripcion: mapa['descripcion'],
      monto: mapa['monto'] is int
          ? (mapa['monto'] as int).toDouble()
          : mapa['monto'],
      tipo: mapa['tipo'] == 'ingreso'
          ? TipoTransaccion.ingreso
          : TipoTransaccion.gasto,
      idCategoria: mapa['id_categoria'],
      fecha: DateTime.parse(mapa['fecha']),
      nota: mapa['nota'],
      nombreCategoria: mapa['nombre_categoria'],
      iconoCategoria: mapa['icono_categoria'],
      colorCategoria: mapa['color_categoria'],
    );
  }

  ModeloTransaccion copiarCon({
    int? id,
    String? descripcion,
    double? monto,
    TipoTransaccion? tipo,
    int? idCategoria,
    DateTime? fecha,
    String? nota,
  }) {
    return ModeloTransaccion(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      idCategoria: idCategoria ?? this.idCategoria,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
    );
  }

  bool get esGasto => tipo == TipoTransaccion.gasto;
  bool get esIngreso => tipo == TipoTransaccion.ingreso;

  @override
  String toString() =>
      'ModeloTransaccion(id: $id, descripcion: $descripcion, monto: $monto, tipo: ${tipo.name}, fecha: $fecha)';
}
