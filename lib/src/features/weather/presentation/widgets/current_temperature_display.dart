// lib/src/features/weather/presentation/widgets/current_temperature_display.dart
import 'package:flutter/material.dart';
import 'package:flutter_weather_app_blog/src/core/utils/date_formatter.dart';

/// Zeigt die aktuelle Temperatur und die letzte Aktualisierungszeit an.
class CurrentTemperatureDisplay extends StatelessWidget {
  final double temperature;
  final DateTime? lastUpdated; // Zeit kann fehlen

  const CurrentTemperatureDisplay({
    required this.temperature,
    this.lastUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Prüfen, ob die Temperatur ein gültiger Wert ist (nicht NaN)
    final bool hasValidTemp = !temperature.isNaN;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Die Temperatur, groß und fett
        Text(
          hasValidTemp ? '${temperature.toStringAsFixed(1)}°C' : '--°C',
          style: textTheme.displayMedium?.copyWith( // displayMedium ist etwas kleiner als Large
            fontWeight: FontWeight.bold,
            color: hasValidTemp ? colorScheme.primary : Colors.grey, // Grau wenn ungültig
          ),
        ),
        const SizedBox(height: 8),
        // Die Aktualisierungszeit, falls vorhanden und Temperatur gültig
        if (lastUpdated != null && hasValidTemp)
          Text(
            'Aktualisiert: ${DateFormatter.formatTime(lastUpdated!)} Uhr',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          )
        else if (hasValidTemp) // Fallback, wenn Zeit fehlt aber Temp da
          Text(
            'Aktualisiert: --:-- Uhr',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          )
        else // Platzhalter, wenn keine gültige Temp da ist
          const SizedBox(height: 16), // Damit Layout stabil bleibt
      ],
    );
  }
}