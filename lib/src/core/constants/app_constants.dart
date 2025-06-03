// lib/src/core/constants/app_constants.dart
class AppConstants {
  // Standard-Ortsname für GPS, bis Reverse Geocoding funktioniert
  static const String myLocationLabel = "Mein Standort";

  // NEU: Open Meteo Archive API für historische Daten
  static const String openMeteoArchiveApiBaseUrl = 'archive-api.open-meteo.com';
  static const String openMeteoArchiveEndpoint = '/v1/archive';

  // NEU: GTS Berechnungsparameter
  static const double gtsBaseTemperature = 0.0; // Basis-Temperatur für GTS (positive Tagessumme)
  static const Map<int, double> gtsMonthlyFactors = {
    // Monat : Faktor
    1: 0.5,  // Januar
    2: 0.75, // Februar
    // Ab März: Faktor 1.0 (Standard, muss nicht explizit in die Map)
  };
  // Für das Caching von GTS-Daten, um API-Anfragen zu reduzieren
  static const int gtsLocationCachePrecision = 2; // Nachkommastellen für Lat/Lon im Cache-Key
}