import 'package:intl/intl.dart';

/// Utilidades de formato para moneda, fechas y porcentajes
class Formateador {
  Formateador._();

  // ── Moneda ─────────────────────────────────────────────────

  static final _formatoMoneda = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$',
    decimalDigits: 2,
  );

  /// Formatea un monto como moneda: RD$ 1,250.00
  static String formatearMoneda(double monto) =>
      _formatoMoneda.format(monto);

  /// Formatea con signo opcional: +RD$ 500.00 / -RD$ 200.00
  static String formatearMonto(double monto, {bool mostrarSigno = false}) {
    final formateado = _formatoMoneda.format(monto.abs());
    if (!mostrarSigno) return formateado;
    return monto >= 0 ? '+$formateado' : '-$formateado';
  }

  // ── Fecha ──────────────────────────────────────────────────

  /// Fecha larga: 12 abr. 2026
  static String formatearFecha(DateTime fecha) =>
      DateFormat('dd MMM yyyy', 'es').format(fecha);

  /// Fecha corta: 12/04/2026
  static String formatearFechaCorta(DateTime fecha) =>
      DateFormat('dd/MM/yyyy').format(fecha);

  /// Mes y año: abril 2026
  static String formatearMesAnio(DateTime fecha) =>
      DateFormat('MMMM yyyy', 'es').format(fecha);

  /// Fecha relativa: Hoy, Ayer, Hace 3 días, o la fecha completa
  static String formatearFechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final soloDia = DateTime(fecha.year, fecha.month, fecha.day);
    final diferencia = hoy.difference(soloDia).inDays;

    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Ayer';
    if (diferencia < 7) return 'Hace $diferencia días';
    return formatearFecha(fecha);
  }

  // ── Porcentaje ─────────────────────────────────────────────

  /// Convierte una proporción a porcentaje: 0.75 → '75%'
  static String formatearPorcentaje(double proporcion) =>
      '${(proporcion * 100).toStringAsFixed(0)}%';
}
