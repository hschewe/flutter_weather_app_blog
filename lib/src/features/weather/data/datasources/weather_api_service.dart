// lib/src/features/weather/data/datasources/weather_api_service.dart
import 'dart:convert';      // Für json.decode
import 'dart:async';       // Für TimeoutException
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart'; // Für Ref und Provider

// AppConstants sind hier nicht mehr direkt nötig, da URLs im Service sind
// import 'package:flutter_weather_app_blog/src/core/constants/app_constants.dart';
import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/networking/http_client.dart'; // Generiert
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/models/forecast_response_model.dart';
import 'package:flutter_weather_app_blog/src/core/constants/app_constants.dart'; // Für Archive API URLs
import 'package:flutter_weather_app_blog/src/features/weather/data/models/historical_response_model.dart'; 

part 'weather_api_service.g.dart'; // Wird generiert

final _log = AppLogger.getLogger('WeatherApiService');

// Stellt den WeatherApiService über Riverpod bereit
@riverpod
WeatherApiService weatherApiService(Ref ref) {
  // Nutzt den httpClient Provider aus dem Core Layer
  return WeatherApiService(ref.watch(httpClientProvider));
}

class WeatherApiService {
  final http.Client _client;
  static const String _apiBaseUrl = 'api.open-meteo.com'; // Basis-URL
  static const String _forecastEndpoint = '/v1/forecast'; // Endpunkt

  WeatherApiService(this._client);

  /// Ruft aktuelle Wetterdaten UND stündlichen Verlauf/Prognose ab. Umbenannt und erweitert!
  Future<ForecastResponseModel> getForecastWeather({
    required double latitude,
    required double longitude,
    int pastDays = 7,      // Standardmäßig 7 Tage Vergangenheit
    int forecastDays = 7,  // Standardmäßig 7 Tage Zukunft
  }) async {
    _log.fine('getForecastWeather API call für Lat: $latitude, Lon: $longitude, Past: $pastDays, Forecast: $forecastDays');
    final queryParameters = {
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'current_weather': 'true',
      'hourly': 'temperature_2m',
      'past_days': pastDays.toString(),
      'forecast_days': forecastDays.toString(),
      'timezone': 'auto',
    };

    // Baue die vollständige URL zusammen
    final uri = Uri.https(
        _apiBaseUrl,
        _forecastEndpoint,
        queryParameters,
    );

    _log.finer('API Request URI: $uri');

    try {
      // Sende die GET-Anfrage mit Timeout
      // Timeout ggf. etwas erhöhen, da mehr Daten geladen werden
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));

      _log.finer('API Response Status Code: ${response.statusCode}');
      // _log.finest('API Response Body: ${response.body}'); // Nur zum Debuggen aktivieren!

