import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key, required this.data});

  final Map<DateTime, double> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No consumption this week'));
    }
    final spots = <FlSpot>[];
    final sortedKeys = data.keys.toList()..sort();
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[sortedKeys[i]]!));
    }
    return BarChart(
      BarChartData(
        barGroups: spots.map((spot) {
          return BarChartGroupData(x: spot.x.toInt(), barRods: [
            BarChartRodData(toY: spot.y, color: Colors.teal, width: 20),
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedKeys.length) {
                  return const Text('');
                }
                return Text(
                  DateFormat('E').format(sortedKeys[index]),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
      ),
    );
  }
}