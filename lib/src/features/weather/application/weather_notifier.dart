// lib/src/features/weather/application/weather_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_weather_app_blog/src/core/error/failure.dart'; // Failure-Klassen importieren
import 'package:flutter_weather_app_blog/src/core/location/location_service.dart'; // Für Exceptions
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:flutter_weather_app_blog/src/features/weather/application/weather_state.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/location_info.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/repositories/weather_repository.dart';

final _log = AppLogger.getLogger('WeatherNotifier');

/// Verwaltet den Zustand (WeatherState) und die Geschäftslogik für das Wetter-Feature.
class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherRepository _weatherRepository;
  // Optional: LocationService direkt für openAppSettings/openLocationSettings
  // final LocationService _locationService; // Wenn wir es hier brauchen

  // Konstruktor: Bekommt das Repository (und evtl. andere Services) übergeben.
  // Startet mit dem initialen Zustand.
  WeatherNotifier(this._weatherRepository /*, this._locationService */) : super(WeatherState.initial());

  // fetchWeatherForCurrentLocation (unverändert in der Logik, da _fetchWeatherDataAndUpdateState
  // jetzt mit WeatherData umgeht)
  Future<void> fetchWeatherForCurrentLocation() async {
    _log.info('Notifier: fetchWeatherForCurrentLocation gestartet.');
    // Verhindere doppelte Ausführung, wenn schon geladen wird
    if (state.status == WeatherStatus.loading) {
       _log.fine('Notifier: Ladevorgang läuft bereits, ignoriere erneuten Aufruf.');
       return;
    }

    // Setze Zustand auf 'loading', lösche alten Fehler
    state = state.copyWith(status: WeatherStatus.loading, clearError: true);

    // 1. Versuche, die GPS-Koordinaten zu holen
    final coordinatesResult = await _weatherRepository.getCurrentLocationCoordinates();

    // coordinatesResult ist ein Either<Failure, LocationInfo>
    // fold: Führt die linke Funktion bei Fehler (Left), die rechte bei Erfolg (Right) aus.
    await coordinatesResult.fold(
      (failure) async => state = state.copyWith(status: WeatherStatus.failure, error: failure),
      (locationInfo) async {
        final displayNameResult = await _weatherRepository.getLocationDisplayName(locationInfo.latitude, locationInfo.longitude);
        final finalLocationInfo = displayNameResult.fold((l) => locationInfo, (name) => locationInfo.copyWith(displayName: name));
        await _fetchWeatherDataAndUpdateState(finalLocationInfo);
      },
    );  }

