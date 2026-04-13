import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'vistas/pantalla_dashboard.dart';
import 'vistas/pantalla_transacciones.dart';
import 'vistas/pantalla_presupuestos.dart';
import 'vistas/pantalla_categorias.dart';
import 'vistas/pantalla_agregar_transaccion.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const AplicacionEcoGasto());
}

class AplicacionEcoGasto extends StatelessWidget {
  const AplicacionEcoGasto({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoGasto',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: const [
  Locale('es'),
],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      home: const PantallaNavegacionPrincipal(),
    );
  }
}

/// Pantalla raíz con la barra de navegación inferior
class PantallaNavegacionPrincipal extends StatefulWidget {
  const PantallaNavegacionPrincipal({super.key});

  @override
  State<PantallaNavegacionPrincipal> createState() =>
      _EstadoPantallaNavegacionPrincipal();
}

class _EstadoPantallaNavegacionPrincipal
    extends State<PantallaNavegacionPrincipal> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = const [
    PantallaDashboard(),
    PantallaTransacciones(),
    PantallaPresupuestos(),
    PantallaCategorias(),
  ];

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (indice) =>
            setState(() => _indiceActual = indice),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Presupuestos',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
        ],
      ),
      // Botón flotante para agregar transacción desde cualquier pantalla
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioTransaccion(context),
        backgroundColor: colores.primary,
        foregroundColor: colores.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _abrirFormularioTransaccion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PantallaAgregarTransaccion(),
        fullscreenDialog: true,
      ),
    );
  }
}