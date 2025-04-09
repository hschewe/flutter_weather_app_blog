// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_weather_app_blog/src/features/weather/presentation/screens/weather_screen.dart';

/// Das Haupt-Widget unserer Anwendung.
class WeatherApp extends ConsumerWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MaterialApp konfiguriert das grundlegende Aussehen und Verhalten der App.
    return MaterialApp(
      title: 'Meine Wetter App',
      theme: ThemeData( // Helles Theme
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue), // Alternative
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Aktiviert das neuere Material Design 3
        // Optional: AppBar-Theme anpassen
        // appBarTheme: const AppBarTheme(
        //   backgroundColor: Colors.blueAccent,
        //   foregroundColor: Colors.white,
        // ),
      ),
      darkTheme: ThemeData( // Dunkles Theme
         brightness: Brightness.dark,
         // colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
         primarySwatch: Colors.blue, // Kann auch für Dark Mode genutzt werden
         visualDensity: VisualDensity.adaptivePlatformDensity,
         useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Nutzt Hell/Dunkel basierend auf Systemeinstellung
      // Startbildschirm unserer App
      home: const WeatherScreen(),
      debugShowCheckedModeBanner: false, // Entfernt das "Debug"-Banner oben rechts
    );
  }
}