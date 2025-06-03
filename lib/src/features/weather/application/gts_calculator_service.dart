import 'dart:math';
import 'package:flutter_weather_app_blog/src/core/constants/app_constants.dart';
import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/utils/date_formatter.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/datasources/weather_api_service.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/daily_data_model.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/forecast_response_model.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/location_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart'; // Für Ref und Provider


part 'gts_calculator_service.g.dart'; // Riverpod Generator

final _log = AppLogger.getLogger('GtsCalculatorService');

// Provider für den GtsCalculatorService
@riverpod
GtsCalculatorService gtsCalculatorService(Ref ref) {
  return GtsCalculatorService(ref.watch(weatherApiServiceProvider));
}

// Einfacher In-Memory Cache für historische GTS-Daten (pro Standort-CacheKey)
// Speichert das DailyDataModel und den Zeitpunkt des Abrufs
final _historicalDataCache = <String, ({DateTime lastFetchTime, DailyDataModel data})>{};
// Einfacher In-Memory Cache für Forecast-Daten (für die Ergänzung der letzten Tage)
final _forecastForGtsCache = <String, ({DateTime lastFetchTime, ForecastResponseModel data})>{};


class GtsCalculatorService {
  final WeatherApiService _apiService;
  final Duration _cacheDuration = const Duration(hours: 6); // Wie lange Cache-Einträge gültig sind

  GtsCalculatorService(this._apiService);

  /// Erstellt einen Cache-Schlüssel für einen Standort basierend auf gerundeten Koordinaten.
  String _getLocationCacheKey(LocationInfo location) {
    final latRounded = location.latitude.toStringAsFixed(AppConstants.gtsLocationCachePrecision);
    final lonRounded = location.longitude.toStringAsFixed(AppConstants.gtsLocationCachePrecision);
    return 'lat=${latRounded}_lon=$lonRounded';
  }

