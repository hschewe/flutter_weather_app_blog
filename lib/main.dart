// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Wird gleich gebraucht
import 'package:flutter_weather_app_blog/app.dart';    // Wird gleich erstellt
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart'; // Wird gleich erstellt
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async{ // main() with ascync
  // Initialisiere Logging (bevor die App startet)
  AppLogger.init();
  final log = AppLogger.getLogger('main'); // Logger für diese Datei holen
  log.info('App wird gestartet...');

  // Wichtig: Stellt sicher, dass Flutter bereit ist, bevor Plugins verwendet werden.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere die deutschen Datumsformatierungsdaten
  // 'de_DE' für Deutschland, 'de' wäre allgemein Deutsch
  await initializeDateFormatting('de_DE', null); 

  // Unsere App wird in einer ProviderScope ausgeführt (notwendig für Riverpod)
  runApp(
    const ProviderScope(
      child: WeatherApp(), // Unsere Haupt-App-Klasse
    ),
  );
}