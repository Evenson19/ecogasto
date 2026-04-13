import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../modelos/modelos.dart';
import '../utilidades/formateador.dart';

/// Servicio encargado de generar y compartir reportes en PDF
class ServicioExportacionPdf {
  ServicioExportacionPdf._();

  /// Genera un reporte mensual y abre el diálogo de impresión/compartir
  static Future<void> exportarReporteMensual({
    required int mes,
    required int anio,
    required List<ModeloTransaccion> transacciones,
    required double totalIngresos,
    required double totalGastos,
    required double saldo,
  }) async {
    final documento = pw.Document();
    final fechaReporte = DateTime(anio, mes);
    final tituloMes = Formateador.formatearMesAnio(fechaReporte);

    // Separa transacciones por tipo
    final gastos = transacciones.where((t) => t.esGasto).toList();
    final ingresos = transacciones.where((t) => t.esIngreso).toList();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (contexto) => _encabezado(tituloMes),
        footer: (contexto) => _pieDePagina(contexto),
        build: (contexto) => [
          _seccionResumen(totalIngresos, totalGastos, saldo),
          pw.SizedBox(height: 20),
          if (gastos.isNotEmpty) ...[
            _tituloSeccion('Gastos del mes'),
            pw.SizedBox(height: 8),
            _tablaTransacciones(gastos),
            pw.SizedBox(height: 20),
          ],
          if (ingresos.isNotEmpty) ...[
            _tituloSeccion('Ingresos del mes'),
            pw.SizedBox(height: 8),
            _tablaTransacciones(ingresos),
          ],
        ],
      ),
    );

    // Abre el diálogo del sistema para imprimir o compartir el PDF
    await Printing.layoutPdf(
      onLayout: (formato) async => documento.save(),
      name: 'EcoGasto_${tituloMes.replaceAll(' ', '_')}.pdf',
    );
  }

  // ── Componentes del PDF ────────────────────────────────────

  static pw.Widget _encabezado(String tituloMes) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF1D9E75), width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EcoGasto',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1D9E75),
                ),
              ),
              pw.Text(
                'Reporte mensual — $tituloMes',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Text(
            'Generado: ${Formateador.formatearFecha(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pieDePagina(pw.Context contexto) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('EcoGasto — Finanzas personales',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          pw.Text(
            'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _seccionResumen(
      double ingresos, double gastos, double saldo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _celdaResumen('Ingresos', ingresos, PdfColors.green700),
          _separadorVertical(),
          _celdaResumen('Gastos', gastos, PdfColors.red700),
          _separadorVertical(),
          _celdaResumen(
            'Saldo',
            saldo,
            saldo >= 0 ? PdfColors.green700 : PdfColors.red700,
          ),
        ],
      ),
    );
  }

  static pw.Widget _celdaResumen(
      String etiqueta, double monto, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(etiqueta,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          Formateador.formatearMoneda(monto),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _separadorVertical() {
    return pw.Container(
      width: 0.5,
      height: 40,
      color: PdfColors.grey400,
    );
  }

  static pw.Widget _tituloSeccion(String titulo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1D9E75),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tablaTransacciones(List<ModeloTransaccion> lista) {
    // Colores alternados para las filas
    final colorFila1 = PdfColors.white;
    final colorFila2 = PdfColors.grey50;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5), // descripción
        1: pw.FlexColumnWidth(1.5), // categoría
        2: pw.FlexColumnWidth(1.2), // fecha
        3: pw.FlexColumnWidth(1.3), // monto
      },
      children: [
        // Encabezado de la tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Descripción', 'Categoría', 'Fecha', 'Monto']
              .map((titulo) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Text(
                      titulo,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ))
              .toList(),
        ),
        // Filas de datos
        ...lista.asMap().entries.map((entrada) {
          final t = entrada.value;
          final colorFondo =
              entrada.key.isEven ? colorFila1 : colorFila2;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: colorFondo),
            children: [
              _celdaTabla(t.descripcion),
              _celdaTabla(t.nombreCategoria ?? '—'),
              _celdaTabla(Formateador.formatearFechaCorta(t.fecha)),
              _celdaTabla(
                Formateador.formatearMoneda(t.monto),
                alineacion: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _celdaTabla(String texto,
      {pw.TextAlign alineacion = pw.TextAlign.left}) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        texto,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: alineacion,
      ),
    );
  }
}
