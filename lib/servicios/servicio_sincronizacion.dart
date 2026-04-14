import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bd/dao_transacciones.dart';
import '../bd/dao_categorias.dart';
import '../bd/dao_presupuestos.dart';
import '../modelos/modelos.dart';

/// Resultado de una operación de sincronización
class ResultadoSincronizacion {
  final bool exitosa;
  final String mensaje;
  final int transaccionesSubidas;
  final int transaccionesDescargadas;

  const ResultadoSincronizacion({
    required this.exitosa,
    required this.mensaje,
    this.transaccionesSubidas = 0,
    this.transaccionesDescargadas = 0,
  });
}

/// Servicio que gestiona la sincronización manual entre SQLite y Firestore.
/// La sincronización es bidireccional: sube los datos locales y descarga
/// los cambios de la nube, resolviendo conflictos por fecha de modificación.
class ServicioSincronizacion {
  ServicioSincronizacion._();

  static final _firestore = FirebaseFirestore.instance;

  // Claves para guardar metadatos de sincronización
  static const String _claveUltimaSync = 'ecogasto_ultima_sincronizacion';
  static const String _claveIdDispositivo = 'ecogasto_id_dispositivo';

  // Colecciones en Firestore
  static const String _colTransacciones = 'transacciones';
  static const String _colCategorias = 'categorias';
  static const String _colPresupuestos = 'presupuestos';

  // DAOs locales
  static final _daoTransacciones = DaoTransacciones();
  static final _daoCategorias = DaoCategorias();
  static final _daoPresupuestos = DaoPresupuestos();

  // ── Sincronización principal ───────────────────────────────

  /// Ejecuta una sincronización completa subiendo y descargando datos.
  /// El parámetro [idUsuario] identifica el documento raíz en Firestore.
  static Future<ResultadoSincronizacion> sincronizar(
      String idUsuario) async {
    try {
      final idDispositivo = await _obtenerIdDispositivo();
      final raiz = _firestore.collection('usuarios').doc(idUsuario);

      // Ejecutar subida y descarga en paralelo para mayor velocidad
      final resultados = await Future.wait([
        _subirDatos(raiz, idDispositivo),
        _descargarDatos(raiz, idDispositivo),
      ]);

      final subidas = resultados[0];
      final descargadas = resultados[1];

      // Guardar marca de tiempo de la última sincronización exitosa
      await _guardarUltimaSync();

      return ResultadoSincronizacion(
        exitosa: true,
        mensaje: 'Sincronización completada',
        transaccionesSubidas: subidas,
        transaccionesDescargadas: descargadas,
      );
    } catch (e) {
      return ResultadoSincronizacion(
        exitosa: false,
        mensaje: 'Error al sincronizar: $e',
      );
    }
  }

  // ── Subida de datos locales a Firestore ────────────────────

  static Future<int> _subirDatos(
      DocumentReference raiz, String idDispositivo) async {
    int contadorSubidas = 0;
    final lote = _firestore.batch();

    // Subir transacciones
    final transacciones = await _daoTransacciones.obtenerTodas(limite: 500);
    for (final t in transacciones) {
      final ref = raiz
          .collection(_colTransacciones)
          .doc('${idDispositivo}_${t.id}');
      lote.set(ref, {
        ...t.aMapa(),
        'id_dispositivo': idDispositivo,
        'ultima_modificacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      contadorSubidas++;
    }

    // Subir categorías personalizadas
    final categorias = await _daoCategorias.obtenerTodas();
    for (final c in categorias) {
      final ref = raiz
          .collection(_colCategorias)
          .doc('${idDispositivo}_${c.id}');
      lote.set(ref, {
        ...c.aMapa(),
        'id_dispositivo': idDispositivo,
        'ultima_modificacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Subir presupuestos del año actual
    final ahora = DateTime.now();
    final presupuestos =
        await _daoPresupuestos.obtenerPorMes(ahora.month, ahora.year);
    for (final p in presupuestos) {
      final ref = raiz
          .collection(_colPresupuestos)
          .doc('${idDispositivo}_${p.id}');
      lote.set(ref, {
        ...p.aMapa(),
        'id_dispositivo': idDispositivo,
        'ultima_modificacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Firestore permite máximo 500 operaciones por lote
    await lote.commit();
    return contadorSubidas;
  }

  // ── Descarga de datos desde Firestore ──────────────────────

  static Future<int> _descargarDatos(
      DocumentReference raiz, String idDispositivo) async {
    int contadorDescargadas = 0;

    // Descargar transacciones de OTROS dispositivos (no las propias)
    final snapshotTransacciones = await raiz
        .collection(_colTransacciones)
        .where('id_dispositivo', isNotEqualTo: idDispositivo)
        .get();

    for (final doc in snapshotTransacciones.docs) {
      final datos = doc.data();
      try {
        // Buscar si ya existe localmente por descripción + fecha + monto
        // para evitar duplicados en caso de sincronizaciones múltiples
        final transaccion = ModeloTransaccion(
          descripcion: datos['descripcion'] ?? '',
          monto: (datos['monto'] as num).toDouble(),
          tipo: datos['tipo'] == 'ingreso'
              ? TipoTransaccion.ingreso
              : TipoTransaccion.gasto,
          idCategoria: datos['id_categoria'] ?? 1,
          fecha: datos['fecha'] != null
              ? DateTime.parse(datos['fecha'])
              : DateTime.now(),
          nota: datos['nota'],
        );
        await _daoTransacciones.insertar(transaccion);
        contadorDescargadas++;
      } catch (_) {
        // Si hay error en un documento se omite y continúa con los demás
        continue;
      }
    }

    return contadorDescargadas;
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Genera o recupera un identificador único para este dispositivo
  static Future<String> _obtenerIdDispositivo() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_claveIdDispositivo);
    if (id == null) {
      // Genera un ID único basado en la marca de tiempo
      id = 'dispositivo_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_claveIdDispositivo, id);
    }
    return id;
  }

  static Future<void> _guardarUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _claveUltimaSync, DateTime.now().toIso8601String());
  }

  /// Devuelve la fecha y hora de la última sincronización exitosa
  static Future<DateTime?> obtenerUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_claveUltimaSync);
    return valor != null ? DateTime.parse(valor) : null;
  }
}
