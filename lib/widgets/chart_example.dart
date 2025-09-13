import 'package:flutter/material.dart';
import 'chart_widget.dart';

/// Example usage of the ChartWidget
class ChartExample extends StatelessWidget {
  const ChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chart Examples')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Line Chart Example
            ChartWidget(
              title: 'Tuxum ishlab chiqarish trendi',
              data: ChartData.createSampleData(
                count: 7,
                xPrefix: 'Kun',
                maxValue: 50,
              ),
              xField: 'day',
              yField: 'eggs',
              chartType: ChartType.line,
              color: Colors.blue,
              height: 250,
            ),

            const SizedBox(height: 16),

            // Bar Chart Example
            ChartWidget(
              title: 'Oylik daromad',
              data: ChartData.createSampleData(
                count: 6,
                xPrefix: 'Oy',
                maxValue: 100000,
              ),
              xField: 'month',
              yField: 'amount',
              chartType: ChartType.bar,
              color: Colors.green,
              height: 250,
            ),

            const SizedBox(height: 16),

            // Pie Chart Example
            ChartWidget(
              title: 'Mijozlar qarzi taqsimoti',
              data: [
                ChartData.sample(x: 'Qarzdorlar', y: 30, color: Colors.orange),
                ChartData.sample(x: 'To\'langan', y: 70, color: Colors.green),
              ],
              xField: 'status',
              yField: 'percentage',
              chartType: ChartType.pie,
              height: 250,
            ),
          ],
        ),
      ),
    );
  }
}
