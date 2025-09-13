import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class ChartWidget extends StatelessWidget {
  final String title;
  final List<ChartData> data;
  final String xField;
  final String yField;
  final ChartType chartType;
  final Color? color;
  final double? height;
  final bool showLegend;
  final bool showTooltip;

  const ChartWidget({
    Key? key,
    required this.title,
    required this.data,
    required this.xField,
    required this.yField,
    this.chartType = ChartType.line,
    this.color,
    this.height = 300,
    this.showLegend = true,
    this.showTooltip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(height: height, child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ma\'lumot yo\'q',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    switch (chartType) {
      case ChartType.bar:
        return SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          series: <CartesianSeries>[
            BarSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.x.toString(),
              yValueMapper: (ChartData data, _) => data.y,
              color: color,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
          tooltipBehavior: TooltipBehavior(enable: showTooltip),
        );
      case ChartType.pie:
        return SfCircularChart(
          legend: Legend(isVisible: showLegend),
          series: <CircularSeries>[
            PieSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.x.toString(),
              yValueMapper: (ChartData data, _) => data.y,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
              enableTooltip: true,
            ),
          ],
        );
      case ChartType.line:
        return SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          primaryYAxis: NumericAxis(numberFormat: _getNumberFormat()),
          series: <CartesianSeries>[
            LineSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.x.toString(),
              yValueMapper: (ChartData data, _) => data.y,
              color: color,
              markerSettings: const MarkerSettings(isVisible: true),
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
          tooltipBehavior: TooltipBehavior(enable: showTooltip),
        );
    }
  }

  NumberFormat? _getNumberFormat() {
    if (yField.contains('amount') || yField.contains('price')) {
      return NumberFormat.currency(symbol: '\$');
    } else if (yField.contains('percent') || yField.contains('percentage')) {
      return NumberFormat.percentPattern();
    }
    return null;
  }
}

class ChartData {
  final dynamic x;
  final num y;
  final String? label;
  final Color? color;

  ChartData({required this.x, required this.y, this.label, this.color});

  // Factory constructor for creating sample data
  factory ChartData.sample({
    required dynamic x,
    required num y,
    String? label,
    Color? color,
  }) {
    return ChartData(x: x, y: y, label: label, color: color);
  }

  // Create sample data for testing
  static List<ChartData> createSampleData({
    required int count,
    required String xPrefix,
    required num maxValue,
  }) {
    return List.generate(count, (index) {
      return ChartData.sample(
        x: '$xPrefix ${index + 1}',
        y: (index + 1) * (maxValue / count),
        label: '${xPrefix} ${index + 1}',
      );
    });
  }
}

enum ChartType { line, bar, pie }
