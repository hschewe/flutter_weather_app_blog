import 'package:flutter_weather_app_blog/src/core/error/exceptions.dart';
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart'; 
import 'package:geocoding/geocoding.dart' as geocoding;

part 'location_service.g.dart'; // Wird generiert

final _log = AppLogger.getLogger('LocationService');

// Stellt den LocationService über Riverpod bereit
@riverpod
LocationService locationService(Ref ref) {
  // Wir übergeben jetzt beide Plattform-Instanzen
  return LocationService(
    GeolocatorPlatform.instance,
    geocoding.GeocodingPlatform.instance!, // NEU
  );}

class LocationService {
  final GeolocatorPlatform _geolocator;
  final geocoding.GeocodingPlatform _geocoding;

  LocationService(this._geolocator , this._geocoding);

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

  /// Wandelt eine Adresse oder einen Ortsnamen in Koordinaten (Lat/Lon) um.
  /// Wirft GeocodingException, wenn die Adresse nicht gefunden wird.
  Future<geocoding.Location> getCoordinatesFromAddress(String address) async {
    _log.fine('getCoordinatesFromAddress aufgerufen für: "$address"');
    try {
      // Nutze das geocoding Paket
      List<geocoding.Location> locations = await _geocoding.locationFromAddress(address);
      if (locations.isEmpty) {
        _log.warning('Keine Koordinaten für Adresse gefunden: "$address"');
        throw GeocodingException('Adresse "$address" konnte nicht gefunden werden.');
      }
      // Nimm das erste Ergebnis (oft das relevanteste)
      final location = locations.first;
      _log.info('Koordinaten für "$address": Lat ${location.latitude}, Lon ${location.longitude}');
      return location;
    } on geocoding.NoResultFoundException catch (e, s) { // Spezifischer Fehler vom Paket
      _log.warning('Geocoding NoResultFoundException für "$address"', e, s);
      // Wandle in unsere eigene Exception um
      throw GeocodingException('Adresse "$address" konnte nicht gefunden werden.', s);
    } catch (e, s) { // Alle anderen Fehler (Netzwerkprobleme beim Geocoding etc.)
      _log.severe('Unerwarteter Fehler beim Geocoding für "$address"', e, s);
      throw GeocodingException('Fehler bei der Adressumwandlung.', s);
    }
  }


  /// Wandelt Koordinaten in eine lesbare Adresse um (Reverse Geocoding).
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
     _log.fine('getAddressFromCoordinates aufgerufen für: Lat $latitude, Lon $longitude');
    try {
      // Nutze placemarkFromCoordinates für Reverse Geocoding
      List<geocoding.Placemark> placemarks = await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Baue einen sinnvollen Namen zusammen (kann angepasst werden)
        String address = [
          place.locality,        // Stadt (z.B. Berlin)
          place.subLocality,     // Stadtteil (z.B. Mitte) - falls verfügbar
          place.thoroughfare,    // Straße (z.B. Unter den Linden) - falls verfügbar
          place.administrativeArea, // Bundesland/Region (z.B. Berlin)
          place.country          // Land (z.B. Deutschland)
        ]
          .where((s) => s != null && s.isNotEmpty) // Filtere leere Teile
          .take(3) // Nimm z.B. nur die ersten 3 nicht-leeren Teile für Kürze
          .join(', '); // Verbinde mit Komma

         _log.info('Adresse für $latitude, $longitude gefunden: $address');
         // Fallback, wenn keine sinnvollen Teile gefunden wurden
        return address.isEmpty ? "${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}" : address;
      }
       _log.warning('Keine Adresse für $latitude, $longitude gefunden.');
      return null; // Keine Adresse gefunden
    } catch (e, s) {
      _log.severe('Fehler beim Reverse Geocoding für $latitude, $longitude', e, s);
      return null; // Fehler beim Reverse Geocoding
    }
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