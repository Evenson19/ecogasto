import 'package:sqflite/sqflite.dart';

import '../modelos/modelos.dart';
import 'asistente_bd.dart';

/// Acceso a datos para la tabla de presupuestos
class DaoPresupuestos {
  final AsistenteBD _asistenteBD = AsistenteBD();

  Future<int> insertar(ModeloPresupuesto presupuesto) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.insert('presupuestos', presupuesto.aMapa());
  }

  /// Devuelve los presupuestos de un mes con el gasto real calculado
  Future<List<ModeloPresupuesto>> obtenerPorMes(int mes, int anio) async {
    final bd = await _asistenteBD.baseDeDatos;
    final filas = await bd.rawQuery('''
      SELECT
        p.*,
        c.nombre AS nombre_categoria,
        c.icono  AS icono_categoria,
        c.color  AS color_categoria,
        COALESCE(
          (SELECT SUM(t.monto)
           FROM transacciones t
           WHERE t.id_categoria = p.id_categoria
             AND t.tipo = 'gasto'
             AND strftime('%m', t.fecha) = ?
             AND strftime('%Y', t.fecha) = ?),
          0.0
        ) AS monto_gastado
      FROM presupuestos p
      JOIN categorias c ON p.id_categoria = c.id
      WHERE p.mes = ? AND p.anio = ?
      ORDER BY c.nombre ASC
    ''', [
      mes.toString().padLeft(2, '0'),
      anio.toString(),
      mes,
      anio,
    ]);

    return filas.map((fila) {
      final presupuesto = ModeloPresupuesto.desdeMapa(fila);
      return presupuesto.copiarCon(
        montoGastado: (fila['monto_gastado'] as num).toDouble(),
      );
    }).toList();
  }

  Future<int> actualizar(ModeloPresupuesto presupuesto) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.update(
      'presupuestos',
      presupuesto.aMapa(),
      where: 'id = ?',
      whereArgs: [presupuesto.id],
    );
  }

  /// Inserta o reemplaza un presupuesto existente para el mismo mes/categoría
  Future<int> insertarOActualizar(ModeloPresupuesto presupuesto) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.insert(
      'presupuestos',
      presupuesto.aMapa(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> eliminar(int id) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.delete('presupuestos', where: 'id = ?', whereArgs: [id]);
  }
}
