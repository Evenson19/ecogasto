import '../modelos/modelos.dart';
import 'asistente_bd.dart';

/// Acceso a datos para la tabla de categorías
class DaoCategorias {
  final AsistenteBD _asistenteBD = AsistenteBD();

  Future<int> insertar(ModeloCategoria categoria) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.insert('categorias', categoria.aMapa());
  }

  /// Devuelve todas las categorías ordenadas alfabéticamente
  Future<List<ModeloCategoria>> obtenerTodas() async {
    final bd = await _asistenteBD.baseDeDatos;
    final filas = await bd.query('categorias', orderBy: 'nombre ASC');
    return filas.map(ModeloCategoria.desdeMapa).toList();
  }

  /// Busca una categoría por su ID; devuelve null si no existe
  Future<ModeloCategoria?> obtenerPorId(int id) async {
    final bd = await _asistenteBD.baseDeDatos;
    final filas =
        await bd.query('categorias', where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) return null;
    return ModeloCategoria.desdeMapa(filas.first);
  }

  Future<int> actualizar(ModeloCategoria categoria) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.update(
      'categorias',
      categoria.aMapa(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> eliminar(int id) async {
    final bd = await _asistenteBD.baseDeDatos;
    return await bd.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}
