import 'package:intl/intl.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';

class DateFormatter {
  // Format für die Anzeige der Uhrzeit (z.B. für aktuelle Wetterdaten)
  static final timeFormat = DateFormat('HH:mm');

  // Format für API-Anfragen (YYYY-MM-DD)
  static final apiDateFormat = DateFormat('yyyy-MM-dd');

  // Format für die Anzeige von Datum und Uhrzeit im Chart-Tooltip
  static final chartTooltipFormat = DateFormat('dd.MM. HH:mm');

  // Format für die Anzeige von Tagen auf der X-Achse des Charts
  static final chartAxisDayFormat = DateFormat('E dd.MM', 'de_DE'); // z.B. Mo 15.07.

  static String formatTime(DateTime date) {
    try {
      return timeFormat.format(date.toLocal()); // Wichtig: Lokale Zeit anzeigen
    } catch (e) {
      return '--:--'; // Fallback bei Fehler
    }
  }

  static String formatApiDate(DateTime date) {
    try {
      return apiDateFormat.format(date);
    } catch (e) {
      return '0000-00-00'; // Fallback
    }
  }

  static String formatChartTooltip(DateTime date) {
    try {
      return chartTooltipFormat.format(date.toLocal());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  static String formatChartAxisDay(DateTime date) {
     try {
      return chartAxisDayFormat.format(date.toLocal());
    } catch (e) {
      return 'Err';
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