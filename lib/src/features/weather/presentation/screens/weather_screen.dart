// lib/src/features/weather/presentation/screens/weather_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod importieren
import 'package:flutter_weather_app_blog/src/core/error/failure.dart';
import 'package:flutter_weather_app_blog/src/core/location/location_service.dart'; // Für den Provider
import 'package:flutter_weather_app_blog/src/core/utils/logger.dart';
import 'package:flutter_weather_app_blog/src/features/weather/application/weather_state.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/current_weather_data.dart';
import 'package:flutter_weather_app_blog/src/features/weather/presentation/providers/weather_providers.dart'; // Unser Notifier Provider
import 'package:flutter_weather_app_blog/src/features/weather/presentation/widgets/current_temperature_display.dart';
import 'package:flutter_weather_app_blog/src/features/weather/presentation/widgets/location_header.dart';

final _log = AppLogger.getLogger('WeatherScreen');

/// Hauptbildschirm der App. Verwendet ConsumerStatefulWidget, um auf Riverpod-Provider zu hören.
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {

  @override
  void initState() {
    super.initState();
    // Nach dem ersten Frame...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ...prüfe den initialen Zustand des Notifiers.
      final initialState = ref.read(weatherNotifierProvider);
      // Wenn er 'initial' ist (App gerade gestartet), lade Wetter für aktuellen Ort.
      if (initialState.status == WeatherStatus.initial) {
         _log.info('Screen: Initialer Ladevorgang wird ausgelöst.');
        // ref.read holt den Notifier, ohne auf Änderungen zu hören.
        // Wir rufen die Methode auf, um den Ladevorgang zu starten.
        ref.read(weatherNotifierProvider.notifier).fetchWeatherForCurrentLocation();
      }
    });
  }

  /// Zeigt eine kurze Nachricht am unteren Bildschirmrand an.
  void _showSnackbar(String message, {bool isError = false}) {
     // mounted prüft, ob das Widget noch im Baum ist (wichtig bei async Operationen)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).snackBarTheme.backgroundColor ?? Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _log.info('Snackbar angezeigt: "$message" (Error: $isError)');
  }

  /// Baut das Widget zur Fehleranzeige, mit optionalen Aktionen.
  Widget _buildErrorWidget(Failure failure) {
    String message = failure.message;
    String? actionLabel;
    VoidCallback? onActionPressed;
    IconData icon = Icons.error_outline;

    // Passe Meldung und Aktion je nach Fehlertyp an
    if (failure is PermissionFailure) {
      icon = Icons.location_off_outlined;
      if (failure.message.contains("permanent")) {
        actionLabel = "App-Einstellungen öffnen";
        onActionPressed = () async {
           _log.info('Screen: Öffne App-Einstellungen wegen permanenter Berechtigungsverweigerung.');
           // Hier greifen wir DIREKT auf den LocationService zu, um die Einstellungen zu öffnen.
           final success = await ref.read(locationServiceProvider).openAppSettings();
           if (!success) {
              _showSnackbar("Einstellungen konnten nicht geöffnet werden.", isError: true);
           }
        };
      } else { // Nur temporär verweigert
         actionLabel = "Berechtigung erneut anfordern";
         onActionPressed = () {
             _log.info('Screen: Versuche erneut, Standortberechtigung zu erhalten.');
             // Starte den Prozess erneut
             ref.read(weatherNotifierProvider.notifier).fetchWeatherForCurrentLocation();
         };
      }
    } else if (failure is LocationFailure && failure.message.contains("deaktiviert")) {
      icon = Icons.location_disabled_outlined;
      actionLabel = "Standort-Einstellungen öffnen";
      onActionPressed = () async {
         _log.info('Screen: Öffne Standort-Einstellungen, da Dienst deaktiviert ist.');
         final success = await ref.read(locationServiceProvider).openLocationSettings();
          if (!success) {
              _showSnackbar("Einstellungen konnten nicht geöffnet werden.", isError: true);
           }
      };
    } else if (failure is NetworkFailure) {
        icon = Icons.wifi_off_outlined;
        actionLabel = "Erneut versuchen";
        onActionPressed = () {
           _log.info('Screen: Erneuter Versuch nach Netzwerkfehler.');
           // Löse den Refresh aus
           ref.read(weatherNotifierProvider.notifier).refreshWeatherData();
        };
    } // Andere Fehler (ServerFailure, UnknownFailure) haben erstmal keine Standardaktion

    return Center(
      key: const ValueKey('error_widget'), // Key für AnimatedSwitcher
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.error, size: 60),
            const SizedBox(height: 16),
            Text(
              'Ups, etwas ist schiefgelaufen!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
               textAlign: TextAlign.center,
            ),
             const SizedBox(height: 8),
            Text(
               message, // Die spezifische Fehlermeldung
               textAlign: TextAlign.center,
               style: Theme.of(context).textTheme.bodyLarge,
             ),
            if (actionLabel != null && onActionPressed != null) ...[
               const SizedBox(height: 24),
               ElevatedButton.icon(
                  icon: const Icon(Icons.refresh), // Oder passenderes Icon
                  label: Text(actionLabel),
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.errorContainer,
                     foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  ),
               )
            ]
          ],
        ),
      ),
    );
  }

  /// Baut den Hauptinhalt basierend auf dem WeatherState.
  Widget _buildContent(WeatherState state) {
    // Verwende den Status als Key für den AnimatedSwitcher,
    // damit er Änderungen erkennt.
    final key = ValueKey(state.status);

    switch (state.status) {
      case WeatherStatus.initial:
        // Zeige Ladeindikator, solange noch gar nichts geladen wurde
        return Center(key: key, child: const CircularProgressIndicator());

      case WeatherStatus.loading:
        // Wenn schon Daten da sind (beim Refresh), zeige sie im Hintergrund weiter an.
        if (state.selectedLocation != null && state.currentWeatherData != CurrentWeatherData.empty) {
          return Stack(
             key: key,
             alignment: Alignment.center,
             children: [
               // Alte Daten anzeigen
               Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     LocationHeader(locationName: state.selectedLocation!.displayName),
                     const SizedBox(height: 20),
                     CurrentTemperatureDisplay(
                       temperature: state.currentWeatherData.temperature,
                       lastUpdated: state.currentWeatherData.lastUpdatedTime,
                     ),
                   ],
                 ),
               // Ladeindikator darüber legen
               Container(color: Colors.black.withOpacity(0.1)), // Leichtes Overlay
               const CircularProgressIndicator(),
             ],
           );
        } else {
          // Wenn noch keine Daten da sind, zeige nur den Ladeindikator
          return Center(key: key, child: const CircularProgressIndicator());
        }

      case WeatherStatus.success:
        // Zeige die erfolgreichen Daten an
        if (state.selectedLocation != null) {
          return Center(
            child: Column( // Zentriert die Elemente vertikal
              key: key,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocationHeader(locationName: state.selectedLocation!.displayName),
                const SizedBox(height: 20), // Abstand
                CurrentTemperatureDisplay(
                  temperature: state.currentWeatherData.temperature,
                  lastUpdated: state.currentWeatherData.lastUpdatedTime,
                ),
              ],
            )
          );
        } else {
            // Sollte nicht passieren, aber sicher ist sicher
            _log.severe('Screen: Erfolgsstatus, aber selectedLocation ist null.');
            return Center(key: key, child: const Text('Fehler: Kein Ort ausgewählt.'));
        }

      case WeatherStatus.failure:
          // Zeige das detaillierte Fehler-Widget
          return _buildErrorWidget(state.error ?? const UnknownFailure('Unbekannter Fehlerzustand.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch: Hört auf Änderungen im weatherNotifierProvider.
    // Wenn sich der State ändert, wird dieses build-Widget neu ausgeführt!
    final weatherState = ref.watch(weatherNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Wetter App'),
        actions: [
           // Refresh-Button
           IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Aktualisieren',
              // Deaktiviert, wenn gerade geladen wird
              onPressed: weatherState.status == WeatherStatus.loading
                  ? null
                  : () {
                       _log.info('Screen: Refresh-Button gedrückt.');
                       // ref.read holt den Notifier, ohne auf Änderungen zu hören.
                       // Rufe die refresh-Methode im Notifier auf.
                       ref.read(weatherNotifierProvider.notifier).refreshWeatherData();
                  },
            ),
        ],
      ),
      // RefreshIndicator: Ermöglicht "Pull-to-Refresh"
      body: RefreshIndicator(
        onRefresh: () async {
           _log.info('Screen: Pull-to-Refresh ausgelöst.');
           // Rufe die refresh-Methode im Notifier auf.
           // Das 'await' wartet, bis der Ladevorgang (im Notifier) abgeschlossen ist.
           await ref.read(weatherNotifierProvider.notifier).refreshWeatherData();
        },
        // AnimatedSwitcher sorgt für weiche Übergänge zwischen Lade-/Erfolgs-/Fehlerzuständen
        child: AnimatedSwitcher(
           duration: const Duration(milliseconds: 400), // Dauer der Animation
           child: _buildContent(weatherState), // Ruft die Methode auf, die den Inhalt baut
        ),
      ),
    );
  }
}