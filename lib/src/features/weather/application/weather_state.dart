// lib/src/features/weather/application/weather_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_weather_app_blog/src/core/error/failure.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/weather_data.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/location_info.dart';

/// Definiert die möglichen Zustände für das Laden von Wetterdaten.
enum WeatherStatus { initial, loading, success, failure }

/// Repräsentiert den gesamten Zustand des Wetter-Features zu einem Zeitpunkt.
class WeatherState extends Equatable {
  final WeatherStatus status; // Der aktuelle Lade-/Fehlerstatus
  final WeatherData weatherData; // Die aktuell angezeigten Wetterdaten
  final LocationInfo? selectedLocation; // Der Ort, für den die Daten gelten
  final Failure? error; // Das Fehlerobjekt, falls status == failure

  // Konstruktor
  const WeatherState({
    required this.status,
    required this.weatherData,
    this.selectedLocation,
    this.error,
  });

  // Fabrik-Methode für den initialen Zustand beim App-Start
  factory WeatherState.initial() {
    return WeatherState(
      status: WeatherStatus.initial,
      weatherData: WeatherData.empty, // Starte mit leeren Daten
      selectedLocation: null, // Kein Ort ausgewählt
      error: null, // Kein Fehler
    );
  }

  @override
  List<Object?> get props => [status, weatherData, selectedLocation, error];

  /// Erstellt eine Kopie des aktuellen Zustands mit geänderten Werten.
  /// Das ist nützlich, um den Zustand unveränderlich (immutable) zu halten.
  WeatherState copyWith({
    WeatherStatus? status,
    WeatherData? weatherData,
    LocationInfo? selectedLocation,
    // Ermöglicht das explizite Löschen des Ortes
    bool clearSelectedLocation = false,
    Failure? error,
    // Ermöglicht das explizite Löschen des Fehlers
    bool clearError = false,
  }) {
    return WeatherState(
      status: status ?? this.status, // Nimm neuen Wert oder alten
      weatherData: weatherData ?? this.weatherData,
      selectedLocation: clearSelectedLocation ? null : (selectedLocation ?? this.selectedLocation),
      error: clearError ? null : (error ?? this.error),
    );
  }
}