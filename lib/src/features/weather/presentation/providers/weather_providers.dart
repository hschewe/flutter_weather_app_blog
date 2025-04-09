// lib/src/features/weather/presentation/providers/weather_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_weather_app_blog/src/features/weather/application/weather_notifier.dart';
import 'package:flutter_weather_app_blog/src/features/weather/application/weather_state.dart';
import 'package:flutter_weather_app_blog/src/features/weather/data/repositories/weather_repository_impl.dart'; // Generiert

/// Stellt unseren WeatherNotifier und seinen WeatherState bereit.
/// Widgets können diesen Provider 'watchen' oder 'readen', um auf den Zustand
/// zuzugreifen oder Methoden im Notifier aufzurufen.
final weatherNotifierProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  // Holt die Instanz des WeatherRepository (über dessen Provider)
  // und übergibt sie an den Konstruktor des WeatherNotifier.
  final weatherRepository = ref.watch(weatherRepositoryProvider);
  // Optional: Wenn Notifier den LocationService braucht:
  // final locationService = ref.watch(locationServiceProvider);
  return WeatherNotifier(weatherRepository /*, locationService */);
});