      // Prüfe, ob die Anfrage erfolgreich war (Status Code 200)
      if (response.statusCode == 200) {
        try {
          // Wandle den JSON-Antworttext in ein Dart-Map-Objekt um
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          // Manchmal sendet die API auch bei Status 200 einen Fehler im Body
          if (jsonResponse.containsKey('error') && jsonResponse['error'] == true) {
             final reason = jsonResponse['reason'] ?? 'Unbekannter API Fehler';
             _log.severe('API Fehler im JSON zurückgegeben: $reason');
             throw ApiException(reason, statusCode: response.statusCode);
          }

          // Parse die JSON-Map in unser Datenmodell
          return ForecastResponseModel.fromJson(jsonResponse);
        } on FormatException catch (e, s) { // Fehler beim JSON-Decoding
            _log.severe('Fehler beim Dekodieren der API Antwort (JSON ungültig)', e, s);
            throw DataParsingException('Ungültiges JSON von der Wetter-API erhalten.', s);
        } on DataParsingException { // Fehler aus fromJson weiterleiten
            rethrow;
        } catch (e, s) { // Andere Fehler beim Parsen
           _log.severe('Unerwarteter Fehler beim Parsen der API Antwort', e, s);
           throw DataParsingException('Antwort der Wetter-API konnte nicht verarbeitet werden.', s);
        }
      } else {
        // Wenn der Status Code nicht 200 ist (z.B. 400, 500)
        _log.severe('API Fehler: Status Code ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          'Fehler von der Wetter-API (Status: ${response.statusCode}).',
          statusCode: response.statusCode
        );
      }
    } on http.ClientException catch (e, s) { // Fehler auf Netzwerkebene (keine Verbindung etc.)
        _log.severe('Netzwerkfehler beim Abrufen der aktuellen Daten', e, s);
        throw NetworkException('Netzwerkfehler: ${e.message}', s);
    } on TimeoutException catch (e, s) { // Zeitüberschreitung
        _log.warning('Timeout beim Abrufen der aktuellen Daten', e, s);
        throw NetworkException('Zeitüberschreitung bei der Wetter-API Anfrage.', s);
    } catch (e, s) { // Alle anderen Fehler auffangen
        // Bekannte Fehler weiterleiten, unbekannte als ApiException behandeln
        if (e is AppException) rethrow;
        _log.severe('Unerwarteter Fehler in getCurrentWeather', e, s);
        throw ApiException('Ein unerwarteter Fehler ist aufgetreten: ${e.runtimeType}', stackTrace: s);
    }
  }

  Future<HistoricalResponseModel> getHistoricalDailyTemperatures({
    required double latitude,
    required double longitude,
    required String startDate, // Format YYYY-MM-DD
    required String endDate,   // Format YYYY-MM-DD
  }) async {
     _log.fine('getHistoricalDailyTemperatures API call für Lat: $latitude, Lon: $longitude, von $startDate bis $endDate');
     final queryParameters = {
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'start_date': startDate,
      'end_date': endDate,
      'daily': 'temperature_2m_mean', // Tägliche Durchschnittstemperatur
      'timezone': 'auto', // Wichtig für korrekte Tagesgrenzen
    };

    // Nutze die Konstanten für die Archiv-API
    final uri = Uri.https(
      AppConstants.openMeteoArchiveApiBaseUrl,
      AppConstants.openMeteoArchiveEndpoint,
      queryParameters,
    );

    _log.finer('API Request URI (Archiv): $uri');

    try {
      // Etwas längeres Timeout für potenziell größere Archivdaten
      final response = await _client.get(uri).timeout(const Duration(seconds: 20));
      _log.finer('API Response Status Code (Archiv): ${response.statusCode}');

       if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
           if (jsonResponse.containsKey('error') && jsonResponse['error'] == true) {
             final reason = jsonResponse['reason'] ?? 'Unbekannter API Fehler (Archiv)';
             _log.severe('API Fehler im JSON zurückgegeben (Archiv): $reason');
             throw ApiException(reason, statusCode: response.statusCode);
          }
          return HistoricalResponseModel.fromJson(jsonResponse);
        } on FormatException catch (e, s) {
            _log.severe('Fehler beim Dekodieren der Historical API Antwort (JSON ungültig)', e, s);
            throw DataParsingException('Ungültiges JSON von der Wetter-Archiv-API erhalten.', s);
        } on DataParsingException {
            rethrow;
        } catch (e, s) {
           _log.severe('Unerwarteter Fehler beim Parsen der Historical API Antwort', e, s);
           throw DataParsingException('Antwort der Wetter-Archiv-API konnte nicht verarbeitet werden.', s);
        }
      } else {
        _log.severe('API Fehler (Archiv): Status Code ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          'Fehler von der Wetter-Archiv-API (Status: ${response.statusCode}).',
          statusCode: response.statusCode
        );
      }
    } on http.ClientException catch (e, s) {
      _log.severe('Netzwerkfehler beim Abrufen der historischen Daten', e, s);
      throw NetworkException('Netzwerkfehler: ${e.message}', s);
    } on TimeoutException catch (e, s) {
       _log.warning('Timeout beim Abrufen der historischen Daten', e, s);
       throw NetworkException('Zeitüberschreitung bei der Wetter-Archiv-API Anfrage.', s);
    } catch (e, s) {
       if (e is AppException) rethrow;
       _log.severe('Unerwarteter Fehler in getHistoricalDailyTemperatures', e, s);
       throw ApiException('Ein unerwarteter Fehler ist aufgetreten: ${e.runtimeType}', stackTrace: s);
    }
  }   
}