import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/scanner_screen.dart';
import 'screens/species_list_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/plants_screen.dart';

void main() {
  runApp(const QRostlinaApp());
}

class QRostlinaApp extends StatelessWidget {
  const QRostlinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRostlina',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('cs'), // Czech
      ],
      theme: ThemeData(
        useMaterial3: true,
        // High contrast theme for field work
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          primary: Colors.yellow,
          onPrimary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 20, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Colors.yellow,
            ),
            const SizedBox(height: 48),
            _MenuButton(
              label: l10n.scanQrCode,
              icon: Icons.camera_alt,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: l10n.speciesList,
              icon: Icons.list_alt,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpeciesListScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: l10n.locations,
              icon: Icons.location_on,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: 'PLANTS',
              icon: Icons.local_florist,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlantsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 80), // Large button for gloved hands
      ),
    );
  }
}
