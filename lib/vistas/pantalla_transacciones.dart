import 'package:flutter/material.dart';
import '../controladores/controlador_transacciones.dart';
import '../modelos/modelos.dart';
import '../utilidades/formateador.dart';
import 'pantalla_agregar_transaccion.dart';

class PantallaTransacciones extends StatefulWidget {
  const PantallaTransacciones({super.key});

  @override
  State<PantallaTransacciones> createState() => _EstadoPantallaTransacciones();
}

class _EstadoPantallaTransacciones extends State<PantallaTransacciones> {
  final ControladorTransacciones _controlador = ControladorTransacciones();

  List<ModeloTransaccion> _todasLasTransacciones = [];
  List<ModeloTransaccion> _transaccionesFiltradas = [];
  bool _cargando = true;

  // Filtros activos
  TipoTransaccion? _filtroTipo;
  String _textoBusqueda = '';
  final _ctrlBusqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarTransacciones();
  }

  @override
  void dispose() {
    _ctrlBusqueda.dispose();
    super.dispose();
  }

  Future<void> _cargarTransacciones() async {
    setState(() => _cargando = true);
    final lista = await _controlador.obtenerTransaccionesRecientes(limite: 200);
    setState(() {
      _todasLasTransacciones = lista;
      _cargando = false;
    });
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    setState(() {
      _transaccionesFiltradas = _todasLasTransacciones.where((t) {
        // Filtro por tipo
        if (_filtroTipo != null && t.tipo != _filtroTipo) return false;
        // Filtro por texto de búsqueda
        if (_textoBusqueda.isNotEmpty) {
          final busqueda = _textoBusqueda.toLowerCase();
          final coincide = t.descripcion.toLowerCase().contains(busqueda) ||
              (t.nombreCategoria?.toLowerCase().contains(busqueda) ?? false);
          if (!coincide) return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
      ),
      body: Column(
        children: [
          _barraFiltros(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _transaccionesFiltradas.isEmpty
                    ? _mensajeSinResultados()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _transaccionesFiltradas.length,
                        itemBuilder: (ctx, i) =>
                            _itemTransaccion(_transaccionesFiltradas[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _barraFiltros() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _ctrlBusqueda,
            decoration: InputDecoration(
              hintText: 'Buscar por descripción o categoría...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _textoBusqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _ctrlBusqueda.clear();
                        setState(() => _textoBusqueda = '');
                        _aplicarFiltros();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (valor) {
              setState(() => _textoBusqueda = valor);
              _aplicarFiltros();
            },
          ),
          const SizedBox(height: 8),
          // Filtros de tipo
          Row(
            children: [
              _chipFiltro('Todos', null),
              const SizedBox(width: 8),
              _chipFiltro('Gastos', TipoTransaccion.gasto),
              const SizedBox(width: 8),
              _chipFiltro('Ingresos', TipoTransaccion.ingreso),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _chipFiltro(String etiqueta, TipoTransaccion? tipo) {
    final seleccionado = _filtroTipo == tipo;
    return FilterChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (_) {
        setState(() => _filtroTipo = tipo);
        _aplicarFiltros();
      },
    );
  }

  Widget _itemTransaccion(ModeloTransaccion t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              t.esGasto ? Colors.red.shade50 : Colors.green.shade50,
          child:
              Text(t.iconoCategoria ?? '📦', style: const TextStyle(fontSize: 20)),
        ),
        title: Text(t.descripcion,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${t.nombreCategoria ?? ''} · ${Formateador.formatearFechaRelativa(t.fecha)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          Formateador.formatearMoneda(t.monto),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: t.esGasto ? Colors.red : Colors.green,
          ),
        ),
        onTap: () => _abrirEdicion(t),
      ),
    );
  }

  Widget _mensajeSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _textoBusqueda.isNotEmpty
                ? 'No hay resultados para "$_textoBusqueda"'
                : 'Aún no hay movimientos registrados',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Acciones ───────────────────────────────────────────────

  Future<void> _abrirEdicion(ModeloTransaccion transaccion) async {
    final huboCambios = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PantallaAgregarTransaccion(transaccionAEditar: transaccion),
        fullscreenDialog: true,
      ),
    );
    if (huboCambios == true) _cargarTransacciones();
  }
}
