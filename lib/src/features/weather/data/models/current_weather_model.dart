// lib/src/features/weather/data/models/current_weather_model.dart
import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/utils/date_formatter.dart';

/// Datenmodell für die aktuellen Wetterdaten von der Open-Meteo API.
/// Muss exakt die Felder aus dem 'current_weather' JSON-Objekt abbilden.
class CurrentWeatherModel {
  final double temperature;
  final double windSpeed;
  final int windDirection;
  final int weatherCode;
  final DateTime? time; // API liefert Zeit als String, wir parsen sie

  CurrentWeatherModel({
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
    required this.time,
  });

  // Factory-Konstruktor, um ein Objekt aus JSON zu erstellen
  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    try {
      // Prüfe, ob alle erwarteten Felder vorhanden und vom richtigen Typ sind
      final temp = json['temperature'];
      final windSpeed = json['windspeed'];
      final windDirection = json['winddirection'];
      final weatherCode = json['weathercode'];
      final timeString = json['time']; // API liefert String

      if (temp is! num ||
          windSpeed is! num ||
          windDirection is! num ||
          weatherCode is! num ||
          timeString is! String?) { // Zeit kann auch fehlen/null sein? Sicher prüfen.
        throw FormatException('Ungültiges Format oder fehlende Felder im CurrentWeather JSON.');
      }

      // Parse den Zeit-String (kann null zurückgeben)
      final parsedTime = DateFormatter.tryParseApiDateTime(timeString);

      // Hier könnten wir prüfen, ob parsedTime null ist und einen Fehler werfen,
      // aber wir erlauben es erstmal, falls die API es manchmal nicht liefert.
      // if (parsedTime == null && timeString != null) {
      //   throw FormatException('Ungültiges Zeitformat im CurrentWeather JSON: $timeString');
      // }

      return CurrentWeatherModel(
        temperature: temp.toDouble(),
        windSpeed: windSpeed.toDouble(),
        windDirection: windDirection.toInt(),
        weatherCode: weatherCode.toInt(),
        time: parsedTime, // Kann null sein
      );
    } catch (e, s) {
      // Logge den Fehler ggf. hier oder in der aufrufenden Schicht
      throw DataParsingException('Fehler beim Parsen von CurrentWeatherModel: ${e.toString()}', s);
    }
  }

  // Methode, um das Objekt zurück in JSON zu wandeln (nützlich für Caching/Debugging)
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'windspeed': windSpeed,
      'winddirection': windDirection,
      'weathercode': weatherCode,
      'time': time?.toIso8601String(), // Wandle DateTime zurück in ISO String
    };
  }
}