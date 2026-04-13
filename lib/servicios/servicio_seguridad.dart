import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona el bloqueo de la app mediante PIN
class ServicioSeguridad {
  ServicioSeguridad._();

  static const String _clavePin = 'ecogasto_pin';
  static const String _claveActivado = 'ecogasto_pin_activado';

  // ── Configuración del PIN ──────────────────────────────────

  /// Verifica si el bloqueo por PIN está activado
  static Future<bool> estaActivado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claveActivado) ?? false;
  }

  /// Guarda un nuevo PIN (se guarda hasheado con salt simple)
  static Future<void> guardarPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clavePin, _hashearPin(pin));
    await prefs.setBool(_claveActivado, true);
  }

  /// Verifica si el PIN ingresado es correcto
  static Future<bool> verificarPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final pinGuardado = prefs.getString(_clavePin);
    return pinGuardado == _hashearPin(pin);
  }

  /// Desactiva el bloqueo por PIN
  static Future<void> desactivarPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clavePin);
    await prefs.setBool(_claveActivado, false);
  }

  /// Hash simple para el PIN (no usar en producción — usar flutter_secure_storage)
  static String _hashearPin(String pin) {
    // En una app de producción usar bcrypt o argon2
    // Para el proyecto académico usamos un hash básico
    int hash = 0;
    const salt = 'ecogasto_salt_2024';
    final entrada = pin + salt;
    for (int i = 0; i < entrada.length; i++) {
      hash = (hash << 5) - hash + entrada.codeUnitAt(i);
      hash &= hash; // convierte a entero de 32 bits
    }
    return hash.toString();
  }
}

// ── Pantalla de bloqueo con PIN ────────────────────────────

/// Pantalla que se muestra al abrir la app si el PIN está activado
class PantallaBloqueo extends StatefulWidget {
  /// Callback que se llama cuando el PIN es correcto
  final VoidCallback alDesbloquear;

  const PantallaBloqueo({super.key, required this.alDesbloquear});

  @override
  State<PantallaBloqueo> createState() => _EstadoPantallaBloqueo();
}

