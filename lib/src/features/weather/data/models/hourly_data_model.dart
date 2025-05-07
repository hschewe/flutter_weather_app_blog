import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/utils/date_formatter.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';

final _log = AppLogger.getLogger('HourlyDataModel');

/// Datenmodell für die stündlichen Wetterdaten (Zeit und Temperatur) von Open-Meteo.
class HourlyDataModel {
  final List<DateTime> time;       // Geparste Zeitstempel
  final List<double> temperature2m; // Temperaturen

  HourlyDataModel({
    required this.time,
    required this.temperature2m,
  });

  factory HourlyDataModel.fromJson(Map<String, dynamic> json) {
    try {
       final timeListRaw = json['time'];
       final tempListRaw = json['temperature_2m'];

       if (timeListRaw is! List || tempListRaw is! List) {
          throw FormatException('Ungültiges Format: "time" oder "temperature_2m" ist keine Liste im HourlyData JSON.');
       }
       // Sicherstellen, dass die Listen die gleiche Länge haben
       if (timeListRaw.length != tempListRaw.length) {
          _log.warning('Längen von time (${timeListRaw.length}) und temperature_2m (${tempListRaw.length}) stimmen nicht überein!');
          throw FormatException('Inkonsistente Datenlängen für Zeit und Temperatur im HourlyData.');
       }

       List<DateTime> parsedTimes = [];
       List<double> parsedTemperatures = [];

       for (int i = 0; i < timeListRaw.length; i++) {
         final timeString = timeListRaw[i];
         final tempValue = tempListRaw[i];

         // Zeit parsen
         if (timeString is! String) {
            _log.warning('Ungültiger Zeiteintrag in HourlyData bei Index $i: $timeString. Wird übersprungen.');
            continue; // Überspringe diesen Datenpunkt
         }
         final parsedTime = DateFormatter.tryParseApiDateTime(timeString);
         if (parsedTime == null) {
             _log.warning('Konnte Zeit nicht parsen in HourlyData bei Index $i: $timeString. Wird übersprungen.');
            continue; // Überspringe diesen Datenpunkt
         }

         // Temperatur parsen (kann null oder NaN sein, wenn die API es so liefert)
         double temperature;
         if (tempValue == null) {
            temperature = double.nan; // Behandle API-Null als NaN
            _log.finer('HourlyData: Null-Temperatur bei Index $i, als NaN interpretiert.');
         } else if (tempValue is num) {
            temperature = tempValue.toDouble();
         } else {
             _log.warning('Ungültiger Temperatureintrag in HourlyData bei Index $i: $tempValue. Wird als NaN interpretiert.');
            temperature = double.nan; // Ungültiger Typ als NaN
         }

         parsedTimes.add(parsedTime);
         parsedTemperatures.add(temperature);
       }

        // Wenn nach dem Parsen keine gültigen Datenpunkte übrig sind, aber die Rohdaten welche hatten.
        if (parsedTimes.isEmpty && timeListRaw.isNotEmpty) {
           throw DataParsingException('Keine gültigen Zeit/Temperatur-Paare im HourlyData JSON gefunden nach dem Parsen.');
        }

       return HourlyDataModel(
         time: parsedTimes,
         temperature2m: parsedTemperatures,
       );
    } catch (e, s) {
        if (e is DataParsingException || e is FormatException) rethrow; // Spezifische Fehler weiterleiten
        throw DataParsingException('Fehler beim Parsen von HourlyDataModel: ${e.toString()}', s);
     }
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.map((dt) => dt.toIso8601String()).toList(),
      'temperature_2m': temperature2m,
    };
  }
}