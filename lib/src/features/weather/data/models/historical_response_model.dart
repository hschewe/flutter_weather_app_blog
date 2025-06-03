import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/daily_data_model.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/daily_units_model.dart';

/// Datenmodell für die gesamte Antwort des Open-Meteo Archive API Endpunkts.
class HistoricalResponseModel {
   final double latitude;
  final double longitude;
  final double generationTimeMs;
  final int utcOffsetSeconds;
  final String? timezone;
  final String? timezoneAbbreviation;
  final double? elevation;
  final DailyUnitsModel? dailyUnits;
  final DailyDataModel? daily;

  HistoricalResponseModel({
    required this.latitude,
    required this.longitude,
    required this.generationTimeMs,
    required this.utcOffsetSeconds,
    this.timezone,
    this.timezoneAbbreviation,
    this.elevation,
    this.dailyUnits,
    this.daily,
  });

 factory HistoricalResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      final lat = json['latitude'];
      final lon = json['longitude'];
      final genTime = json['generationtime_ms'];
      final utcOffset = json['utc_offset_seconds'];

      if (lat is! num || lon is! num || genTime is! num || utcOffset is! num) {
           throw FormatException('Ungültiges Format oder fehlende Kern-Metadaten im HistoricalResponse JSON.');
      }

      final tz = json['timezone'] is String ? json['timezone'] as String : null;
      final tzAbbr = json['timezone_abbreviation'] is String ? json['timezone_abbreviation'] as String : null;
      final elev = json['elevation'] is num ? (json['elevation'] as num).toDouble() : null;

      final units = json.containsKey('daily_units') && json['daily_units'] is Map<String, dynamic>
          ? DailyUnitsModel.fromJson(json['daily_units'])
          : null;
      final data = json.containsKey('daily') && json['daily'] is Map<String, dynamic>
          ? DailyDataModel.fromJson(json['daily'])
          : null;

      return HistoricalResponseModel(
         latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        generationTimeMs: genTime.toDouble(),
        utcOffsetSeconds: utcOffset.toInt(),
        timezone: tz,
        timezoneAbbreviation: tzAbbr,
        elevation: elev,
        dailyUnits: units,
        daily: data,
      );
   } catch (e, s) {
        if (e is DataParsingException || e is FormatException) rethrow;
        throw DataParsingException('Fehler beim Parsen von HistoricalResponseModel: ${e.toString()}', s);
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
      'daily_units': dailyUnits?.toJson(),
      'daily': daily?.toJson(),
    };
  }
}