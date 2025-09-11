import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartWidget extends StatelessWidget {
  final String title;
  final List<ChartData> data;
  final String xField;
  final String yField;
  final ChartType chartType;
  final Color? color;

  const ChartWidget({
    Key? key,
    required this.title,
    required this.data,
    required this.xField,
    required this.yField,
    this.chartType = ChartType.line,
    this.color,
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
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
          tooltipBehavior: TooltipBehavior(enable: true),
        );
      case ChartType.pie:
        return SfCircularChart(
          legend: const Legend(isVisible: true),
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
      default:
        return SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          primaryYAxis: NumericAxis(
            numberFormat: _getNumberFormat(),
          ),
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
          tooltipBehavior: TooltipBehavior(enable: true),
        );
    }
  }

  String? _getNumberFormat() {
    if (yField.contains('amount') || yField.contains('price')) {
      return '\$#,##0.00';
    } else if (yField.contains('percent') || yField.contains('percentage')) {
      return '0.00%';
    }
    return null;
  }
}

class ChartData {
  final dynamic x;
  final num y;
  final String? label;
  final Color? color;

  ChartData({
    required this.x,
    required this.y,
    this.label,
    this.color,
  });
}

enum ChartType {
  line,
  bar,
  pie,
}
