import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart'; // Für kReleaseMode

class AppLogger {
  static Logger getLogger(String name) => Logger(name); // Einfacher Logger pro Datei/Klasse

  static void init() {
    // Setzt das globale Loglevel. Im Release-Modus weniger loggen.
    Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;

    // Konsolenausgabe konfigurieren
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name.padRight(7)}: ${record.time.toIso8601String().substring(11, 23)}: ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null && !kReleaseMode) { // Stacktrace nur im Debug
        // ignore: avoid_print
        print(record.stackTrace);
      }
      // Hier könnte später Sentry o.ä. integriert werden
    });

    final log = Logger('AppLogger');
    log.info("Logger initialisiert. Loglevel: ${Logger.root.level.name}");
    log.info("App läuft im ${kReleaseMode ? 'RELEASE' : 'DEBUG'}-Modus.");
  }
}