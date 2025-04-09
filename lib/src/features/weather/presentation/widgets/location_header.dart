// lib/src/features/weather/presentation/widgets/location_header.dart
import 'package:flutter/material.dart';

/// Zeigt den Namen des aktuell ausgewählten Ortes an.
class LocationHeader extends StatelessWidget {
  final String? locationName;
  final bool isLoading; // Zeigt an, ob der Ort noch geladen wird

  const LocationHeader({
    this.locationName,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget content;
    if (isLoading) {
      content = const Row(
        key: ValueKey('loading_location'), // Wichtig für AnimatedSwitcher
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Lade Ort...', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      );
    } else {
      content = Text(
        locationName ?? 'Unbekannter Ort', // Fallback
        key: ValueKey(locationName ?? 'unknown'), // Wichtig für AnimatedSwitcher
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis, // Bei langen Namen abschneiden
      );
    }

    // Animierter Übergang, wenn sich der Inhalt ändert
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: content,
    );
  }
}