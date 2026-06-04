import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key, required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
    ];
    final sections = <PieChartSectionData>[];
    int i = 0;
    for (final entry in data.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: entry.value.toStringAsFixed(1),
          color: colors[i % colors.length],
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    }
    return PieChart(PieChartData(sections: sections));
  }
}