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

  /// Hauptmethode für Teil 3: Holt Koordinaten und dann Wetterdaten.
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
      // Fehlerfall (linke Seite)
      (failure) async {
        _log.warning('Notifier: Fehler beim Holen der GPS-Koordinaten: $failure');
        // Setze Zustand auf 'failure' mit dem Fehlerobjekt
        state = state.copyWith(status: WeatherStatus.failure, error: failure);
      },
      // Erfolgsfall (rechte Seite)
      (locationInfo) async {
        _log.info('Notifier: GPS-Koordinaten erfolgreich erhalten.');

        // Optional: Versuche, den Anzeigenamen zu verfeinern (Reverse Geocoding)
        // In Teil 3 ist das noch nicht implementiert, daher wird es den Standardnamen nicht ändern.
        final displayNameResult = await _weatherRepository.getLocationDisplayName(
          locationInfo.latitude, locationInfo.longitude,
        );

        // Nutze den verfeinerten Namen, wenn verfügbar, sonst den Standardnamen
        final finalLocationInfo = displayNameResult.fold(
           (failure) => locationInfo, // Bei Fehler alten Namen behalten
           (displayName) => locationInfo.copyWith(displayName: displayName)
        );

        // 2. Wenn Koordinaten da sind, hole die Wetterdaten dafür
        await _fetchWeatherDataAndUpdateState(finalLocationInfo);
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

    // weatherResult ist ein Either<Failure, CurrentWeatherData>
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
          // currentWeatherData: CurrentWeatherData.empty,
        );
      },
      // Erfolgsfall
      (weatherData) {
        _log.info('Notifier: Wetterdaten erfolgreich erhalten für ${locationInfo.displayName}');
        // Setze Zustand auf 'success', speichere die Daten und den Ort, lösche Fehler.
        state = state.copyWith(
          status: WeatherStatus.success,
          currentWeatherData: weatherData,
          selectedLocation: locationInfo,
          clearError: true, // Fehler löschen bei Erfolg
        );
      },
    );
  }

  /// Aktualisiert die Wetterdaten für den aktuell ausgewählten Ort (vereinfacht für Teil 3).
  Future<void> refreshWeatherData() async {
    _log.info('Notifier: refreshWeatherData aufgerufen');
    // In Teil 3 gibt es nur "Mein Standort", also rufen wir einfach dessen Funktion auf.
    // Später wird hier der `state.selectedLocation` verwendet.
     if (state.status == WeatherStatus.loading) return; // Nicht refreshen, wenn schon lädt
    await fetchWeatherForCurrentLocation();
  }

  // fetchWeatherForAddress kommt in Teil 4

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