class _EstadoPantallaBloqueo extends State<PantallaBloqueo> {
  String _pinIngresado = '';
  bool _pinIncorrecto = false;
  static const int _longitudPin = 4;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colores.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Ícono y título
            Icon(Icons.lock_outline,
                size: 56, color: colores.primary),
            const SizedBox(height: 16),
            Text(
              'Ingresa tu PIN',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'EcoGasto está protegido',
              style: TextStyle(color: colores.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            // Indicadores de dígitos ingresados
            _indicadoresPin(colores),
            const SizedBox(height: 12),
            // Mensaje de error
            AnimatedOpacity(
              opacity: _pinIncorrecto ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'PIN incorrecto, intenta de nuevo',
                style: TextStyle(color: colores.error, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),
            // Teclado numérico
            _tecladoNumerico(colores),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _indicadoresPin(ColorScheme colores) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_longitudPin, (i) {
        final lleno = i < _pinIngresado.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lleno ? colores.primary : Colors.transparent,
            border: Border.all(
              color: _pinIncorrecto ? colores.error : colores.primary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _tecladoNumerico(ColorScheme colores) {
    final teclas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: teclas.map((fila) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: fila.map((tecla) {
            if (tecla.isEmpty) return const SizedBox(width: 80, height: 72);
            return _botonTecla(tecla, colores);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _botonTecla(String tecla, ColorScheme colores) {
    return InkWell(
      onTap: () => _alPresionarTecla(tecla),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 72,
        alignment: Alignment.center,
        child: Text(
          tecla,
          style: TextStyle(
            fontSize: tecla == '⌫' ? 20 : 24,
            fontWeight: FontWeight.w500,
            color: colores.onSurface,
          ),
        ),
      ),
    );
  }

  Future<void> _alPresionarTecla(String tecla) async {
    if (tecla == '⌫') {
      // Borrar último dígito
      if (_pinIngresado.isNotEmpty) {
        setState(() {
          _pinIngresado =
              _pinIngresado.substring(0, _pinIngresado.length - 1);
          _pinIncorrecto = false;
        });
      }
      return;
    }

    if (_pinIngresado.length >= _longitudPin) return;

    setState(() {
      _pinIngresado += tecla;
      _pinIncorrecto = false;
    });

    // Verificar automáticamente al completar los 4 dígitos
    if (_pinIngresado.length == _longitudPin) {
      await Future.delayed(const Duration(milliseconds: 150));
      final correcto = await ServicioSeguridad.verificarPin(_pinIngresado);
      if (correcto) {
        widget.alDesbloquear();
      } else {
        // Vibrar y limpiar
        HapticFeedback.heavyImpact();
        setState(() {
          _pinIncorrecto = true;
          _pinIngresado = '';
        });
      }
    }
  }
}

// ── Pantalla de configuración de PIN ──────────────────────

/// Pantalla para activar, cambiar o desactivar el PIN
class PantallaConfigurarPin extends StatefulWidget {
  const PantallaConfigurarPin({super.key});

  @override
  State<PantallaConfigurarPin> createState() =>
      _EstadoPantallaConfigurarPin();
}

class _EstadoPantallaConfigurarPin extends State<PantallaConfigurarPin> {
  bool _pinActivado = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    final activado = await ServicioSeguridad.estaActivado();
    setState(() {
      _pinActivado = activado;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Estado actual
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _pinActivado
                              ? Icons.lock
                              : Icons.lock_open_outlined,
                          color: _pinActivado ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pinActivado
                                    ? 'Bloqueo activado'
                                    : 'Sin bloqueo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _pinActivado
                                    ? 'La app solicita PIN al abrirse'
                                    : 'Cualquiera puede acceder a la app',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de acción
                if (!_pinActivado)
                  FilledButton.icon(
                    onPressed: () => _flujoCrearPin(context),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Activar bloqueo por PIN'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                if (_pinActivado) ...[
                  OutlinedButton.icon(
                    onPressed: () => _flujoCrearPin(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Cambiar PIN'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _desactivarPin(context),
                    icon: const Icon(Icons.lock_open_outlined,
                        color: Colors.red),
                    label: const Text('Desactivar bloqueo',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El PIN protege el acceso a tus datos financieros. '
                          'Si lo olvidas, deberás reinstalar la app.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _flujoCrearPin(BuildContext context) async {
    // Paso 1: ingresar nuevo PIN
    final pin1 = await _mostrarIngresadorPin(
      context,
      titulo: 'Crear PIN',
      subtitulo: 'Elige 4 dígitos para tu PIN',
    );
    if (pin1 == null || !context.mounted) return;

    // Paso 2: confirmar PIN
    final pin2 = await _mostrarIngresadorPin(
      context,
      titulo: 'Confirmar PIN',
      subtitulo: 'Ingresa el mismo PIN de nuevo',
    );
    if (pin2 == null || !context.mounted) return;

    if (pin1 != pin2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los PINs no coinciden, intenta de nuevo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ServicioSeguridad.guardarPin(pin1);
    setState(() => _pinActivado = true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN configurado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _desactivarPin(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar PIN'),
        content: const Text(
            '¿Estás seguro de que deseas desactivar el bloqueo por PIN?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desactivar')),
        ],
      ),
    );

    if (confirmar == true) {
      await ServicioSeguridad.desactivarPin();
      setState(() => _pinActivado = false);
    }
  }

  /// Muestra un diálogo con el teclado numérico para ingresar un PIN
  Future<String?> _mostrarIngresadorPin(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
  }) async {
    String pinTemporal = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarEstado) {
          return AlertDialog(
            title: Text(titulo),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subtitulo,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                // Indicadores
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < pinTemporal.length
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Teclado compacto en el diálogo
                ...([
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['', '0', '⌫'],
                ].map((fila) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: fila.map((tecla) {
                        if (tecla.isEmpty) {
                          return const SizedBox(width: 64, height: 52);
                        }
                        return InkWell(
                          onTap: () {
                            if (tecla == '⌫') {
                              if (pinTemporal.isNotEmpty) {
                                actualizarEstado(() => pinTemporal =
                                    pinTemporal.substring(
                                        0, pinTemporal.length - 1));
                              }
                            } else if (pinTemporal.length < 4) {
                              actualizarEstado(
                                  () => pinTemporal += tecla);
                              if (pinTemporal.length == 4) {
                                Navigator.of(ctx).pop(pinTemporal);
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: SizedBox(
                            width: 64,
                            height: 52,
                            child: Center(
                              child: Text(tecla,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        );
                      }).toList(),
                    ))),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
