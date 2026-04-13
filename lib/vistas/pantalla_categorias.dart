import 'package:flutter/material.dart';
import '../bd/dao_categorias.dart';
import '../modelos/modelos.dart';

class PantallaCategorias extends StatefulWidget {
  const PantallaCategorias({super.key});

  @override
  State<PantallaCategorias> createState() => _EstadoPantallaCategorias();
}

class _EstadoPantallaCategorias extends State<PantallaCategorias> {
  final DaoCategorias _dao = DaoCategorias();
  List<ModeloCategoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargando = true);
    final lista = await _dao.obtenerTodas();
    setState(() {
      _categorias = lista;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirFormulario(context),
            tooltip: 'Nueva categoría',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _categorias.length,
              itemBuilder: (ctx, i) =>
                  _itemCategoria(_categorias[i], context),
            ),
    );
  }

  Widget _itemCategoria(ModeloCategoria categoria, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorDesdeHex(categoria.color).withOpacity(0.2),
          child: Text(categoria.icono,
              style: const TextStyle(fontSize: 20)),
        ),
        title: Text(categoria.nombre,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Muestra el color asignado
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _colorDesdeHex(categoria.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () =>
                  _abrirFormulario(context, categoriaAEditar: categoria),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formulario ─────────────────────────────────────────────

  Future<void> _abrirFormulario(BuildContext context,
      {ModeloCategoria? categoriaAEditar}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormularioCategoria(
        categoriaAEditar: categoriaAEditar,
        alGuardar: _cargarCategorias,
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
}

// ── Formulario en bottom sheet ─────────────────────────────

class _FormularioCategoria extends StatefulWidget {
  final ModeloCategoria? categoriaAEditar;
  final VoidCallback alGuardar;

  const _FormularioCategoria({
    this.categoriaAEditar,
    required this.alGuardar,
  });

  @override
  State<_FormularioCategoria> createState() => _EstadoFormularioCategoria();
}

class _EstadoFormularioCategoria extends State<_FormularioCategoria> {
  final _claveFormulario = GlobalKey<FormState>();
  final DaoCategorias _dao = DaoCategorias();

  final _ctrlNombre = TextEditingController();
  String _iconoSeleccionado = '📦';
  String _colorSeleccionado = '#888780';

  // Opciones de íconos disponibles
  final List<String> _iconosDisponibles = [
    '🍔', '🚌', '🎮', '💊', '📚', '👕',
    '💡', '🏠', '💼', '📦', '✈️', '🎵',
    '🏋️', '🐶', '☕', '🛒', '🎁', '💻',
  ];

  // Paleta de colores disponibles
  final List<String> _coloresDisponibles = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#F0A500', '#A8E6CF',
    '#6BCB77', '#B8B8B8', '#FF8C69', '#87CEEB',
  ];

  bool get _esModoEdicion => widget.categoriaAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esModoEdicion) {
      _ctrlNombre.text = widget.categoriaAEditar!.nombre;
      _iconoSeleccionado = widget.categoriaAEditar!.icono;
      _colorSeleccionado = widget.categoriaAEditar!.color;
    }
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
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
              _esModoEdicion ? 'Editar categoría' : 'Nueva categoría',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctrlNombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 16),
            Text('Ícono', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconosDisponibles.map((icono) {
                final seleccionado = icono == _iconoSeleccionado;
                return GestureDetector(
                  onTap: () => setState(() => _iconoSeleccionado = icono),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: seleccionado
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: seleccionado ? 2 : 1,
                      ),
                      color: seleccionado
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                          : null,
                    ),
                    child: Center(
                      child: Text(icono,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coloresDisponibles.map((hex) {
                final seleccionado = hex == _colorSeleccionado;
                final color =
                    Color(int.parse(hex.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => setState(() => _colorSeleccionado = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: seleccionado ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: seleccionado
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardar,
              child: Text(
                  _esModoEdicion ? 'Guardar cambios' : 'Crear categoría'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_claveFormulario.currentState!.validate()) return;

    final categoria = ModeloCategoria(
      id: widget.categoriaAEditar?.id,
      nombre: _ctrlNombre.text.trim(),
      icono: _iconoSeleccionado,
      color: _colorSeleccionado,
    );

    if (_esModoEdicion) {
      await _dao.actualizar(categoria);
    } else {
      await _dao.insertar(categoria);
    }

    widget.alGuardar();
    if (mounted) Navigator.of(context).pop();
  }
}
