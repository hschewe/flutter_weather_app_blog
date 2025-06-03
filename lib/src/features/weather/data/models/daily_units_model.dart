import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';

/// Datenmodell für die Einheiten der täglichen historischen Wetterdaten.
class DailyUnitsModel {
  final String time; // z.B. "iso8601"
  final String temperature2mMean; // z.B. "°C"

  DailyUnitsModel({
    required this.time,
    required this.temperature2mMean,
  });

  factory DailyUnitsModel.fromJson(Map<String, dynamic> json) {
     try {
       final timeValue = json['time'];
       final tempMeanValue = json['temperature_2m_mean'];

       if (timeValue is! String || tempMeanValue is! String) {
          throw FormatException('Ungültiges Format oder fehlende Felder im DailyUnits JSON (Historical).');
       }

      return DailyUnitsModel(
        time: timeValue,
        temperature2mMean: tempMeanValue,
      );
     } catch (e, s) {
       throw DataParsingException('Fehler beim Parsen von DailyUnitsModel (Historical): ${e.toString()}', s);
     }
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature_2m_mean': temperature2mMean,
    };
  }
}