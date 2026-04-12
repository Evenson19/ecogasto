import '../modelos/modelos.dart';
import 'asistente_bd.dart';

/// Acceso a datos para la tabla de transacciones
class DaoTransacciones {
  final AsistenteBD _asistenteBD = AsistenteBD();

  // ── INSERTAR ───────────────────────────────────────────────

  Future<int> insertar(ModeloTransaccion transaccion) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.insert('transacciones', transaccion.aMapa());
  }

  // ── CONSULTAR ──────────────────────────────────────────────

  /// Devuelve las últimas transacciones con datos de categoría (JOIN)
  Future<List<ModeloTransaccion>> obtenerTodas({int limite = 100}) async {
    final bd = await _asistenteBD.baseDeDatos;
    final filas = await bd.rawQuery('''
      SELECT
        t.*,
        c.nombre AS nombre_categoria,
        c.icono  AS icono_categoria,
        c.color  AS color_categoria
      FROM transacciones t
      JOIN categorias c ON t.id_categoria = c.id
      ORDER BY t.fecha DESC
      LIMIT ?
    ''', [limite]);
    return filas.map(ModeloTransaccion.desdeMapa).toList();
  }

  /// Devuelve transacciones dentro de un rango de fechas
  Future<List<ModeloTransaccion>> obtenerPorRangoDeFechas(
      DateTime desde, DateTime hasta) async {
    final bd = await _asistenteBD.baseDeDatos;
    final filas = await bd.rawQuery('''
      SELECT
        t.*,
        c.nombre AS nombre_categoria,
        c.icono  AS icono_categoria,
        c.color  AS color_categoria
      FROM transacciones t
      JOIN categorias c ON t.id_categoria = c.id
      WHERE t.fecha BETWEEN ? AND ?
      ORDER BY t.fecha DESC
    ''', [desde.toIso8601String(), hasta.toIso8601String()]);
    return filas.map(ModeloTransaccion.desdeMapa).toList();
  }

  /// Devuelve todas las transacciones de un mes específico
  Future<List<ModeloTransaccion>> obtenerPorMes(int mes, int anio) async {
    final desde = DateTime(anio, mes, 1);
    final hasta = DateTime(anio, mes + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    return obtenerPorRangoDeFechas(desde, hasta);
  }

  /// Devuelve el total gastado e ingresado por categoría en un mes
  Future<List<Map<String, dynamic>>> obtenerResumenPorCategoria(
      int mes, int anio) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.rawQuery('''
      SELECT
        c.id     AS id_categoria,
        c.nombre AS nombre_categoria,
        c.icono  AS icono_categoria,
        c.color  AS color_categoria,
        t.tipo,
        SUM(t.monto) AS total
      FROM transacciones t
      JOIN categorias c ON t.id_categoria = c.id
      WHERE strftime('%m', t.fecha) = ? AND strftime('%Y', t.fecha) = ?
      GROUP BY c.id, t.tipo
      ORDER BY total DESC
    ''', [mes.toString().padLeft(2, '0'), anio.toString()]);
  }

  /// Calcula el balance del mes: ingresos, gastos y saldo final
  Future<Map<String, double>> obtenerBalanceMensual(int mes, int anio) async {
    final bd = await _asistenteBD.baseDeDatos;
    final resultado = await bd.rawQuery('''
      SELECT
        tipo,
        SUM(monto) AS total
      FROM transacciones
      WHERE strftime('%m', fecha) = ? AND strftime('%Y', fecha) = ?
      GROUP BY tipo
    ''', [mes.toString().padLeft(2, '0'), anio.toString()]);

    double ingresos = 0;
    double gastos = 0;
    for (final fila in resultado) {
      if (fila['tipo'] == 'ingreso') {
        ingresos = (fila['total'] as num).toDouble();
      } else {
        gastos = (fila['total'] as num).toDouble();
      }
    }
    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'saldo': ingresos - gastos,
    };
  }

  // ── ACTUALIZAR ─────────────────────────────────────────────

  Future<int> actualizar(ModeloTransaccion transaccion) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.update(
      'transacciones',
      transaccion.aMapa(),
      where: 'id = ?',
      whereArgs: [transaccion.id],
    );
  }

  // ── ELIMINAR ───────────────────────────────────────────────

  Future<int> eliminar(int id) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.delete('transacciones', where: 'id = ?', whereArgs: [id]);
  }
}
