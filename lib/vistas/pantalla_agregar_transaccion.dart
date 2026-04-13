import 'package:flutter/material.dart';
import '../controladores/controlador_transacciones.dart';
import '../bd/dao_categorias.dart';
import '../modelos/modelos.dart';
import '../utilidades/formateador.dart';

class PantallaAgregarTransaccion extends StatefulWidget {
  /// Si se pasa una transacción existente, entra en modo edición
  final ModeloTransaccion? transaccionAEditar;

  const PantallaAgregarTransaccion({super.key, this.transaccionAEditar});

  @override
  State<PantallaAgregarTransaccion> createState() =>
      _EstadoPantallaAgregarTransaccion();
}

class _EstadoPantallaAgregarTransaccion
    extends State<PantallaAgregarTransaccion> {
  final _claveFormulario = GlobalKey<FormState>();
  final ControladorTransacciones _controlador = ControladorTransacciones();
  final DaoCategorias _daoCategorias = DaoCategorias();

  // Controladores de texto
  final _ctrlDescripcion = TextEditingController();
  final _ctrlMonto = TextEditingController();
  final _ctrlNota = TextEditingController();

  List<ModeloCategoria> _categorias = [];
  ModeloCategoria? _categoriaSeleccionada;
  TipoTransaccion _tipo = TipoTransaccion.gasto;
  DateTime _fechaSeleccionada = DateTime.now();
  bool _guardando = false;

  bool get _esModoEdicion => widget.transaccionAEditar != null;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (_esModoEdicion) _precargarDatos();
  }

  Future<void> _cargarCategorias() async {
    final lista = await _daoCategorias.obtenerTodas();
    setState(() => _categorias = lista);
  }

  /// Precarga los datos si estamos editando una transacción existente
  void _precargarDatos() {
    final t = widget.transaccionAEditar!;
    _ctrlDescripcion.text = t.descripcion;
    _ctrlMonto.text = t.monto.toStringAsFixed(2);
    _ctrlNota.text = t.nota ?? '';
    _tipo = t.tipo;
    _fechaSeleccionada = t.fecha;
  }

  @override
  void dispose() {
    _ctrlDescripcion.dispose();
    _ctrlMonto.dispose();
    _ctrlNota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esModoEdicion ? 'Editar movimiento' : 'Nuevo movimiento'),
        leading: const CloseButton(),
      ),
      body: Form(
        key: _claveFormulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _selectorTipo(),
            const SizedBox(height: 16),
            _campoDescripcion(),
            const SizedBox(height: 16),
            _campoMonto(),
            const SizedBox(height: 16),
            _selectorCategoria(),
            const SizedBox(height: 16),
            _selectorFecha(context),
            const SizedBox(height: 16),
            _campoNota(),
            const SizedBox(height: 32),
            _botonGuardar(context),
            if (_esModoEdicion) ...[
              const SizedBox(height: 12),
              _botonEliminar(context),
            ],
          ],
        ),
      ),
    );
  }

  // ── Campos del formulario ──────────────────────────────────

  Widget _selectorTipo() {
    return SegmentedButton<TipoTransaccion>(
      segments: const [
        ButtonSegment(
          value: TipoTransaccion.gasto,
          label: Text('Gasto'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: TipoTransaccion.ingreso,
          label: Text('Ingreso'),
          icon: Icon(Icons.arrow_upward),
        ),
      ],
      selected: {_tipo},
      onSelectionChanged: (seleccion) =>
          setState(() => _tipo = seleccion.first),
    );
  }

  Widget _campoDescripcion() {
    return TextFormField(
      controller: _ctrlDescripcion,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        hintText: 'Ej: Almuerzo en el trabajo',
        prefixIcon: Icon(Icons.edit_outlined),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (valor) {
        if (valor == null || valor.trim().isEmpty) {
          return 'Ingresa una descripción';
        }
        return null;
      },
    );
  }

  Widget _campoMonto() {
    return TextFormField(
      controller: _ctrlMonto,
      decoration: const InputDecoration(
        labelText: 'Monto (RD\$)',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (valor) {
        if (valor == null || valor.trim().isEmpty) {
          return 'Ingresa un monto';
        }
        final numero = double.tryParse(valor.replaceAll(',', '.'));
        if (numero == null || numero <= 0) {
          return 'El monto debe ser mayor a cero';
        }
        return null;
      },
    );
  }

  Widget _selectorCategoria() {
    return DropdownButtonFormField<ModeloCategoria>(
      value: _categoriaSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _categorias
          .map((c) => DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    Text(c.icono, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(c.nombre),
                  ],
                ),
              ))
          .toList(),
      onChanged: (cat) => setState(() => _categoriaSeleccionada = cat),
      validator: (valor) =>
          valor == null ? 'Selecciona una categoría' : null,
    );
  }

  Widget _selectorFecha(BuildContext context) {
    return InkWell(
      onTap: () => _elegirFecha(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(Formateador.formatearFecha(_fechaSeleccionada)),
      ),
    );
  }

  Widget _campoNota() {
    return TextFormField(
      controller: _ctrlNota,
      decoration: const InputDecoration(
        labelText: 'Nota (opcional)',
        hintText: 'Agrega un comentario...',
        prefixIcon: Icon(Icons.notes_outlined),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _botonGuardar(BuildContext context) {
    return FilledButton.icon(
      onPressed: _guardando ? null : () => _guardar(context),
      icon: _guardando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(_esModoEdicion ? 'Guardar cambios' : 'Registrar movimiento'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }

  Widget _botonEliminar(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmarEliminacion(context),
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: const Text('Eliminar movimiento',
          style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Colors.red),
      ),
    );
  }

  // ── Acciones ───────────────────────────────────────────────

  Future<void> _elegirFecha(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }

  Future<void> _guardar(BuildContext context) async {
    if (!_claveFormulario.currentState!.validate()) return;

    setState(() => _guardando = true);

    final monto =
        double.parse(_ctrlMonto.text.trim().replaceAll(',', '.'));

    final transaccion = ModeloTransaccion(
      id: widget.transaccionAEditar?.id,
      descripcion: _ctrlDescripcion.text.trim(),
      monto: monto,
      tipo: _tipo,
      idCategoria: _categoriaSeleccionada!.id!,
      fecha: _fechaSeleccionada,
      nota: _ctrlNota.text.trim().isEmpty ? null : _ctrlNota.text.trim(),
    );

    if (_esModoEdicion) {
      await _controlador.editarTransaccion(transaccion);
    } else {
      await _controlador.agregarTransaccion(transaccion);
    }

    setState(() => _guardando = false);

    if (context.mounted) {
      Navigator.of(context).pop(true); // true = hubo cambios
    }
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este movimiento? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await _controlador
          .eliminarTransaccion(widget.transaccionAEditar!.id!);
      Navigator.of(context).pop(true);
    }
  }
}
