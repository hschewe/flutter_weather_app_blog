import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/utils/date_formatter.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';

final _log = AppLogger.getLogger('DailyDataModel');

/// Datenmodell für die täglichen historischen Wetterdaten (Zeit und mittlere Temperatur).
class DailyDataModel {
  final List<DateTime> time;
  final List<double> temperature2mMean;

  DailyDataModel({
    required this.time,
    required this.temperature2mMean,
  });

  factory DailyDataModel.fromJson(Map<String, dynamic> json) {
    try {
       final timeListRaw = json['time'];
       final tempMeanListRaw = json['temperature_2m_mean'];

        if (timeListRaw is! List || tempMeanListRaw is! List) {
          throw FormatException('Ungültiges Format: "time" oder "temperature_2m_mean" ist keine Liste im DailyData JSON (Historical).');
       }
        if (timeListRaw.length != tempMeanListRaw.length) {
           _log.warning('Längen von time (${timeListRaw.length}) und temperature_2m_mean (${tempMeanListRaw.length}) stimmen nicht überein (Historical)!');
           throw FormatException('Inkonsistente Datenlängen für Zeit und mittlere Temperatur (Historical).');
        }

       List<DateTime> parsedTimes = [];
       List<double> parsedTemperatures = [];

        for (int i = 0; i < timeListRaw.length; i++) {
         final timeString = timeListRaw[i];
         final tempValue = tempMeanListRaw[i];

          if (timeString is! String) {
            _log.warning('Ungültiger Zeiteintrag in DailyData bei Index $i: $timeString. Wird übersprungen.');
            continue;
         }
         final parsedDate = DateFormatter.tryParseApiDateTime(timeString); // API liefert nur Datum
         if (parsedDate == null) {
             _log.warning('Konnte Datum nicht parsen in DailyData bei Index $i: $timeString. Wird übersprungen.');
            continue;
         }

         double temperature;
         if (tempValue == null) {
            temperature = double.nan;
         } else if (tempValue is num) {
            temperature = tempValue.toDouble();
         } else {
            _log.warning('Ungültiger mittlerer Temperatureintrag in DailyData bei Index $i: $tempValue. Wird als NaN interpretiert.');
            temperature = double.nan;
         }

         parsedTimes.add(parsedDate);
         parsedTemperatures.add(temperature);
       }

       if (parsedTimes.isEmpty && timeListRaw.isNotEmpty) {
           throw DataParsingException('Keine gültigen Zeit/Temperatur-Paare im DailyData JSON (Historical) gefunden nach Parsen.');
        }

      return DailyDataModel(
        time: parsedTimes,
        temperature2mMean: parsedTemperatures,
      );
    } catch (e, s) {
        if (e is DataParsingException || e is FormatException) rethrow;
        throw DataParsingException('Fehler beim Parsen von DailyDataModel (Historical): ${e.toString()}', s);
     }
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.map((dt) => DateFormatter.formatApiDate(dt)).toList(), // Nur Datum als String
      'temperature_2m_mean': temperature2mMean,
    };
  }
}