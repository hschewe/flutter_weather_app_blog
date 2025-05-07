import 'package:equatable/equatable.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/chart_point.dart';

/// Repräsentiert die aufbereiteten Wetterdaten für die Anzeige in der UI,
/// inklusive aktueller Temperatur und stündlicher Vorhersage/Verlauf.
class WeatherData extends Equatable {
  final double currentTemperature;
  final DateTime? lastUpdatedTime; // Zeit der aktuellen Temperatur (kann fehlen)
  final List<ChartPoint> hourlyForecast; // Kombinierte Vergangenheit & Zukunft für Chart

  // GTS wird in Teil 6 hinzugefügt
  // final double greenlandTemperatureSum;

  const WeatherData({
    required this.currentTemperature,
    this.lastUpdatedTime,
    required this.hourlyForecast,
    // required this.greenlandTemperatureSum,
  });

  @override
  List<Object?> get props => [
        currentTemperature,
        lastUpdatedTime,
        hourlyForecast,
        // greenlandTemperatureSum,
      ];

  // Leerer Zustand für Initialisierung
  static final WeatherData empty = WeatherData(
    currentTemperature: double.nan,
    lastUpdatedTime: null,
    hourlyForecast: const [], // Leere Liste für den Chart
    // greenlandTemperatureSum: double.nan,
  );

  // Hilfsmethode für das Kopieren und Ändern des Zustands
  WeatherData copyWith({
    double? currentTemperature,
    DateTime? lastUpdatedTime,
    bool setLastUpdatedTimeToNull = false,
    List<ChartPoint>? hourlyForecast,
    // double? greenlandTemperatureSum,
  }) {
    return WeatherData(
      currentTemperature: currentTemperature ?? this.currentTemperature,
      lastUpdatedTime: setLastUpdatedTimeToNull ? null : (lastUpdatedTime ?? this.lastUpdatedTime),
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      // greenlandTemperatureSum: greenlandTemperatureSum ?? this.greenlandTemperatureSum,
    );
  }
}