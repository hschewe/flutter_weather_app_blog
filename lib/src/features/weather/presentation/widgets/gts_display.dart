import 'package:flutter/material.dart';

class GtsDisplay extends StatelessWidget {
  final double gtsValue;

  const GtsDisplay({required this.gtsValue, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasValidGts = !gtsValue.isNaN; // Prüfen, ob GTS-Wert gültig ist

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Füllt die Breite der Card
          children: [
            Text(
              'Grünlandtemperatursumme (GTS)',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline, // Für schöne Textausrichtung
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(Icons.thermostat_auto, size: 32, color: colorScheme.primary), // Thermostat-Icon
                const SizedBox(width: 10),
                Text(
                  hasValidGts ? gtsValue.toStringAsFixed(1) : '--',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasValidGts ? colorScheme.primary : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text( // Einheit etwas kleiner
                  '°Cd',
                   style: textTheme.titleSmall?.copyWith(
                    color: hasValidGts ? colorScheme.primary : Colors.grey,
                  ),
                )
              ],
            ),
             const SizedBox(height: 6),
             Text(
              hasValidGts
                ? 'Summe der positiven Tagesmitteltemperaturen seit 1. Januar (mit Monatsfaktoren).'
                : '(Berechnung fehlgeschlagen oder Daten unvollständig)',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}