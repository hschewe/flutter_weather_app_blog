import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;
import 'package:riverpod_annotation/riverpod_annotation.dart';
// Import für Geocoding (kommt erst in Teil 4)
// import 'package:geocoding/geocoding.dart' as geocoding;

part 'location_service.g.dart'; // Wird generiert

final _log = AppLogger.getLogger('LocationService');

// Stellt den LocationService über Riverpod bereit
@riverpod
LocationService locationService(LocationServiceRef ref) {
  // Wir übergeben die Geolocator-Instanz, um sie testbar zu machen
  return LocationService(GeolocatorPlatform.instance);
}

class LocationService {
  final GeolocatorPlatform _geolocator;
  // Geocoding wird erst in Teil 4 gebraucht
  // final geocoding.GeocodingPlatform _geocoding;

  LocationService(this._geolocator /*, this._geocoding */);

  /// Holt die aktuelle GPS-Position des Geräts.
  /// Wirft LocationException bei Fehlern (Service deaktiviert, Berechtigung verweigert).
  Future<Position> getCurrentPosition() async {
    _log.fine('getCurrentPosition aufgerufen');
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Prüfen, ob Standortdienste überhaupt aktiviert sind
    serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log.warning('Standortdienste sind deaktiviert.');
      throw LocationServiceDisabledException();
    }

    // 2. Berechtigungsstatus prüfen
    permission = await _geolocator.checkPermission();
    _log.fine('Aktueller Berechtigungsstatus: $permission');

    // 3. Wenn Berechtigung fehlt, anfordern
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      _log.info('Berechtigung angefordert, Ergebnis: $permission');
      if (permission == LocationPermission.denied) {
        _log.warning('Standortberechtigung verweigert.');
        throw LocationPermissionDeniedException(permanentlyDenied: false);
      }
    }

    // 4. Wenn Berechtigung permanent verweigert wurde
    if (permission == LocationPermission.deniedForever) {
      _log.warning('Standortberechtigung permanent verweigert.');
      throw LocationPermissionDeniedException(permanentlyDenied: true);
    }

    // 5. Wenn alles ok ist, Position abrufen
    try {
      _log.fine('Versuche, aktuelle Position zu holen...');
      // getCurrentPosition kann manchmal etwas dauern
      final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high, // Fordern hohe Genauigkeit an
      );
      final position = await _geolocator.getCurrentPosition(
         locationSettings: locationSettings, 
         // timeLimit: const Duration(seconds: 10) // Optional: Timeout
       );
      _log.info('Aktuelle Position erhalten: Lat ${position.latitude}, Lon ${position.longitude}');
      return position;
    } catch (e, s) {
      _log.severe('Fehler beim Holen der Position', e, s);
      throw LocationException("Position konnte nicht ermittelt werden: ${e.toString()}", s);
    }
  }

  /// Wandelt Koordinaten in eine lesbare Adresse um (Reverse Geocoding).
  /// Wird erst in Teil 4 relevant, wenn wir Geocoding hinzufügen.
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    _log.fine('getAddressFromCoordinates aufgerufen für: Lat $latitude, Lon $longitude');
    // Implementierung kommt in Teil 4 mit dem 'geocoding'-Paket
    // Vorerst geben wir null zurück oder einen Platzhalter
    _log.info('Reverse Geocoding noch nicht implementiert.');
    // Man könnte hier versuchen, einen Namen über eine andere API zu holen,
    // aber für Teil 3 reicht der Standardname "Mein Standort".
    return null;
  }

  /// Öffnet die App-Einstellungen, damit der Nutzer Berechtigungen ändern kann.
  Future<bool> openAppSettings() async {
    _log.info('Öffne App-Einstellungen...');
    return await _geolocator.openAppSettings();
  }

  /// Öffnet die Geräteeinstellungen für Standortdienste.
  Future<bool> openLocationSettings() async {
    _log.info('Öffne Standort-Einstellungen...');
    return await _geolocator.openLocationSettings();
  }
}