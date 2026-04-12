class ModeloCategoria {
  final int? id;
  final String nombre;
  final String icono;
  final String color;

  ModeloCategoria({
    this.id,
    required this.nombre,
    required this.icono,
    required this.color,
  });

  /// Convierte el objeto a un mapa para guardar en la base de datos
  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'color': color,
    };
  }

  /// Crea un objeto desde un mapa de la base de datos
  factory ModeloCategoria.desdeMapa(Map<String, dynamic> mapa) {
    return ModeloCategoria(
      id: mapa['id'],
      nombre: mapa['nombre'],
      icono: mapa['icono'],
      color: mapa['color'],
    );
  }

  ModeloCategoria copiarCon({
    int? id,
    String? nombre,
    String? icono,
    String? color,
  }) {
    return ModeloCategoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      color: color ?? this.color,
    );
  }

  @override
  String toString() =>
      'ModeloCategoria(id: $id, nombre: $nombre, icono: $icono, color: $color)';
}
