import 'package:flutter/material.dart';
import '../controladores/controlador_transacciones.dart';
import '../modelos/modelos.dart';
import '../utilidades/formateador.dart';
import '../servicios/servicio_exportacion_pdf.dart';
import '../servicios/servicio_seguridad.dart';
import 'pantalla_agregar_transaccion.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key});

  @override
  State<PantallaDashboard> createState() => _EstadoPantallaDashboard();
}

class _EstadoPantallaDashboard extends State<PantallaDashboard> {
  final ControladorTransacciones _controlador = ControladorTransacciones();

  ResumenMensual? _resumen;
  List<ModeloTransaccion> _transaccionesRecientes = [];
  bool _cargando = true;

  // Mes y año actualmente visualizados
  late int _mesActual;
  late int _anioActual;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _mesActual = ahora.month;
    _anioActual = ahora.year;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final resumen =
        await _controlador.obtenerResumenMensual(_mesActual, _anioActual);
    final recientes =
        await _controlador.obtenerTransaccionesRecientes(limite: 5);
    setState(() {
      _resumen = resumen;
      _transaccionesRecientes = recientes;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoGasto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportarPdf,
            tooltip: 'Exportar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.security_outlined),
            onPressed: _abrirSeguridad,
            tooltip: 'Seguridad',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _encabezadoMes(context),
                  const SizedBox(height: 16),
                  _tarjetaSaldo(context),
                  const SizedBox(height: 16),
                  _filaTarjetasIngresosGastos(context),
                  if (_resumen!.hayAlertas) ...[
                    const SizedBox(height: 16),
                    _tarjetaAlertas(context),
                  ],
                  const SizedBox(height: 24),
                  _encabezadoSeccion('Últimos movimientos', context),
                  const SizedBox(height: 8),
                  ..._transaccionesRecientes.map(
                    (t) => _itemTransaccion(t, context),
                  ),
                  if (_transaccionesRecientes.isEmpty)
                    _mensajeSinDatos('Aún no hay movimientos registrados'),
                ],
              ),
            ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _encabezadoMes(BuildContext context) {
    final fecha = DateTime(_anioActual, _mesActual);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _meAnterior,
        ),
        Text(
          Formateador.formatearMesAnio(fecha),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _mesSiguiente,
        ),
      ],
    );
  }

  Widget _tarjetaSaldo(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final saldo = _resumen?.saldo ?? 0;
    final esPositivo = saldo >= 0;

    return Card(
      color: colores.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Saldo del mes',
              style: TextStyle(
                color: colores.onPrimaryContainer.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Formateador.formatearMonto(saldo, mostrarSigno: true),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colores.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaTarjetasIngresosGastos(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tarjetaMetrica(
            context,
            titulo: 'Ingresos',
            monto: _resumen?.ingresos ?? 0,
            icono: Icons.arrow_upward,
            colorIcono: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tarjetaMetrica(
            context,
            titulo: 'Gastos',
            monto: _resumen?.gastos ?? 0,
            icono: Icons.arrow_downward,
            colorIcono: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaMetrica(
    BuildContext context, {
    required String titulo,
    required double monto,
    required IconData icono,
    required Color colorIcono,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 16),
                const SizedBox(width: 4),
                Text(titulo,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              Formateador.formatearMoneda(monto),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAlertas(BuildContext context) {
    final alertas = _resumen!.alertas;
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${alertas.length} presupuesto(s) cerca del límite',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alertas.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${p.iconoCategoria ?? ''} ${p.nombreCategoria ?? ''}',
                          style: const TextStyle(fontSize: 13)),
                      Text(
                        Formateador.formatearPorcentaje(p.proporcionUsada),
                        style: TextStyle(
                          fontSize: 13,
                          color: p.superaElLimite ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _encabezadoSeccion(String titulo, BuildContext context) {
    return Text(
      titulo,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _itemTransaccion(ModeloTransaccion t, BuildContext context) {
    final esGasto = t.esGasto;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: esGasto
              ? Colors.red.shade50
              : Colors.green.shade50,
          child: Text(t.iconoCategoria ?? '📦',
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(t.descripcion,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${t.nombreCategoria ?? ''} · ${Formateador.formatearFechaRelativa(t.fecha)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          Formateador.formatearMonto(t.monto, mostrarSigno: true),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: esGasto ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _mensajeSinDatos(String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(mensaje,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ),
    );
  }

  // ── Navegación de meses ────────────────────────────────────

  Future<void> _exportarPdf() async {
    if (_resumen == null) return;
    try {
      await ServicioExportacionPdf.exportarReporteMensual(
        mes: _mesActual,
        anio: _anioActual,
        transacciones: _transaccionesRecientes,
        totalIngresos: _resumen!.ingresos,
        totalGastos: _resumen!.gastos,
        saldo: _resumen!.saldo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  void _abrirSeguridad() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PantallaConfigurarPin(),
      ),
    );
  }

  void _meAnterior() {
    setState(() {
      if (_mesActual == 1) {
        _mesActual = 12;
        _anioActual--;
      } else {
        _mesActual--;
      }
    });
    _cargarDatos();
  }

  void _mesSiguiente() {
    final ahora = DateTime.now();
    // No permitir navegar al futuro
    if (_anioActual == ahora.year && _mesActual == ahora.month) return;
    setState(() {
      if (_mesActual == 12) {
        _mesActual = 1;
        _anioActual++;
      } else {
        _mesActual++;
      }
    });
    _cargarDatos();
  }
}