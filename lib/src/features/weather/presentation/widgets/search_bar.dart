// lib/src/features/weather/presentation/widgets/search_bar.dart
import 'package:flutter/material.dart';

/// Ein einfaches Widget für eine Suchleiste mit Senden-Button.
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch; // Callback, wenn gesucht wird
  final bool isLoading; // Um Eingabe/Button ggf. zu deaktivieren
  final String hintText;

  const SearchBarWidget({
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
    this.hintText = 'Ort oder Adresse suchen...',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      // Deaktivieren, wenn die App gerade lädt
      enabled: !isLoading,
      decoration: InputDecoration(
        hintText: hintText,
        // Lupe als Icon am Anfang
        prefixIcon: const Icon(Icons.search),
        // Rahmen der Suchleiste
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0), // Abgerundete Ecken
          borderSide: BorderSide( // Leichter Rand
            color: Theme.of(context).colorScheme.outline.withAlpha(127),
          ),
        ),
        // Fokussierter Rahmen
         focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, // Akzentfarbe bei Fokus
            width: 1.5,
          ),
        ),
        // Hintergrund leicht einfärben
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withAlpha(127),
        // Innenabstand
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        // Senden-Button oder Ladeindikator am Ende
        suffixIcon: isLoading
            ? const Padding(
                 padding: EdgeInsets.all(12.0),
                 child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
               )
            : IconButton(
                icon: const Icon(Icons.send),
                tooltip: 'Suchen',
                // Nur aktivieren, wenn nicht geladen wird
                onPressed: isLoading ? null : () => onSearch(controller.text),
              ),
      ),
      // Aktion auf der Tastatur (z.B. "Suchen"-Button) löst auch Suche aus
      textInputAction: TextInputAction.search,
      onSubmitted: isLoading ? null : onSearch, // Suche auch bei Enter auslösen
    );
  }
}