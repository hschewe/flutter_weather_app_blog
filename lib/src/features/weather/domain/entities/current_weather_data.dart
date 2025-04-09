// lib/src/features/weather/domain/entities/current_weather_data.dart
import 'package:equatable/equatable.dart';

/// Repräsentiert die aufbereiteten aktuellen Wetterdaten für die Anzeige in der UI (Teil 3).
/// Dies ist die "saubere" Datenstruktur, die unsere App verwendet.
class CurrentWeatherData extends Equatable {
  final double temperature;
  final DateTime lastUpdatedTime;

  const CurrentWeatherData({
    required this.temperature,
    required this.lastUpdatedTime,
  });

  @override
  List<Object?> get props => [temperature, lastUpdatedTime];

  // Ein "leerer" oder initialer Zustand für diese Daten.
  // Wird verwendet, bevor die ersten echten Daten geladen wurden.
  static final CurrentWeatherData empty = CurrentWeatherData(
    temperature: double.nan, // NaN (Not a Number) signalisiert einen ungültigen oder fehlenden Wert.
    lastUpdatedTime: DateTime.fromMillisecondsSinceEpoch(0), // Ein Dummy-Zeitstempel
  );
}