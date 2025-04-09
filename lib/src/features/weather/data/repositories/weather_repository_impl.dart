// lib/src/features/weather/data/repositories/weather_repository_impl.dart
import 'package:flutter_weather_app_blog/src/core/constants/app_constants.dart';
import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/error/failure.dart';
import 'package:flutter_weather_app_blog/src/core/location/location_service.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/datasources/weather_api_service.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/current_weather_data.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/location_info.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:fpdart/fpdart.dart'; // Für Either
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException; // Für Position
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weather_repository_impl.g.dart'; // Wird generiert

final _log = AppLogger.getLogger('WeatherRepositoryImpl');

// Stellt die Repository-Implementierung über Riverpod bereit
@riverpod
WeatherRepository weatherRepository(WeatherRepositoryRef ref) {
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
  Future<Either<Failure, CurrentWeatherData>> getWeatherForLocation(LocationInfo location) async {
    _log.fine('Repo: getWeatherForLocation für ${location.displayName}');
    try {
      // Rufe die API-Methode auf
      final forecastResponse = await _apiService.getCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      // Extrahiere die relevanten Daten aus der API-Antwort
      final current = forecastResponse.currentWeather;
      if (current?.time == null || current?.temperature.isNaN == true) {
        _log.warning('Unvollständige oder ungültige Wetterdaten von API erhalten.');
        return Left(ServerFailure('Unvollständige Wetterdaten erhalten.'));
      }

      // Wandle das API-Modell in unser App-Entity um
      final weatherData = CurrentWeatherData(
        temperature: current!.temperature,
        lastUpdatedTime: current.time!, // Wir haben oben auf null geprüft
      );

      _log.info('Wetterdaten erfolgreich geholt und gemappt für ${location.displayName}');
      return Right(weatherData); // Erfolg zurückgeben

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
}