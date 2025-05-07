// lib/src/features/weather/data/models/forecast_response_model.dart
import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/current_weather_model.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/hourly_data_model.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/hourly_units_model.dart';

/// Bildet die GESAMTE JSON-Antwort der Open-Meteo Forecast API ab.
class ForecastResponseModel {
  final double latitude;
  final double longitude;
  final double generationTimeMs;
  final int utcOffsetSeconds;
  final String? timezone; // Nullable machen, falls es fehlt
  final String? timezoneAbbreviation; // Nullable machen
  final double? elevation; // Nullable machen
  // Enthält das aktuelle Wetter, falls angefordert und vorhanden
  final CurrentWeatherModel? currentWeather;
  final HourlyUnitsModel? hourlyUnits;
  final HourlyDataModel? hourly;

  ForecastResponseModel({
    required this.latitude,
    required this.longitude,
    required this.generationTimeMs,
    required this.utcOffsetSeconds,
    this.timezone,
    this.timezoneAbbreviation,
    this.elevation,
    this.currentWeather,
    this.hourlyUnits,
    this.hourly,
  });

  factory ForecastResponseModel.fromJson(Map<String, dynamic> json) {
   try {
      // Grundlegende Metadaten prüfen (müssen da sein)
      final lat = json['latitude'];
      final lon = json['longitude'];
      final genTime = json['generationtime_ms'];
      final utcOffset = json['utc_offset_seconds'];

      if (lat is! num || lon is! num || genTime is! num || utcOffset is! num) {
          throw FormatException('Ungültiges Format oder fehlende Kern-Metadaten im ForecastResponse JSON.');
      }

      // Parse die optionalen Felder sicher
      final tz = json['timezone'] is String ? json['timezone'] as String : null;
      final tzAbbr = json['timezone_abbreviation'] is String ? json['timezone_abbreviation'] as String : null;
      final elev = json['elevation'] is num ? (json['elevation'] as num).toDouble() : null;

      // Parse verschachtelte Objekte nur, wenn sie vorhanden und vom richtigen Typ sind
      final current = json.containsKey('current_weather') && json['current_weather'] is Map<String, dynamic>
          ? CurrentWeatherModel.fromJson(json['current_weather'])
          : null;
      // Stündliche Daten parsen, falls vorhanden
      final units = json.containsKey('hourly_units') && json['hourly_units'] is Map<String, dynamic>
          ? HourlyUnitsModel.fromJson(json['hourly_units'])
          : null;
      final data = json.containsKey('hourly') && json['hourly'] is Map<String, dynamic>
          ? HourlyDataModel.fromJson(json['hourly'])
          : null;

      return ForecastResponseModel(
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        generationTimeMs: genTime.toDouble(),
        utcOffsetSeconds: utcOffset.toInt(),
        timezone: tz,
        timezoneAbbreviation: tzAbbr,
        elevation: elev,
        currentWeather: current,
        hourlyUnits: units, 
        hourly: data, 
      );
   } catch (e, s) {
       // Fange Parsing-Fehler von Untermodellen oder eigene FormatExceptions
        if (e is DataParsingException) rethrow; // Weiterleiten
        throw DataParsingException('Fehler beim Parsen von ForecastResponseModel: ${e.toString()}', s);
     }
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'generationtime_ms': generationTimeMs,
      'utc_offset_seconds': utcOffsetSeconds,
      'timezone': timezone,
      'timezone_abbreviation': timezoneAbbreviation,
      'elevation': elevation,
      'current_weather': currentWeather?.toJson(),
      'hourly_units': hourlyUnits?.toJson(), 
      'hourly': hourly?.toJson(), 
    };
  }
}