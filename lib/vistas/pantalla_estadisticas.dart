import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controladores/controlador_transacciones.dart';
import '../modelos/modelos.dart';
import '../utilidades/formateador.dart';

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});

  @override
  State<PantallaEstadisticas> createState() => _EstadoPantallaEstadisticas();
}

class _EstadoPantallaEstadisticas extends State<PantallaEstadisticas>
    with SingleTickerProviderStateMixin {
  final ControladorTransacciones _controlador = ControladorTransacciones();

  late TabController _controladorPestanas;
  ResumenMensual? _resumen;
  List<ModeloTransaccion> _transaccionesMes = [];
  bool _cargando = true;

  late int _mesActual;
  late int _anioActual;

  // Índice del sector tocado en la dona
  int _indiceSectorTocado = -1;

  @override
  void initState() {
    super.initState();
    _controladorPestanas = TabController(length: 2, vsync: this);
    final ahora = DateTime.now();
    _mesActual = ahora.month;
    _anioActual = ahora.year;
    _cargarDatos();
  }

  @override
  void dispose() {
    _controladorPestanas.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final resumen =
        await _controlador.obtenerResumenMensual(_mesActual, _anioActual);
    final transacciones =
        await _controlador.obtenerTransaccionesDeMes(_mesActual, _anioActual);
    setState(() {
      _resumen = resumen;
      _transaccionesMes = transacciones;
      _cargando = false;
      _indiceSectorTocado = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        bottom: TabBar(
          controller: _controladorPestanas,
          tabs: const [
            Tab(text: 'Por categoría'),
            Tab(text: 'Por semana'),
          ],
        ),
      ),
      body: Column(
        children: [
          _encabezadoMes(context),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _controladorPestanas,
                    children: [
                      _vistaCategoria(),
                      _vistaSemanal(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Encabezado navegación de meses ─────────────────────────

  Widget _encabezadoMes(BuildContext context) {
    final fecha = DateTime(_anioActual, _mesActual);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left), onPressed: _meAnterior),
          Text(
            Formateador.formatearMesAnio(fecha),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _mesSiguiente),
        ],
      ),
    );
  }

  // ── Vista: gráfico de dona por categoría ───────────────────

  Widget _vistaCategoria() {
    // Filtra solo gastos y agrupa por categoría
    final gastosPorCategoria = <String, _DatoCategoria>{};
    for (final t in _transaccionesMes) {
      if (t.esGasto) {
        final clave = t.nombreCategoria ?? 'Otros';
        gastosPorCategoria.update(
          clave,
          (existing) => existing..monto += t.monto,
          ifAbsent: () => _DatoCategoria(
            nombre: clave,
            icono: t.iconoCategoria ?? '📦',
            color: _colorDesdeHex(t.colorCategoria ?? '#888780'),
            monto: t.monto,
          ),
        );
      }
    }

    final datos = gastosPorCategoria.values.toList()
      ..sort((a, b) => b.monto.compareTo(a.monto));

    if (datos.isEmpty) {
      return _mensajeSinDatos('No hay gastos registrados este mes');
    }

    final totalGastos = datos.fold(0.0, (s, d) => s + d.monto);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjetas resumen
        _filaTarjetasResumen(),
        const SizedBox(height: 24),
        // Gráfico de dona
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (evento, respuesta) {
                      setState(() {
                        if (respuesta == null ||
                            respuesta.touchedSection == null) {
                          _indiceSectorTocado = -1;
                        } else {
                          _indiceSectorTocado = respuesta
                              .touchedSection!.touchedSectionIndex;
                        }
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: datos.asMap().entries.map((entrada) {
                    final i = entrada.key;
                    final d = entrada.value;
                    final tocado = i == _indiceSectorTocado;
                    return PieChartSectionData(
                      color: d.color,
                      value: d.monto,
                      title: tocado
                          ? Formateador.formatearMoneda(d.monto)
                          : '',
                      radius: tocado ? 70 : 55,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Centro de la dona: total
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total gastos',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    Formateador.formatearMoneda(totalGastos),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Leyenda con montos
        ...datos.map((d) => _itemLeyenda(d, totalGastos)),
      ],
    );
  }

  Widget _filaTarjetasResumen() {
    return Row(
      children: [
        Expanded(
          child: _tarjetaMetrica(
            'Ingresos',
            _resumen?.ingresos ?? 0,
            Icons.arrow_upward,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tarjetaMetrica(
            'Gastos',
            _resumen?.gastos ?? 0,
            Icons.arrow_downward,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tarjetaMetrica(
            'Saldo',
            _resumen?.saldo ?? 0,
            Icons.account_balance_wallet_outlined,
            (_resumen?.saldo ?? 0) >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaMetrica(
      String titulo, double monto, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(height: 4),
            Text(titulo,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              Formateador.formatearMoneda(monto),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemLeyenda(_DatoCategoria dato, double total) {
    final porcentaje = total > 0 ? dato.monto / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dato.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(dato.icono, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(dato.nombre,
                style: const TextStyle(fontSize: 13)),
          ),
          Text(
            Formateador.formatearPorcentaje(porcentaje),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            Formateador.formatearMoneda(dato.monto),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Vista: gráfico de barras semanal ───────────────────────

  Widget _vistaSemanal() {
    // Agrupa gastos e ingresos por semana del mes (1-5)
    final gastosPorSemana = List<double>.filled(5, 0);
    final ingresosPorSemana = List<double>.filled(5, 0);

    for (final t in _transaccionesMes) {
      // Semana dentro del mes basada en el día
      final semana = ((t.fecha.day - 1) / 7).floor().clamp(0, 4);
      if (t.esGasto) {
        gastosPorSemana[semana] += t.monto;
      } else {
        ingresosPorSemana[semana] += t.monto;
      }
    }

    // Determina cuántas semanas tiene el mes
    final diasEnMes = DateTime(_anioActual, _mesActual + 1, 0).day;
    final semanasTotales = ((diasEnMes - 1) / 7).floor() + 1;

    final maxValor = [
      ...gastosPorSemana,
      ...ingresosPorSemana,
    ].fold(0.0, (max, v) => v > max ? v : max);

    if (maxValor == 0) {
      return _mensajeSinDatos('No hay movimientos este mes');
    }

    final colores = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _filaTarjetasResumen(),
        const SizedBox(height: 24),
        // Leyenda del gráfico
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _itemLeyendaColor(Colors.green, 'Ingresos'),
            const SizedBox(width: 16),
            _itemLeyendaColor(Colors.red, 'Gastos'),
          ],
        ),
        const SizedBox(height: 16),
        // Gráfico de barras
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValor * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (grupo, valorGrupo, barra, valorBarra) {
                    return BarTooltipItem(
                      Formateador.formatearMoneda(barra.toY),
                      const TextStyle(
                          color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (valor, meta) {
                      final semana = valor.toInt() + 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Sem $semana',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (valor, meta) {
                      if (valor == 0) return const SizedBox.shrink();
                      return Text(
                        Formateador.formatearMoneda(valor),
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxValor / 4,
                getDrawingHorizontalLine: (valor) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 0.8,
                ),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(semanasTotales, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: ingresosPorSemana[i],
                      color: Colors.green,
                      width: 14,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: gastosPorSemana[i],
                      color: Colors.red,
                      width: 14,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Tabla resumen por semana
        _tablaResumenSemanal(
            gastosPorSemana, ingresosPorSemana, semanasTotales),
      ],
    );
  }

  Widget _itemLeyendaColor(Color color, String etiqueta) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(etiqueta, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _tablaResumenSemanal(List<double> gastos, List<double> ingresos,
      int semanas) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Encabezado
            const Row(
              children: [
                Expanded(
                    child: Text('Semana',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey))),
                SizedBox(
                    width: 90,
                    child: Text('Ingresos',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green))),
                SizedBox(
                    width: 90,
                    child: Text('Gastos',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red))),
              ],
            ),
            const Divider(),
            ...List.generate(semanas, (i) {
              final saldo = ingresos[i] - gastos[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Semana ${i + 1}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        Formateador.formatearMoneda(ingresos[i]),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.green),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        Formateador.formatearMoneda(gastos[i]),
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _mensajeSinDatos(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(mensaje, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _colorDesdeHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
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

// ── Clase auxiliar para datos del gráfico ──────────────────

class _DatoCategoria {
  final String nombre;
  final String icono;
  final Color color;
  double monto;

  _DatoCategoria({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.monto,
  });
}
