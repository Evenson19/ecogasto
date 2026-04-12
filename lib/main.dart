import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa los datos de localización para fechas en español
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75), // verde principal de la marca
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
      // TODO Fase 2: reemplazar con el enrutador real de pantallas
      home: const _PantallaProvisional(),
    );
  }
}

/// Pantalla temporal para verificar que la app inicia correctamente.
/// Se reemplaza en la Fase 2 por el dashboard real.
class _PantallaProvisional extends StatelessWidget {
  const _PantallaProvisional();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoGasto')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 72, color: Color(0xFF1D9E75)),
            SizedBox(height: 16),
            Text(
              'Fase 1 lista ✓',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Base de datos y modelos configurados',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
