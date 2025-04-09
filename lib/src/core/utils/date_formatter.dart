import 'package:intl/intl.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';

class DateFormatter {
  // Format für die Anzeige der Uhrzeit (z.B. für aktuelle Wetterdaten)
  static final timeFormat = DateFormat('HH:mm');

  // Format für API-Anfragen (YYYY-MM-DD) - wird später gebraucht
  // static final apiDateFormat = DateFormat('yyyy-MM-dd');

  static String formatTime(DateTime date) {
    try {
      return timeFormat.format(date.toLocal()); // Wichtig: Lokale Zeit anzeigen
    } catch (e) {
      return '--:--'; // Fallback bei Fehler
    }
  }

  /// Versucht, einen Datums/Zeit-String von der API zu parsen.
  static DateTime? tryParseApiDateTime(String? dateTimeString) {
    if (dateTimeString == null) return null;
    try {
      // Standard ISO 8601 Format (oft von APIs verwendet)
      return DateTime.parse(dateTimeString).toLocal(); // Wichtig: In lokale Zeit umwandeln
    } catch (e) {
      // Fallback für reines Datum (fügt Mitternacht hinzu)
       try {
         final dateOnly = DateFormat('yyyy-MM-dd').parseStrict(dateTimeString);
         return dateOnly.toLocal();
       } catch (_) {
          // Wenn beides fehlschlägt
          AppLogger.getLogger('DateFormatter').warning('Konnte Datum/Zeit nicht parsen: $dateTimeString');
          return null;
       }
    }
  }
}