import '../bd/dao_transacciones.dart';
import '../bd/dao_presupuestos.dart';
import '../modelos/modelos.dart';

/// Controlador principal de transacciones.
/// Es la única capa que las pantallas deben utilizar; nunca los DAOs directamente.
class ControladorTransacciones {
  final DaoTransacciones _daoTransacciones = DaoTransacciones();
  final DaoPresupuestos _daoPresupuestos = DaoPresupuestos();

  // ── Guardar ────────────────────────────────────────────────

  Future<int> agregarTransaccion(ModeloTransaccion transaccion) async {
    return await _daoTransacciones.insertar(transaccion);
  }

  Future<int> editarTransaccion(ModeloTransaccion transaccion) async {
    return await _daoTransacciones.actualizar(transaccion);
  }

  Future<int> eliminarTransaccion(int id) async {
    return await _daoTransacciones.eliminar(id);
  }

  // ── Leer ───────────────────────────────────────────────────

  Future<List<ModeloTransaccion>> obtenerTransaccionesRecientes(
      {int limite = 20}) async {
    return await _daoTransacciones.obtenerTodas(limite: limite);
  }

  Future<List<ModeloTransaccion>> obtenerTransaccionesDeMes(
      int mes, int anio) async {
    return await _daoTransacciones.obtenerPorMes(mes, anio);
  }

  // ── Resumen mensual ────────────────────────────────────────

  /// Devuelve un resumen completo del mes: saldo, desglose por categoría y alertas
  Future<ResumenMensual> obtenerResumenMensual(int mes, int anio) async {
    final balance =
        await _daoTransacciones.obtenerBalanceMensual(mes, anio);
    final porCategoria =
        await _daoTransacciones.obtenerResumenPorCategoria(mes, anio);
    final presupuestos =
        await _daoPresupuestos.obtenerPorMes(mes, anio);

    return ResumenMensual(
      ingresos: balance['ingresos']!,
      gastos: balance['gastos']!,
      saldo: balance['saldo']!,
      desglosePorCategoria: porCategoria,
      presupuestos: presupuestos,
    );
  }

  // ── Alertas ────────────────────────────────────────────────

  /// Devuelve los presupuestos que superaron el 80% de su límite
  Future<List<ModeloPresupuesto>> obtenerAlertas(int mes, int anio) async {
    final presupuestos = await _daoPresupuestos.obtenerPorMes(mes, anio);
    return presupuestos.where((p) => p.cercaDelLimite).toList();
  }
}

/// Objeto de transferencia con el resumen financiero del mes
class ResumenMensual {
  final double ingresos;
  final double gastos;
  final double saldo;
  final List<Map<String, dynamic>> desglosePorCategoria;
  final List<ModeloPresupuesto> presupuestos;

  ResumenMensual({
    required this.ingresos,
    required this.gastos,
    required this.saldo,
    required this.desglosePorCategoria,
    required this.presupuestos,
  });

  /// Lista de presupuestos que requieren atención (>=80% gastado)
  List<ModeloPresupuesto> get alertas =>
      presupuestos.where((p) => p.cercaDelLimite).toList();

  bool get hayAlertas => alertas.isNotEmpty;
}
