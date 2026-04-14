import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../servicios/servicio_sincronizacion.dart';
import '../utilidades/formateador.dart';

class PantallaSincronizacion extends StatefulWidget {
  const PantallaSincronizacion({super.key});

  @override
  State<PantallaSincronizacion> createState() =>
      _EstadoPantallaSincronizacion();
}

class _EstadoPantallaSincronizacion extends State<PantallaSincronizacion> {
  // Estado de la sincronización
  bool _sincronizando = false;
  ResultadoSincronizacion? _ultimoResultado;
  DateTime? _ultimaSync;

  // Estado de autenticación
  User? _usuarioActual;
  final _ctrlEmail = TextEditingController();
  final _ctrlPassword = TextEditingController();
  bool _iniciandoSesion = false;
  bool _mostrarPassword = false;
  String? _errorAutenticacion;

  @override
  void initState() {
    super.initState();
    _usuarioActual = FirebaseAuth.instance.currentUser;
    _cargarUltimaSync();
    // Escuchar cambios de sesión
    FirebaseAuth.instance.authStateChanges().listen((usuario) {
      if (mounted) setState(() => _usuarioActual = usuario);
    });
  }

  @override
  void dispose() {
    _ctrlEmail.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  Future<void> _cargarUltimaSync() async {
    final fecha = await ServicioSincronizacion.obtenerUltimaSync();
    if (mounted) setState(() => _ultimaSync = fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización en la nube')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Encabezado informativo
          _tarjetaInfo(),
          const SizedBox(height: 16),
          // Sección de autenticación o sincronización
          _usuarioActual == null
              ? _seccionInicioSesion()
              : _seccionSincronizacion(),
        ],
      ),
    );
  }

  // ── Tarjeta informativa ────────────────────────────────────

  Widget _tarjetaInfo() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Respaldo en la nube',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda tus datos en Firebase para acceder desde '
              'cualquier dispositivo. La sincronización es manual '
              'y se activa cuando tú lo decidas.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sección: inicio de sesión ──────────────────────────────

  Widget _seccionInicioSesion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Iniciar sesión',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Usa tu correo para sincronizar',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Campo email
            TextField(
              controller: _ctrlEmail,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            // Campo contraseña
            TextField(
              controller: _ctrlPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _mostrarPassword = !_mostrarPassword),
                ),
              ),
              obscureText: !_mostrarPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _iniciarSesion(),
            ),
            // Mensaje de error
            if (_errorAutenticacion != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorAutenticacion!,
                style:
                    const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            // Botón iniciar sesión
            FilledButton.icon(
              onPressed: _iniciandoSesion ? null : _iniciarSesion,
              icon: _iniciandoSesion
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Iniciar sesión'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 8),
            // Botón registrarse
            OutlinedButton.icon(
              onPressed: _iniciandoSesion ? null : _registrarse,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Crear cuenta nueva'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sección: sincronización ────────────────────────────────

  Widget _seccionSincronizacion() {
    return Column(
      children: [
        // Tarjeta de usuario conectado
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (_usuarioActual!.email ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              _usuarioActual!.email ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Sesión activa'),
            trailing: TextButton(
              onPressed: _cerrarSesion,
              child: const Text('Salir',
                  style: TextStyle(color: Colors.red)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Última sincronización
        if (_ultimaSync != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Última sync: ${Formateador.formatearFechaRelativa(_ultimaSync!)}',
                  style:
                      const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        // Resultado del último intento
        if (_ultimoResultado != null)
          _tarjetaResultado(_ultimoResultado!),
        const SizedBox(height: 16),
        // Botón principal de sincronización
        FilledButton.icon(
          onPressed: _sincronizando ? null : _ejecutarSincronizacion,
          icon: _sincronizando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.sync),
          label: Text(_sincronizando
              ? 'Sincronizando...'
              : 'Sincronizar ahora'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 24),
        // Nota sobre la sincronización
        _notaInformativa(),
      ],
    );
  }

  Widget _tarjetaResultado(ResultadoSincronizacion resultado) {
    final exitosa = resultado.exitosa;
    return Card(
      color: exitosa ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  exitosa ? Icons.check_circle : Icons.error_outline,
                  color: exitosa ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  resultado.mensaje,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: exitosa ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
            if (exitosa) ...[
              const SizedBox(height: 6),
              Text(
                '${resultado.transaccionesSubidas} movimientos subidos · '
                '${resultado.transaccionesDescargadas} descargados',
                style: TextStyle(
                    fontSize: 12, color: Colors.green.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _notaInformativa() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Los datos se sincronizan manualmente. '
              'Tus movimientos locales siempre se conservan '
              'independientemente de la conexión a internet.',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ───────────────────────────────────────────────

  Future<void> _iniciarSesion() async {
    final email = _ctrlEmail.text.trim();
    final password = _ctrlPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() =>
          _errorAutenticacion = 'Ingresa tu correo y contraseña');
      return;
    }

    setState(() {
      _iniciandoSesion = true;
      _errorAutenticacion = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() =>
          _errorAutenticacion = _mensajeErrorFirebase(e.code));
    } finally {
      if (mounted) setState(() => _iniciandoSesion = false);
    }
  }

  Future<void> _registrarse() async {
    final email = _ctrlEmail.text.trim();
    final password = _ctrlPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() =>
          _errorAutenticacion = 'Ingresa tu correo y contraseña');
      return;
    }

    setState(() {
      _iniciandoSesion = true;
      _errorAutenticacion = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() =>
          _errorAutenticacion = _mensajeErrorFirebase(e.code));
    } finally {
      if (mounted) setState(() => _iniciandoSesion = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _ejecutarSincronizacion() async {
    setState(() {
      _sincronizando = true;
      _ultimoResultado = null;
    });

    final resultado = await ServicioSincronizacion.sincronizar(
        _usuarioActual!.uid);

    await _cargarUltimaSync();

    setState(() {
      _sincronizando = false;
      _ultimoResultado = resultado;
    });
  }

  /// Convierte los códigos de error de Firebase a mensajes en español
  String _mensajeErrorFirebase(String codigo) {
    switch (codigo) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'El correo no tiene un formato válido';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return 'Error de autenticación ($codigo)';
    }
  }
}