/// Holt Wetterdaten für eine eingegebene Adresse.
  Future<void> fetchWeatherForAddress(String address) async {
    _log.info('Notifier: fetchWeatherForAddress gestartet für "$address".');
    if (address.trim().isEmpty) {
        _log.warning("Notifier: Leere Adresse übergeben.");
        // Optional: Zeige dem User einen Fehler oder ignoriere es einfach
        // state = state.copyWith(status: WeatherStatus.failure, error: GeocodingFailure("Bitte eine Adresse eingeben."));
        return;
    }
    if (state.status == WeatherStatus.loading) {
       _log.fine('Notifier: Ladevorgang läuft bereits, ignoriere Aufruf für "$address".');
       return;
    }
    state = state.copyWith(status: WeatherStatus.loading, clearError: true);

    // 1. Adresse in Koordinaten umwandeln lassen
    final geocodingResult = await _weatherRepository.getCoordinatesForAddress(address);

    // 2. Ergebnis behandeln
    await geocodingResult.fold(
      // Fehlerfall (z.B. Adresse nicht gefunden)
      (failure) async {
        _log.warning('Notifier: Fehler beim Geocoding für "$address": $failure');
        state = state.copyWith(status: WeatherStatus.failure, error: failure);
      },
      // Erfolgsfall (Koordinaten gefunden)
      (locationInfo) async {
        _log.info('Notifier: Koordinaten für "$address" erfolgreich erhalten.');
        // 3. Wetterdaten für diese Koordinaten holen (nutzt die bestehende Methode!)
        await _fetchWeatherDataAndUpdateState(locationInfo);
      },
    );
  }

  /// Interne Hilfsmethode: Holt Wetterdaten für einen gegebenen Ort und aktualisiert den State.
  Future<void> _fetchWeatherDataAndUpdateState(LocationInfo locationInfo) async {
    _log.fine('Notifier: Rufe Wetterdaten ab für: ${locationInfo.displayName}');
    // Zustand bleibt erstmal 'loading' (oder wird es, falls nicht schon)
    // Optional könnte man hier nochmal state = state.copyWith(status: WeatherStatus.loading); setzen
    // falls dieser Aufruf auch von anderer Stelle (z.B. Refresh) kommen könnte.

    final weatherResult = await _weatherRepository.getWeatherForLocation(locationInfo);

    // weatherResult ist ein Either<Failure, weatherData>
    weatherResult.fold(
      // Fehlerfall
      (failure) {
        _log.severe('Notifier: Fehler beim Abrufen der Wetterdaten für ${locationInfo.displayName}: $failure');
        // Setze Zustand auf 'failure', behalte aber den zuletzt erfolgreichen Ort (falls vorhanden).
        // Wenn wir keinen Ort behalten wollen, hier `clearSelectedLocation: true` setzen.
        state = state.copyWith(
          status: WeatherStatus.failure,
          error: failure,
          // Die alten Wetterdaten könnten wir löschen oder behalten, Geschmackssache.
          // weatherData: WeatherData.empty,
        );
      },
      // Erfolgsfall
      (data) { // 'data' ist jetzt vom Typ WeatherData
        _log.info('Notifier: Wetterdaten erfolgreich erhalten für ${locationInfo.displayName}');
        // Setze Zustand auf 'success', speichere die Daten und den Ort, lösche Fehler.
        state = state.copyWith(
          status: WeatherStatus.success,
          weatherData: data, // Hier wird das WeatherData-Objekt gespeichert
          selectedLocation: locationInfo,
          clearError: true, // Fehler löschen bei Erfolg
        );
      },
    );
  }

  /// Aktualisiert die Wetterdaten für den aktuell ausgewählten Ort (angepasst für Teil 4).
  Future<void> refreshWeatherData() async {
    _log.info('Notifier: refreshWeatherData aufgerufen');
      // Prüfe, ob überhaupt ein Ort ausgewählt ist
    final currentLocation = state.selectedLocation;
    if (currentLocation == null) {
      _log.warning('Notifier: Refresh aufgerufen, aber kein Ort ausgewählt. Lade GPS als Fallback.');
      await fetchWeatherForCurrentLocation();
      return;
    }
     if (state.status == WeatherStatus.loading) return;

     // Ladezustand setzen (aber alte Daten behalten)
     state = state.copyWith(status: WeatherStatus.loading, clearError: true);
     // Nutze den gespeicherten Ort im State für den Refresh!
    await _fetchWeatherDataAndUpdateState(currentLocation);
  }

  /// Öffnet die App-Einstellungen (nützlich bei permanent verweigerten Berechtigungen).
  /// Greift auf den LocationService zu (muss dafür ggf. injiziert werden oder über Repo gehen).
  Future<bool> openAppSettings() async {
    _log.info('Notifier: Versuche App-Einstellungen zu öffnen.');
    // Direkter Zugriff auf LocationService ist sauberer, wenn er injiziert wird.
    // Alternative: Methode im Repository hinzufügen, die es durchreicht.
    // Einfachste Lösung für jetzt (wenn Service nur hier gebraucht wird):
    try {
        // Annahme: Wir haben Zugriff auf den LocationService (z.B. durch Injizieren im Konstruktor)
        // return await _locationService.openAppSettings();
        // Da wir ihn nicht injiziert haben, machen wir es über das Repo (Best Practice wäre,
        // wenn das Repo nur Daten liefert und nicht UI-Aktionen auslöst. Aber pragmatisch ok für jetzt).
        // --> Füge openAppSettings zum LocationService hinzu (haben wir schon)
        // --> Füge eine Methode im Repository hinzu:
        // In WeatherRepository: Future<bool> triggerOpenAppSettings();
        // In WeatherRepositoryImpl: Future<bool> triggerOpenAppSettings() => _locationService.openAppSettings();
        // Dann hier: return await _weatherRepository.triggerOpenAppSettings();

        // **Workaround für jetzt ohne Repo-Änderung (nicht ideal):**
        // Provider direkt lesen (geht nur, wenn Notifier mit Ref erstellt wird)
        // Geht hier nicht standardmäßig.
        // --> Einfachste Lösung für den Blog: Im UI-Code den Service-Provider direkt nutzen!
        _log.warning("openAppSettings sollte idealerweise vom UI-Code aufgerufen werden.");
        return false; // Platzhalter
    } catch (e) {
        _log.severe("Fehler beim Öffnen der App-Einstellungen: $e");
        return false;
    }
  }
   /// Öffnet die Standort-Einstellungen (nützlich bei deaktivierten Diensten).
  Future<bool> openLocationSettings() async {
      _log.info('Notifier: Versuche Standort-Einstellungen zu öffnen.');
       // Gleiches Problem wie bei openAppSettings
       _log.warning("openLocationSettings sollte idealerweise vom UI-Code aufgerufen werden.");
       return false; // Platzhalter
  }
}