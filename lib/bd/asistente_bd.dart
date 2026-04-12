import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton que gestiona la conexión a la base de datos SQLite
class AsistenteBD {
  static final AsistenteBD _instancia = AsistenteBD._interno();
  static Database? _baseDeDatos;

  factory AsistenteBD() => _instancia;
  AsistenteBD._interno();

  /// Devuelve la base de datos, inicializándola si es necesario
  Future<Database> get baseDeDatos async {
    _baseDeDatos ??= await _inicializar();
    return _baseDeDatos!;
  }

  Future<Database> _inicializar() async {
    final rutaBD = await getDatabasesPath();
    final ruta = join(rutaBD, 'ecogasto.db');

    return await openDatabase(
      ruta,
      version: 1,
      onCreate: _alCrear,
      onConfigure: _alConfigurar,
    );
  }

  /// Habilita el soporte de llaves foráneas en SQLite
  Future<void> _alConfigurar(Database bd) async {
    await bd.execute('PRAGMA foreign_keys = ON');
  }

  /// Crea las tablas e inserta los datos iniciales
  Future<void> _alCrear(Database bd, int version) async {
    // ── Tabla: categorias ──────────────────────────────────────
    await bd.execute('''
      CREATE TABLE categorias (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT    NOT NULL UNIQUE,
        icono  TEXT    NOT NULL,
        color  TEXT    NOT NULL
      )
    ''');

    // ── Tabla: transacciones ───────────────────────────────────
    await bd.execute('''
      CREATE TABLE transacciones (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion  TEXT    NOT NULL,
        monto        REAL    NOT NULL CHECK(monto > 0),
        tipo         TEXT    NOT NULL CHECK(tipo IN ('ingreso','gasto')),
        id_categoria INTEGER NOT NULL,
        fecha        TEXT    NOT NULL,
        nota         TEXT,
        FOREIGN KEY (id_categoria) REFERENCES categorias(id) ON DELETE RESTRICT
      )
    ''');

    // ── Tabla: presupuestos ────────────────────────────────────
    await bd.execute('''
      CREATE TABLE presupuestos (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        id_categoria INTEGER NOT NULL,
        monto_limite REAL    NOT NULL CHECK(monto_limite > 0),
        mes          INTEGER NOT NULL CHECK(mes BETWEEN 1 AND 12),
        anio         INTEGER NOT NULL,
        UNIQUE(id_categoria, mes, anio),
        FOREIGN KEY (id_categoria) REFERENCES categorias(id) ON DELETE CASCADE
      )
    ''');

    // ── Índices para acelerar las consultas más frecuentes ─────
    await bd.execute(
        'CREATE INDEX idx_transacciones_fecha ON transacciones(fecha)');
    await bd.execute(
        'CREATE INDEX idx_transacciones_categoria ON transacciones(id_categoria)');
    await bd.execute(
        'CREATE INDEX idx_presupuestos_periodo ON presupuestos(mes, anio)');

    // ── Categorías predeterminadas ─────────────────────────────
    await _insertarCategoriasPredeterminadas(bd);
  }

  Future<void> _insertarCategoriasPredeterminadas(Database bd) async {
    final categorias = [
      {'nombre': 'Alimentación', 'icono': '🍔', 'color': '#FF6B6B'},
      {'nombre': 'Transporte',   'icono': '🚌', 'color': '#4ECDC4'},
      {'nombre': 'Ocio',         'icono': '🎮', 'color': '#45B7D1'},
      {'nombre': 'Salud',        'icono': '💊', 'color': '#96CEB4'},
      {'nombre': 'Educación',    'icono': '📚', 'color': '#FFEAA7'},
      {'nombre': 'Ropa',         'icono': '👕', 'color': '#DDA0DD'},
      {'nombre': 'Servicios',    'icono': '💡', 'color': '#F0A500'},
      {'nombre': 'Hogar',        'icono': '🏠', 'color': '#A8E6CF'},
      {'nombre': 'Sueldo',       'icono': '💼', 'color': '#6BCB77'},
      {'nombre': 'Otros',        'icono': '📦', 'color': '#B8B8B8'},
    ];

    // Insertamos todas las categorías en una sola operación por eficiencia
    final lote = bd.batch();
    for (final categoria in categorias) {
      lote.insert('categorias', categoria);
    }
    await lote.commit(noResult: true);
  }

  /// Cierra la conexión a la base de datos (útil en pruebas)
  Future<void> cerrar() async {
    final bd = await baseDeDatos;
    await bd.close();
    _baseDeDatos = null;
  }
}
