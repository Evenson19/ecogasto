import 'package:flutter/material.dart';
import '../bd/dao_presupuestos.dart';
import '../bd/dao_categorias.dart';
import '../modelos/modelos.dart';
import '../utilidades/formateador.dart';

class PantallaPresupuestos extends StatefulWidget {
  const PantallaPresupuestos({super.key});

  @override
  State<PantallaPresupuestos> createState() => _EstadoPantallaPresupuestos();
}

class _EstadoPantallaPresupuestos extends State<PantallaPresupuestos> {
  final DaoPresupuestos _daoPresupuestos = DaoPresupuestos();
  final DaoCategorias _daoCategorias = DaoCategorias();

  List<ModeloPresupuesto> _presupuestos = [];
  bool _cargando = true;

  late int _mesActual;
  late int _anioActual;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _mesActual = ahora.month;
    _anioActual = ahora.year;
    _cargarPresupuestos();
  }

  Future<void> _cargarPresupuestos() async {
    setState(() => _cargando = true);
    final lista =
        await _daoPresupuestos.obtenerPorMes(_mesActual, _anioActual);
    setState(() {
      _presupuestos = lista;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirFormularioPresupuesto(context),
            tooltip: 'Agregar presupuesto',
          ),
        ],
      ),
      body: Column(
        children: [
          _encabezadoMes(context),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _presupuestos.isEmpty
                    ? _mensajeSinPresupuestos(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _presupuestos.length,
                        itemBuilder: (ctx, i) =>
                            _tarjetaPresupuesto(_presupuestos[i], context),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

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
              icon: const Icon(Icons.chevron_right), onPressed: _mesSiguiente),
        ],
      ),
    );
  }

  Widget _tarjetaPresupuesto(ModeloPresupuesto p, BuildContext context) {
    final porcentaje = (p.proporcionUsada * 100).clamp(0, 100).toInt();
    final colorBarra = p.superaElLimite
        ? Colors.red
        : p.cercaDelLimite
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: categoría y monto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(p.iconoCategoria ?? '📦',
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(p.nombreCategoria ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () =>
                      _abrirFormularioPresupuesto(context, presupuesto: p),
                  tooltip: 'Editar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.proporcionUsada.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: colorBarra,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            // Montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Formateador.formatearMoneda(p.montoGastado ?? 0)} gastados',
                  style: TextStyle(fontSize: 12, color: colorBarra),
                ),
                Text(
                  'límite: ${Formateador.formatearMoneda(p.montoLimite)}',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (p.superaElLimite)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '¡Superaste el límite!',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mensajeSinPresupuestos(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No hay presupuestos para este mes',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _abrirFormularioPresupuesto(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar presupuesto'),
          ),
        ],
      ),
    );
  }

  // ── Formulario de presupuesto ──────────────────────────────

  Future<void> _abrirFormularioPresupuesto(BuildContext context,
      {ModeloPresupuesto? presupuesto}) async {
    final categorias = await _daoCategorias.obtenerTodas();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormularioPresupuesto(
        categorias: categorias,
        presupuestoAEditar: presupuesto,
        mes: _mesActual,
        anio: _anioActual,
        alGuardar: _cargarPresupuestos,
        alEliminar: _cargarPresupuestos,
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
    _cargarPresupuestos();
  }

  void _mesSiguiente() {
    setState(() {
      if (_mesActual == 12) {
        _mesActual = 1;
        _anioActual++;
      } else {
        _mesActual++;
      }
    });
    _cargarPresupuestos();
  }
}

// ── Formulario en bottom sheet ─────────────────────────────

class _FormularioPresupuesto extends StatefulWidget {
  final List<ModeloCategoria> categorias;
  final ModeloPresupuesto? presupuestoAEditar;
  final int mes;
  final int anio;
  final VoidCallback alGuardar;
  final VoidCallback alEliminar;

  const _FormularioPresupuesto({
    required this.categorias,
    required this.mes,
    required this.anio,
    required this.alGuardar,
    required this.alEliminar,
    this.presupuestoAEditar,
  });

  @override
  State<_FormularioPresupuesto> createState() =>
      _EstadoFormularioPresupuesto();
}

class _EstadoFormularioPresupuesto extends State<_FormularioPresupuesto> {
  final _claveFormulario = GlobalKey<FormState>();
  final DaoPresupuestos _dao = DaoPresupuestos();
  final _ctrlMonto = TextEditingController();

  ModeloCategoria? _categoriaSeleccionada;

  bool get _esModoEdicion => widget.presupuestoAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esModoEdicion) {
      _ctrlMonto.text =
          widget.presupuestoAEditar!.montoLimite.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _ctrlMonto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _claveFormulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _esModoEdicion ? 'Editar presupuesto' : 'Nuevo presupuesto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (!_esModoEdicion)
              DropdownButtonFormField<ModeloCategoria>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: widget.categorias
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(children: [
                            Text(c.icono),
                            const SizedBox(width: 8),
                            Text(c.nombre),
                          ]),
                        ))
                    .toList(),
                onChanged: (c) => setState(() => _categoriaSeleccionada = c),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ctrlMonto,
              decoration: const InputDecoration(
                labelText: 'Límite mensual (RD\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (n == null || n <= 0) return 'Ingresa un monto válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _guardar,
              child: Text(_esModoEdicion ? 'Guardar cambios' : 'Crear presupuesto'),
            ),
            if (_esModoEdicion) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _eliminar,
                style:
                    OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar presupuesto'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    final monto =
        double.parse(_ctrlMonto.text.trim().replaceAll(',', '.'));

    if (_esModoEdicion) {
      await _dao.actualizar(
          widget.presupuestoAEditar!.copiarCon(montoLimite: monto));
    } else {
      await _dao.insertarOActualizar(ModeloPresupuesto(
        idCategoria: _categoriaSeleccionada!.id!,
        montoLimite: monto,
        mes: widget.mes,
        anio: widget.anio,
      ));
    }

    widget.alGuardar();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _eliminar() async {
    await _dao.eliminar(widget.presupuestoAEditar!.id!);
    widget.alEliminar();
    if (mounted) Navigator.of(context).pop();
  }
}
