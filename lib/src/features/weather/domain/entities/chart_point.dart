import 'package:equatable/equatable.dart';

/// Repräsentiert einen einzelnen Datenpunkt für das Temperaturdiagramm.
class ChartPoint extends Equatable {
  final DateTime time;      // X-Achse: Zeitstempel
  final double temperature; // Y-Achse: Temperatur

  const ChartPoint({required this.time, required this.temperature});

  @override
  List<Object?> get props => [time, temperature];
}