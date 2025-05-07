import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_weather_app_blog/src/core/utils/date_formatter.dart';
import 'package:flutter_weather_app_blog/src/features/weather/domain/entities/chart_point.dart';
import 'dart:math'; // Für min/max

class TemperatureChart extends StatelessWidget {
  final List<ChartPoint> chartData; // Die aufbereiteten Datenpunkte
  final double? minY; // Optional: Fester Minimalwert für Y-Achse
  final double? maxY; // Optional: Fester Maximalwert für Y-Achse

  const TemperatureChart({
    required this.chartData,
    this.minY,
    this.maxY,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (chartData.isEmpty) {
      return const Center(child: Text('Keine Verlaufsdaten verfügbar.'));
    }

    // Erstelle die FlSpot-Objekte für fl_chart
    final List<FlSpot> spots = chartData
        .where((point) => !point.temperature.isNaN) // Nur gültige Temperaturen
        .map((point) => FlSpot(
              point.time.millisecondsSinceEpoch.toDouble(), // X-Wert: Zeitstempel
              point.temperature,                            // Y-Wert: Temperatur
            ))
        .toList();

    if (spots.isEmpty) {
      return const Center(child: Text('Keine gültigen Daten zum Anzeigen im Diagramm.'));
    }

    // Dynamische Berechnung von Min/Max für die Y-Achse, falls nicht extern vorgegeben
    // Füge Puffer hinzu, damit die Linie nicht am Rand klebt.
    final double actualMinY = minY ?? spots.map((s) => s.y).reduce(min);
    final double actualMaxY = maxY ?? spots.map((s) => s.y).reduce(max);
    // Stelle sicher, dass minY nicht größer als maxY wird, falls alle Werte gleich sind
    final double yRange = (actualMaxY - actualMinY).abs();
    final double yPadding = yRange < 1 ? 2.0 : 2.0; // Mindestens 2 Grad Puffer, oder mehr falls nötig

    final double paddedMinY = (actualMinY - yPadding).floorToDouble();
    final double paddedMaxY = (actualMaxY + yPadding).ceilToDouble();
    // Sicherstellen, dass ein Mindestintervall für die Y-Achse besteht
    final double yAxisSpan = (paddedMaxY - paddedMinY).abs() < 4 ? 4.0 : (paddedMaxY - paddedMinY).abs();
    final double yInterval = (yAxisSpan / 5).clamp(1.0, 10.0).roundToDouble(); // Sinnvolles Intervall


    return LineChart(
      LineChartData(
        // Daten für die Linie
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, // Geglättete Linie
            color: colorScheme.primary, // Linienfarbe
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // Keine Punkte auf der Linie
            // Bereich unter der Linie füllen
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                 colors: [
                    colorScheme.primary.withAlpha((255 * 0.3).round()), // Korrigiert
                    colorScheme.primary.withAlpha(0),                   // Korrigiert
                 ],
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        // Achsenbeschriftungen (Titel)
        titlesData: FlTitlesData(
          // Untere Achse (X-Achse: Tage)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              // Intervall von 2 Tagen für die Beschriftung
              interval: const Duration(days: 2).inMilliseconds.toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                String text = '';
                final today = DateTime.now();
                final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
                final todayOnly = DateTime(today.year, today.month, today.day);

                if (dateOnly.isAtSameMomentAs(todayOnly)) {
                  text = 'Heute';
                } else if (dateOnly.isAtSameMomentAs(todayOnly.subtract(const Duration(days:1)))) {
                  text = 'Gestern';
                } else if (dateOnly.isAtSameMomentAs(todayOnly.add(const Duration(days:1)))) {
                  text = 'Morgen';
                } else {
                  // Zeige das Label nur, wenn es dem exakten `value` des Intervals entspricht
                  // oder wenn es der erste/letzte Punkt ist, um sicherzustellen, dass die Ränder Labels haben (optional)
                  // Hier vereinfacht: Zeige Label wenn es auf einen vollen Tag fällt,
                  // und `meta.formattedValue` entspricht dem, was wir erwarten würden.
                  // Dies hilft, überlappende Labels zu reduzieren.
                  if (value == meta.min || value == meta.max || meta.formattedValue == DateFormatter.formatChartAxisDay(dateTime) ) {
                     text = DateFormatter.formatChartAxisDay(dateTime);
                  } else {
                     // Alternativ, um weniger Labels zu haben:
                     // if (dateTime.hour == 0) { // Nur einmal pro Tag (um Mitternacht)
                     //   text = DateFormatter.formatChartAxisDay(dateTime);
                     // } else {
                        return Container(); // Keine Beschriftung
                     // }
                  }
                }
                return SideTitleWidget(
                  meta: meta, // KORRIGIERT
                  space: 8.0,
                  child: Text(text, style: textTheme.bodySmall),
                );
              },
            ),
          ),
          // Linke Achse (Y-Achse: Temperatur)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval, // Dynamisches Intervall
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta, // KORRIGIERT
                  space: 8.0,
                  child: Text('${value.toInt()}°', style: textTheme.bodySmall),
                );
              },
            ),
          ),
          // Obere und rechte Achsen ausblenden
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        // Gitternetz
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: yInterval, // Passend zum Y-Achsen-Intervall
          verticalInterval: const Duration(days: 1).inMilliseconds.toDouble(),
           getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withAlpha(50), strokeWidth: 1), // Korrigiert
           getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withAlpha(50), strokeWidth: 1),    // Korrigiert
        ),
        // Rahmen um das Diagramm
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withAlpha(75), width: 1), // Korrigiert
        ),
        // Tooltips bei Berührung
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (LineBarSpot touchedSpot) { // Korrigiert
               return Colors.blueGrey.withAlpha((255 * 0.8).round()); // Korrigiert
             },
             getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  if (flSpot.y.isNaN) return null;

                  final dateTime = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                  return LineTooltipItem(
                     '${DateFormatter.formatChartTooltip(dateTime)}\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                         text: '${flSpot.y.toStringAsFixed(1)}°C',
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ]
                  );
                }).whereType<LineTooltipItem>().toList();
             }
          ),
          handleBuiltInTouches: true,
        ),
        // Y-Achsen-Bereich
        minY: paddedMinY,
        maxY: paddedMaxY,
        // X-Achsen-Bereich wird durch die `spots` bestimmt (minX/maxX nicht explizit nötig, wenn alle Daten im Bereich liegen)
      ),
    );
  }
}