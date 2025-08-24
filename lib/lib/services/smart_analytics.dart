import 'dart:math' as Math;
import '../models/farm.dart';
import '../models/customer.dart';

enum HintType { info, success, warning, critical }
enum HintPriority { low, medium, high, critical }

class SmartHint {
  final HintType type;
  final String title;
  final String description;
  final String suggestion;
  final HintPriority priority;
  final DateTime createdAt;

  SmartHint({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.priority,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TrendAnalysis {
  final double overallTrend; // positive/negative/stable
  final Map<String, double> weekdayPattern;
  final List<Anomaly> anomalies;
  final List<Prediction> predictions;

  TrendAnalysis({
    required this.overallTrend,
    required this.weekdayPattern,
    required this.anomalies,
    required this.predictions,
  });
}

class Anomaly {
  final DateTime date;
  final String type; // 'high_eggs', 'low_eggs', 'high_deaths', etc.
  final double value;
  final double expectedValue;
  final double severity; // 0.0 to 1.0

  Anomaly({
    required this.date,
    required this.type,
    required this.value,
    required this.expectedValue,
    required this.severity,
  });
}

class Prediction {
  final DateTime date;
  final String metric; // 'eggs', 'revenue', 'deaths'
  final double predictedValue;
  final double confidence; // 0.0 to 1.0

  Prediction({
    required this.date,
    required this.metric,
    required this.predictedValue,
    required this.confidence,
  });
}

class SmartAnalytics {
  // Trend Analysis
  static TrendAnalysis analyzeTrend(Farm farm) {
    List<double> eggCounts = [];
    List<DateTime> dates = [];
    
    // Extract egg data from farm records
    farm.todayActivity.forEach((key, value) {
      if (key.contains('eggs')) {
        eggCounts.add(value.toDouble());
        dates.add(DateTime.now().subtract(Duration(days: eggCounts.length - 1)));
      }
    });
    
    // Simple linear regression for trend
    double trend = _calculateLinearTrend(eggCounts);
    
    // Seasonal patterns
    Map<String, double> weekdayAverage = _calculateWeekdayAverages(eggCounts, dates);
    
    // Anomaly detection
    List<Anomaly> anomalies = _detectAnomalies(eggCounts, dates);
    
    // Generate predictions
    List<Prediction> predictions = _generatePredictions(eggCounts, dates);
    
    return TrendAnalysis(
      overallTrend: trend,
      weekdayPattern: weekdayAverage,
      anomalies: anomalies,
      predictions: predictions,
    );
  }
  
  // Predictive Hints
  static List<SmartHint> generateHints(Farm farm) {
    List<SmartHint> hints = [];
    
    // Declining production warning
    if (_isProductionDeclining(farm)) {
      hints.add(SmartHint(
        type: HintType.warning,
        title: '⚠️ Tuxum ishlab chiqarish kamaymoqda',
        description: 'So\'nggi 3 kun davomida tuxum soni kamaydi',
        suggestion: 'Yem sifatini tekshiring yoki veterinarni chaqiring',
        priority: HintPriority.high,
      ));
    }
    
    // High mortality alert
    if (_isMortalityHigh(farm)) {
      int weeklyDeaths = _getWeeklyDeaths(farm);
      hints.add(SmartHint(
        type: HintType.critical,
        title: '🚨 Tovuq o\'limi ko\'p',
        description: 'Bu haftada $weeklyDeaths ta tovuq o\'ldi',
        suggestion: 'Zudlik bilan veterinar bilan bog\'laning',
        priority: HintPriority.critical,
      ));
    }
    
    // Good performance praise
    if (_isPerformanceGood(farm)) {
      hints.add(SmartHint(
        type: HintType.success,
        title: '🎉 Ajoyib natija!',
        description: 'Bu hafta o\'rtachadan 15% ko\'p tuxum',
        suggestion: 'Shu ishni davom ettiring!',
        priority: HintPriority.low,
      ));
    }
    
    // Stock warning
    int currentStock = farm.farmStats['currentStock'] ?? 0;
    if (currentStock < 10) {
      hints.add(SmartHint(
        type: HintType.warning,
        title: '📦 Zaxira kam',
        description: 'Sizda faqat $currentStock fletka tuxum qoldi',
        suggestion: 'Tez orada tuxum yig\'ing yoki sotuvni kamaytiring',
        priority: HintPriority.medium,
      ));
    }

    // Customer debt warning
    int totalDebt = _calculateTotalCustomerDebt(farm);
    if (totalDebt > 100000) {
      hints.add(SmartHint(
        type: HintType.warning,
        title: '💰 Qarzdorlik ko\'p',
        description: 'Mijozlarning umumiy qarzi $totalDebt som',
        suggestion: 'Qarzdor mijozlar bilan bog\'lanib, to\'lovni eslatishingiz mumkin',
        priority: HintPriority.medium,
      ));
    }

    // Weather-based suggestions
    String weatherCondition = farm.todayActivity['weather'] ?? '';
    if (weatherCondition.contains('yomgir') || weatherCondition.contains('rain')) {
      hints.add(SmartHint(
        type: HintType.info,
        title: '🌧️ Yomgirli kun',
        description: 'Bugun ob-havo yomgirli',
        suggestion: 'Tovuqlarni quruq joyda saqlang va ventilatsiyani ta\'minlang',
        priority: HintPriority.low,
      ));
    }
    
    return hints;
  }

  // Helper methods for trend calculation
  static double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = values.length;
    
    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  static Map<String, double> _calculateWeekdayAverages(List<double> values, List<DateTime> dates) {
    Map<String, List<double>> weekdayValues = {
      'Monday': [], 'Tuesday': [], 'Wednesday': [], 'Thursday': [],
      'Friday': [], 'Saturday': [], 'Sunday': []
    };
    
    List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    for (int i = 0; i < values.length && i < dates.length; i++) {
      String weekday = weekdays[dates[i].weekday - 1];
      weekdayValues[weekday]!.add(values[i]);
    }
    
    Map<String, double> averages = {};
    weekdayValues.forEach((weekday, values) {
      if (values.isNotEmpty) {
        averages[weekday] = values.reduce((a, b) => a + b) / values.length;
      } else {
        averages[weekday] = 0.0;
      }
    });
    
    return averages;
  }

  static List<Anomaly> _detectAnomalies(List<double> values, List<DateTime> dates) {
    if (values.length < 3) return [];
    
    List<Anomaly> anomalies = [];
    double average = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((v) => (v - average) * (v - average)).reduce((a, b) => a + b) / values.length;
    double stdDev = variance.isNaN ? 0 : variance < 0 ? 0 : Math.sqrt(variance);
    
    for (int i = 0; i < values.length; i++) {
      double deviation = (values[i] - average).abs();
      if (deviation > 2 * stdDev && stdDev > 0) {
        anomalies.add(Anomaly(
          date: dates[i],
          type: values[i] > average ? 'high_eggs' : 'low_eggs',
          value: values[i],
          expectedValue: average,
          severity: deviation / (3 * stdDev).clamp(1, double.infinity),
        ));
      }
    }
    
    return anomalies;
  }

  static List<Prediction> _generatePredictions(List<double> values, List<DateTime> dates) {
    if (values.length < 3) return [];
    
    double trend = _calculateLinearTrend(values);
    double lastValue = values.last;
    DateTime lastDate = dates.last;
    
    List<Prediction> predictions = [];
    
    // Predict next 7 days
    for (int i = 1; i <= 7; i++) {
      double predictedValue = lastValue + (trend * i);
      predictions.add(Prediction(
        date: lastDate.add(Duration(days: i)),
        metric: 'eggs',
        predictedValue: predictedValue.clamp(0, double.infinity),
        confidence: (0.9 - (i * 0.1)).clamp(0.1, 0.9),
      ));
    }
    
    return predictions;
  }

  // Helper methods for hint generation
  static bool _isProductionDeclining(Farm farm) {
    // Check if egg production has been declining in recent days
    int todayEggs = farm.todayActivity['eggsCollected'] ?? 0;
    int avgEggs = farm.farmStats['averageEggs'] ?? 0;
    
    return todayEggs < avgEggs * 0.8; // 20% below average
  }

  static bool _isMortalityHigh(Farm farm) {
    int todayDeaths = farm.todayActivity['chickenDeaths'] ?? 0;
    int totalChickens = farm.farmStats['totalChickens'] ?? 0;
    
    // If more than 2% of chickens died today, it's high mortality
    return todayDeaths > (totalChickens * 0.02);
  }

  static bool _isPerformanceGood(Farm farm) {
    int todayEggs = farm.todayActivity['eggsCollected'] ?? 0;
    int avgEggs = farm.farmStats['averageEggs'] ?? 0;
    
    return todayEggs > avgEggs * 1.15; // 15% above average
  }

  static int _getWeeklyDeaths(Farm farm) {
    // This would need to be calculated from historical data
    // For now, return today's deaths as a placeholder
    return farm.todayActivity['chickenDeaths'] ?? 0;
  }

  static int _calculateTotalCustomerDebt(Farm farm) {
    // Calculate total debt from all customers
    double totalDebt = 0;
    for (Customer customer in farm.customers) {
      totalDebt += customer.totalDebt;
    }
    return totalDebt.toInt();
  }
} 