  /// Berechnet die Grünlandtemperatursumme (GTS) für den gegebenen Standort.
  Future<double> calculateGtsForLocation(LocationInfo location) async {
    _log.fine('calculateGtsForLocation aufgerufen für: ${location.displayName}');
    final cacheKey = _getLocationCacheKey(location);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Heutiges Datum ohne Zeit
    final yesterday = today.subtract(const Duration(days: 1)); // Gestern
    final startOfYear = DateTime(now.year, 1, 1); // 1. Januar des aktuellen Jahres

    DailyDataModel? historicalData;

    // 1. Cache für historische Daten prüfen
    if (_historicalDataCache.containsKey(cacheKey)) {
      final cachedEntry = _historicalDataCache[cacheKey]!;
      if (now.difference(cachedEntry.lastFetchTime) < _cacheDuration) {
        _log.info('GTS: Historische Daten aus Cache für $cacheKey');
        historicalData = cachedEntry.data;
      } else {
        _log.info('GTS: Cache für historische Daten ($cacheKey) abgelaufen.');
        _historicalDataCache.remove(cacheKey);
      }
    }

    // 2. Wenn nicht im Cache oder veraltet, von API holen
    if (historicalData == null) {
      _log.fine('GTS: Hole historische Daten von API für $cacheKey...');
      try {
        final apiResponse = await _apiService.getHistoricalDailyTemperatures(
          latitude: location.latitude,
          longitude: location.longitude,
          startDate: DateFormatter.formatApiDate(startOfYear),
          endDate: DateFormatter.formatApiDate(yesterday), // Daten bis gestern
        );

        if (apiResponse.daily == null || apiResponse.daily!.time.isEmpty) {
           _log.warning('GTS: Keine historischen Daten von API erhalten für $cacheKey.');
           throw GtsCalculationException('Keine historischen Temperaturdaten verfügbar.');
        }
        historicalData = apiResponse.daily!;
        _historicalDataCache[cacheKey] = (lastFetchTime: now, data: historicalData);
        _log.info('GTS: Historische Daten für $cacheKey in Cache gespeichert.');
      } on ApiException catch (e, s) {
         _log.severe('GTS: API Fehler beim Holen der historischen Daten', e, s);
         throw GtsCalculationException('Fehler beim Abrufen der historischen Daten: ${e.message}', s);
      } catch (e, s) {
         _log.severe('GTS: Unerwarteter Fehler beim Holen der historischen Daten', e, s);
         if (e is GtsCalculationException) rethrow;
         throw GtsCalculationException('Unerwarteter Fehler bei historischen Daten.', s);
      }
    }

    // Map zur Speicherung der Tagesmittelwerte (Datum -> Temperatur)
    Map<DateTime, double> dailyAverages = {};
    for (int i = 0; i < historicalData.time.length; i++) {
        if (!historicalData.temperature2mMean[i].isNaN) {
           // Stelle sicher, dass wir das Datum ohne Zeitkomponente verwenden
           final dateOnly = DateTime(historicalData.time[i].year, historicalData.time[i].month, historicalData.time[i].day);
           dailyAverages[dateOnly] = historicalData.temperature2mMean[i];
        }
    }

    // 3. Prüfen, ob Daten bis gestern reichen und ggf. mit Forecast-Daten der letzten Tage ergänzen
    DateTime? lastHistoricalDate = dailyAverages.keys.isNotEmpty ? dailyAverages.keys.reduce((a,b) => a.isAfter(b) ? a : b) : null;

    if (lastHistoricalDate == null || lastHistoricalDate.isBefore(yesterday)) {
      _log.info('GTS: Historische Daten reichen nicht bis gestern. Versuche Forecast-Ergänzung für $cacheKey...');
      ForecastResponseModel? forecastForGts;

      // Cache für Forecast-Daten prüfen
      if (_forecastForGtsCache.containsKey(cacheKey)) {
        final cachedEntry = _forecastForGtsCache[cacheKey]!;
        if (now.difference(cachedEntry.lastFetchTime) < _cacheDuration) { // Evtl. kürzere Cache-Dauer für Forecast
           _log.info('GTS: Forecast-Daten für Ergänzung aus Cache für $cacheKey');
           forecastForGts = cachedEntry.data;
        } else {
           _log.info('GTS: Cache für Forecast-Daten ($cacheKey) abgelaufen.');
           _forecastForGtsCache.remove(cacheKey);
        }
      }

      if (forecastForGts == null) {
        _log.fine('GTS: Hole Forecast-Daten für Ergänzung von API für $cacheKey...');
        try {
          // Fordere nur die letzten paar Tage an, um die Lücke zu füllen (max. 7 Tage)
          final daysNeeded = yesterday.difference(lastHistoricalDate ?? startOfYear.subtract(const Duration(days:1))).inDays;
          forecastForGts = await _apiService.getForecastWeather(
              latitude: location.latitude,
              longitude: location.longitude,
              pastDays: min(daysNeeded + 1, 7), // Fordere nur die nötigen Tage, max 7
              forecastDays: 0 // Keine Zukunftsprognose nötig
          );
          _forecastForGtsCache[cacheKey] = (lastFetchTime: now, data: forecastForGts);
          _log.info('GTS: Forecast-Daten für $cacheKey in Cache gespeichert.');
        } on ApiException catch (e, s) {
           _log.warning('GTS: API Fehler beim Holen der Forecast-Daten für Ergänzung. Berechnung ohne diese Daten.', e, s);
        } catch (e, s) {
           _log.warning('GTS: Unerwarteter Fehler beim Holen der Forecast-Daten für Ergänzung. Berechnung ohne diese Daten.', e, s);
        }
      }

      // Verarbeite Forecast-Daten, um tägliche Mittelwerte zu berechnen
      if (forecastForGts?.hourly != null && forecastForGts!.hourly!.time.isNotEmpty) {
        Map<DateTime, List<double>> tempsByDay = {};
        for (int i = 0; i < forecastForGts.hourly!.time.length; i++) {
          final dateTime = forecastForGts.hourly!.time[i];
          final temp = forecastForGts.hourly!.temperature2m[i];
          final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

          // Nur Tage berücksichtigen, die nach dem letzten historischen Datum liegen und nicht nach gestern
          if (!temp.isNaN &&
              (lastHistoricalDate == null || dateOnly.isAfter(lastHistoricalDate)) &&
              !dateOnly.isAfter(yesterday)) {
            tempsByDay.putIfAbsent(dateOnly, () => []).add(temp);
          }
        }
        // Durchschnitt berechnen und in dailyAverages eintragen/überschreiben
        tempsByDay.forEach((date, temps) {
          if (temps.isNotEmpty) {
            final avg = temps.reduce((a, b) => a + b) / temps.length;
            dailyAverages[date] = avg;
            _log.finer('GTS: Ergänzter Tagesmittelwert für ${DateFormatter.formatApiDate(date)}: ${avg.toStringAsFixed(1)}°C');
          }
        });
      }
    }

    // 4. GTS berechnen
    double gtsSum = 0;
    _log.fine('GTS: Beginne Summenberechnung für $cacheKey...');

    // Iteriere über die sortierten Tage des aktuellen Jahres bis gestern
    List<DateTime> sortedDays = dailyAverages.keys.toList()..sort();
    for (DateTime day in sortedDays) {
       // Nur Tage im aktuellen Jahr und nicht nach gestern berücksichtigen
       if (day.year == now.year && !day.isAfter(yesterday)) {
         final tempMean = dailyAverages[day]!; // Wir wissen, dass der Key existiert
         // Prüfe, ob Temperatur über der Basis liegt (positive Tagessumme)
         if (tempMean > AppConstants.gtsBaseTemperature) {
           // Monatsfaktor holen (Standard 1.0 für März-Dezember)
           double factor = AppConstants.gtsMonthlyFactors[day.month] ?? 1.0;
           double dailyContribution = (tempMean - AppConstants.gtsBaseTemperature) * factor;
           gtsSum += dailyContribution;
           _log.finest('GTS-Tag: ${DateFormatter.formatApiDate(day)}: Tavg=${tempMean.toStringAsFixed(1)}, Faktor=$factor, Beitrag=${dailyContribution.toStringAsFixed(1)}, Summe=${gtsSum.toStringAsFixed(1)}');
         }
       }
    }

    _log.info('GTS: Berechnete Summe für $cacheKey: ${gtsSum.toStringAsFixed(1)}');
    return gtsSum;
  }
}