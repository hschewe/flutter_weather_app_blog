import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';

/// Datenmodell für die Einheiten der stündlichen Wetterdaten von Open-Meteo.
class HourlyUnitsModel {
  final String time; // z.B. "iso8601"
  final String temperature2m; // z.B. "°C"

  HourlyUnitsModel({
    required this.time,
    required this.temperature2m,
  });

  factory HourlyUnitsModel.fromJson(Map<String, dynamic> json) {
     try {
      final timeValue = json['time'];
      final tempValue = json['temperature_2m'];

      if (timeValue is! String || tempValue is! String) {
        throw FormatException('Ungültiges Format oder fehlende Felder im HourlyUnits JSON.');
      }

      return HourlyUnitsModel(
        time: timeValue,
        temperature2m: tempValue,
      );
     } catch (e, s) {
        throw DataParsingException('Fehler beim Parsen von HourlyUnitsModel: ${e.toString()}', s);
     }
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature_2m': temperature2m,
    };
  }
}