// lib/src/features/weather/data/repositories/weather_repository_impl.dart
import 'package:flutter_weather_app_blog/src/core/constants/app_constants.dart';
import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/error/failure.dart';
import 'package:flutter_weather_app_blog/src/core/location/location_service.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/datasources/weather_api_service.dart';
// Ersetze CurrentWeatherData durch WeatherData
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/weather_data.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/location_info.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:fpdart/fpdart.dart'; // Für Either
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException; // Für Position
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart'; // Für Ref und Provider
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/chart_point.dart';

part 'weather_repository_impl.g.dart'; // Wird generiert

final _log = AppLogger.getLogger('WeatherRepositoryImpl');

// Stellt die Repository-Implementierung über Riverpod bereit
@riverpod
WeatherRepository weatherRepository(Ref ref) {
  // Das Repository bekommt die Services, die es braucht, über 'ref.watch'
  return WeatherRepositoryImpl(
    ref.watch(weatherApiServiceProvider), // Holt den API Service
    ref.watch(locationServiceProvider),   // Holt den Location Service
  );
}

/// Konkrete Implementierung des WeatherRepository-Vertrags.
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherApiService _apiService;
  final LocationService _locationService;

  WeatherRepositoryImpl(this._apiService, this._locationService);

  @override
  Future<Either<Failure, WeatherData>> getWeatherForLocation(LocationInfo location) async {
    _log.fine('Repo: getWeatherForLocation für ${location.displayName}');
    try {
      // Rufe jetzt getForecastWeather auf, um auch stündliche Daten zu bekommen
      final forecastResponse = await _apiService.getForecastWeather(
        latitude: location.latitude,
        longitude: location.longitude,
        // pastDays und forecastDays werden im Service mit Defaults belegt
      );

      // Aktuelle Temperatur und Zeit
      final currentTemp = forecastResponse.currentWeather?.temperature ?? double.nan;
      final lastUpdated = forecastResponse.currentWeather?.time;
      // Stündliche Daten für Chart aufbereiten
      List<ChartPoint> hourlyPoints = [];
      if (forecastResponse.hourly != null &&
          forecastResponse.hourly!.time.isNotEmpty &&
          forecastResponse.hourly!.time.length == forecastResponse.hourly!.temperature2m.length) {
        for (int i = 0; i < forecastResponse.hourly!.time.length; i++) {
          final time = forecastResponse.hourly!.time[i];
          final temp = forecastResponse.hourly!.temperature2m[i];
          // Nur gültige Punkte hinzufügen (Temperatur nicht NaN)
          if (!temp.isNaN) {
            hourlyPoints.add(ChartPoint(time: time, temperature: temp));
          } else {
            _log.finest('Repo: Überspringe NaN Stundenwert bei ${time.toIso8601String()} für ${location.displayName}');
          }
        }
      } else {
        _log.warning('Repo: Keine oder inkonsistente stündliche Daten für ${location.displayName} erhalten.');
      }

      // Erstelle das umfassende WeatherData Objekt
      final weatherData = WeatherData(
        currentTemperature: currentTemp,
        lastUpdatedTime: lastUpdated,
        hourlyForecast: hourlyPoints,
        // greenlandTemperatureSum wird in Teil 6 hinzugefügt
      );

      _log.info('Wetterdaten (inkl. stündlich) erfolgreich geholt und gemappt für ${location.displayName}');
      return Right(weatherData);
      
    } on NetworkException catch (e, s) { // Netzwerkfehler abfangen
      _log.warning('Repo: Netzwerkfehler bei getWeather', e, s);
      return Left(NetworkFailure()); // Als NetworkFailure weitergeben
    } on ApiException catch (e, s) { // API-Fehler abfangen
      _log.warning('Repo: API Fehler bei getWeather', e, s);
      return Left(ServerFailure(e.message)); // Als ServerFailure weitergeben
    } on DataParsingException catch (e, s) { // Parse-Fehler abfangen
       _log.severe('Repo: Datenparsefehler bei getWeather', e, s);
       return Left(ServerFailure(e.message)); // Als ServerFailure weitergeben
    } catch (e, s) { // Alle anderen Fehler
      _log.severe('Repo: Unerwarteter Fehler bei getWeather', e, s);
      return Left(UnknownFailure(e.toString())); // Als UnknownFailure weitergeben
    }
  }

  @override
  Future<Either<Failure, String>> getLocationDisplayName(double latitude, double longitude) async {
     _log.fine('Repo: getLocationDisplayName für $latitude, $longitude');
    try {
      // Nutze den LocationService für Reverse Geocoding (noch nicht implementiert)
      final address = await _locationService.getAddressFromCoordinates(latitude, longitude);
      if (address != null && address.isNotEmpty) {
        _log.info('Repo: Anzeigename gefunden: $address');
        return Right(address);
      } else {
         _log.info('Repo: Kein Anzeigename gefunden, nutze Koordinaten.');
        // Fallback, wenn Reverse Geocoding (noch) nichts liefert
        return Right('${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}');
      }
    } catch (e, s) { // Fehler beim Reverse Geocoding (sollte nicht passieren in Teil 3)
      _log.severe('Repo: Fehler bei getLocationDisplayName', e, s);
       // Fallback bei unerwartetem Fehler
       return Right('${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}');
    }
  }

  @override
  Future<Either<Failure, LocationInfo>> getCurrentLocationCoordinates() async {
     _log.fine('Repo: getCurrentLocationCoordinates');
    try {
      // Nutze den LocationService, um die Position zu holen
      final Position position = await _locationService.getCurrentPosition();

      // Erstelle ein LocationInfo-Objekt mit Standardnamen
      final locationInfo = LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        displayName: AppConstants.myLocationLabel, // Standardname
      );
       _log.info('Repo: GPS Koordinaten erhalten: Lat ${locationInfo.latitude}, Lon ${locationInfo.longitude}');
      return Right(locationInfo);

    } on LocationServiceDisabledException catch (e,s) { // Standortdienste aus?
        _log.warning('Repo: Standortdienste deaktiviert.', e, s);
        return Left(LocationFailure(e.message)); // Als LocationFailure
    } on LocationPermissionDeniedException catch (e, s) { // Berechtigung fehlt?
        _log.warning('Repo: Standortberechtigung verweigert.', e, s);
        return Left(PermissionFailure(e.message)); // Als PermissionFailure
    } on LocationException catch (e, s) { // Andere Standortfehler?
        _log.warning('Repo: Allgemeiner Standortfehler.', e, s);
        return Left(LocationFailure(e.message)); // Als LocationFailure
    } catch (e, s) { // Alle anderen Fehler
       _log.severe('Repo: Unerwarteter Fehler bei getCurrentLocationCoordinates', e, s);
       return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationInfo>> getCoordinatesForAddress(String address) async {
     _log.fine('Repo: getCoordinatesForAddress für "$address"');
     try {
       // Rufe den LocationService auf
       final geocoding.Location location = await _locationService.getCoordinatesFromAddress(address);

       // Optional: Versuche, den Namen für die Anzeige zu verfeinern
       final refinedDisplayNameResult = await getLocationDisplayName(location.latitude, location.longitude);
       // Nimm den verfeinerten Namen, oder die ursprüngliche Suche als Fallback
       final displayName = refinedDisplayNameResult.fold(
            (failure) => address, // Bei Fehler nimm die ursprüngliche Suche
            (name) => name // Bei Erfolg nimm den gefundenen Namen
       );

       final locationInfo = LocationInfo(
         latitude: location.latitude,
         longitude: location.longitude,
         displayName: displayName,
       );
       _log.info('Repo: Koordinaten für "$address" gefunden und gemappt: ${locationInfo.displayName}');
       return Right(locationInfo);

     } on GeocodingException catch (e, s) { // Spezifischen Geocoding-Fehler fangen
         _log.warning('Repo: Geocoding Fehler für "$address".', e, s);
         return Left(GeocodingFailure(e.message)); // Als GeocodingFailure zurückgeben
     } catch (e, s) { // Andere unerwartete Fehler
        _log.severe('Repo: Unerwarteter Fehler bei getCoordinatesForAddress für "$address"', e, s);
        return Left(UnknownFailure('Fehler bei der Adresssuche: ${e.toString()}'));
     }
   }
}