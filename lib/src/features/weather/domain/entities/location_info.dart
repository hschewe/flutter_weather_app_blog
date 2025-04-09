// lib/src/features/weather/domain/entities/location_info.dart
import 'package:equatable/equatable.dart';

/// Repräsentiert einen Standort mit Koordinaten und einem Anzeigenamen in der App.
class LocationInfo extends Equatable {
  final double latitude;
  final double longitude;
  final String displayName; // z.B. "Berlin", "Mein Standort"

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  @override
  List<Object?> get props => [latitude, longitude, displayName];

  // Hilfsmethode, um eine Kopie mit geänderten Werten zu erstellen
  LocationInfo copyWith({
    double? latitude,
    double? longitude,
    String? displayName,
  }) {
    return LocationInfo(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      displayName: displayName ?? this.displayName,
    );
  }
}