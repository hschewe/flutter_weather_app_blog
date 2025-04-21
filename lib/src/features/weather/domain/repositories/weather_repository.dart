// lib/src/features/weather/domain/repositories/weather_repository.dart
import 'package:flutter_weather_app_blog/src/core/error/failure.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/current_weather_data.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/location_info.dart';
import 'package:fpdart/fpdart.dart'; // Für Either

/// Definiert den "Vertrag", welche Datenoperationen im Wetter-Feature benötigt werden.
/// Dies ist eine Abstraktionsebene: Wir sagen WAS wir brauchen, nicht WIE.
abstract class WeatherRepository {
  /// Ruft die aktuellen Wetterdaten für einen gegebenen Standort ab.
  /// Gibt entweder einen Fehler (Failure) oder die Wetterdaten (CurrentWeatherData) zurück.
  /// `Either<Left, Right>`: Ein Typ, der entweder einen Fehler (links) oder Erfolg (rechts) hält.
  Future<Either<Failure, CurrentWeatherData>> getWeatherForLocation(LocationInfo location);

  /// Holt den Anzeigenamen für gegebene Koordinaten (Reverse Geocoding).
  Future<Either<Failure, String>> getLocationDisplayName(double latitude, double longitude);

  /// Holt die Koordinaten für den aktuellen Gerätestandort (GPS).
  Future<Either<Failure, LocationInfo>> getCurrentLocationCoordinates();

  /// Holt die Koordinaten für eine gegebene Adresse.
  Future<Either<Failure, LocationInfo>> getCoordinatesForAddress(String address);
  
  // Future<Either<Failure, FullWeatherData>> getFullWeather(...) // Für Diagramm/GTS
}