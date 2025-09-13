import 'dart:math' as math;

import '../models/farm.dart';
import '../models/customer.dart';
import '../models/egg.dart';
import '../models/chicken.dart';
import '../services/inventory_service.dart';

class AnalyticsService {
  
  // Foyda tahlili
  static Future<Map<String, dynamic>> getProfitAnalysis(
    Farm farm, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Default to last 30 days if no dates provided
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Tuxum sotuvidan daromad
      double eggRevenue = 0.0;
      double totalEggSales = 0.0;
      int totalEggsSold = 0;

      if (farm.egg != null) {
        final eggSales = farm.egg!.sales.where((sale) =>
            sale.date.isAfter(startDate!) && 
            sale.date.isBefore(endDate!.add(const Duration(days: 1))));
        
        for (final sale in eggSales) {
          final revenue = sale.trayCount * sale.pricePerTray;
          eggRevenue += revenue;
          totalEggSales += revenue;
          totalEggsSold += sale.trayCount;
        }
      }

      // Mijozlardan to'lovlar
      double customerPayments = 0.0;
      double totalDebt = 0.0;
      int totalCustomers = farm.customers.length;

      for (final customer in farm.customers) {
        // Calculate paid amounts in date range
        final paidOrders = customer.orders.where((order) => 
            order.isPaid && 
            order.paidAt != null &&
            order.paidAt!.isAfter(startDate!) &&
            order.paidAt!.isBefore(endDate!.add(const Duration(days: 1))));
        
        for (final order in paidOrders) {
          customerPayments += order.totalAmount;
        }

        // Total outstanding debt
        totalDebt += customer.totalDebt;
      }

      // Xarajatlar tahlili
      final inventoryStats = await InventoryService.getInventoryStats(farm.id);
      final feedCost = await _calculateFeedCost(farm.id, startDate, endDate);
      final medicineCost = await _calculateMedicineCost(farm.id, startDate, endDate);
      
      double totalExpenses = feedCost + medicineCost;
      
      // Tovuq o'limi zarar
      double mortalityLoss = 0.0;
      if (farm.chicken != null) {
        final deaths = farm.chicken!.deaths.where((death) =>
            death.date.isAfter(startDate!) && 
            death.date.isBefore(endDate!.add(const Duration(days: 1))));
        
        for (final death in deaths) {
          // Assuming average chicken value
          mortalityLoss += death.count * 50000; // 50,000 so'm per chicken
        }
      }

      totalExpenses += mortalityLoss;

      // Sof foyda
      double totalRevenue = eggRevenue + customerPayments;
      double netProfit = totalRevenue - totalExpenses;
      double profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

      // ROI (Return on Investment)
      double totalInvestment = (inventoryStats['totalValue'] ?? 0.0) + 
          (farm.chicken?.totalCount ?? 0) * 50000;
      double roi = totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0;

      return {
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'days': endDate.difference(startDate).inDays + 1,
        },
        'revenue': {
          'total': totalRevenue,
          'eggSales': eggRevenue,
          'customerPayments': customerPayments,
          'averageDaily': totalRevenue / (endDate.difference(startDate).inDays + 1),
        },
        'expenses': {
          'total': totalExpenses,
          'feed': feedCost,
          'medicine': medicineCost,
          'mortalityLoss': mortalityLoss,
        },
        'profit': {
          'net': netProfit,
          'margin': profitMargin,
          'roi': roi,
          'dailyAverage': netProfit / (endDate.difference(startDate).inDays + 1),
        },
        'eggs': {
          'totalSold': totalEggsSold,
          'revenue': eggRevenue,
          'averagePrice': totalEggsSold > 0 ? eggRevenue / totalEggsSold : 0,
        },
        'customers': {
          'total': totalCustomers,
          'totalDebt': totalDebt,
          'paymentsReceived': customerPayments,
        },
        'performance': {
          'profitability': netProfit > 0 ? 'Foydali' : 'Zarar',
          'efficiency': _calculateEfficiency(farm),
          'growth': await _calculateGrowthRate(farm, startDate, endDate),
        }
      };
    } catch (e) {
      print('Error calculating profit analysis: $e');
      return {};
    }
  }

  // Mijozlar tahlili
  static Map<String, dynamic> getCustomerAnalysis(Farm farm) {
    try {
      if (farm.customers.isEmpty) {
        return {
          'totalCustomers': 0,
          'activeCustomers': 0,
          'debtorCustomers': 0,
          'totalDebt': 0.0,
          'averageDebt': 0.0,
          'topCustomers': [],
          'recentCustomers': [],
        };
      }

      final customers = farm.customers;
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Aktiv mijozlar (oxirgi 30 kunda buyurtma berganlar)
      final activeCustomers = customers.where((customer) =>
          customer.orders.any((order) => 
              order.deliveryDate.isAfter(thirtyDaysAgo))).toList();

      // Qarzor mijozlar
      final debtorCustomers = customers.where((customer) => 
          customer.totalDebt > 0).toList();

      // Umumiy qarz
      final totalDebt = customers.fold<double>(
          0.0, (sum, customer) => sum + customer.totalDebt);

      // O'rtacha qarz
      final averageDebt = debtorCustomers.isNotEmpty 
          ? totalDebt / debtorCustomers.length 
          : 0.0;

      // Eng katta mijozlar (qarz bo'yicha)
      final sortedByDebt = List<Customer>.from(customers);
      sortedByDebt.sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
      final topCustomers = sortedByDebt.take(5).map((customer) => {
        'name': customer.name,
        'phone': customer.phone,
        'debt': customer.totalDebt,
        'orders': customer.orders.length,
        'lastOrder': customer.orders.isNotEmpty 
            ? customer.orders.last.deliveryDate.toIso8601String()
            : null,
      }).toList();

      // Eng so'nggi qo'shilgan mijozlar
      final sortedByDate = List<Customer>.from(customers);
      sortedByDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentCustomers = sortedByDate.take(5).map((customer) => {
        'name': customer.name,
        'phone': customer.phone,
        'debt': customer.totalDebt,
        'joinDate': customer.createdAt.toIso8601String(),
        'orders': customer.orders.length,
      }).toList();

      // Mijozlar kategoriyasi bo'yicha statistika
      final customerCategories = {
        'vip': customers.where((c) => c.totalDebt > 1000000).length, // 1M+
        'regular': customers.where((c) => c.totalDebt > 100000 && c.totalDebt <= 1000000).length,
        'occasional': customers.where((c) => c.totalDebt > 0 && c.totalDebt <= 100000).length,
        'paid': customers.where((c) => c.totalDebt == 0).length,
      };

      // Oylik trend
      final monthlyStats = _getMonthlyCustomerStats(customers);

      return {
        'totalCustomers': customers.length,
        'activeCustomers': activeCustomers.length,
        'debtorCustomers': debtorCustomers.length,
        'totalDebt': totalDebt,
        'averageDebt': averageDebt,
        'topCustomers': topCustomers,
        'recentCustomers': recentCustomers,
        'categories': customerCategories,
        'monthlyStats': monthlyStats,
        'insights': _generateCustomerInsights(customers, activeCustomers, debtorCustomers),
      };
    } catch (e) {
      print('Error analyzing customers: $e');
      return {};
    }
  }

  // Tuxum ishlab chiqarish tahlili
  static Map<String, dynamic> getEggProductionAnalysis(Farm farm) {
    try {
      if (farm.egg == null) return {};

      final egg = farm.egg!;
      final now = DateTime.now();
      
      // So'nggi 30 kun
      final last30Days = egg.productionLastNDays(30);
      final dailyAverage = egg.productionDailyAverageLastNDays(30);
      
      // So'nggi 7 kun
      final last7Days = egg.productionLastNDays(7);
      final weeklyAverage = egg.productionDailyAverageLastNDays(7);

      // Bu oy
      final thisMonth = egg.productionLastNDays(now.day);
      
      // Eng yaxshi kun
      final bestDay = _getBestProductionDay(egg);
      
      // Trend tahlili
      final trend = _calculateProductionTrend(egg);

      return {
        'current': {
          'today': egg.todayProduction,
          'thisWeek': last7Days,
          'thisMonth': thisMonth,
          'last30Days': last30Days,
        },
        'averages': {
          'daily': dailyAverage,
          'weekly': weeklyAverage,
        },
        'best': {
          'day': bestDay,
          'weeklyBest': _getBestWeek(egg),
        },
        'trend': trend,
        'efficiency': {
          'productionRate': _calculateProductionRate(farm),
          'consistency': _calculateConsistency(egg),
        },
        'projections': {
          'nextWeek': _projectNextWeek(egg),
          'nextMonth': _projectNextMonth(egg),
        }
      };
    } catch (e) {
      print('Error analyzing egg production: $e');
      return {};
    }
  }

  // Private helper methods
  static Future<double> _calculateFeedCost(String farmId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await InventoryService.getFarmTransactions(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );

      double total = 0.0;
      for (final t in transactions.where((t) => t.transactionType == 'out' && t.referenceType == 'feed_usage')) {
        total += t.totalAmount ?? 0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<double> _calculateMedicineCost(String farmId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await InventoryService.getFarmTransactions(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );

      double total = 0.0;
      for (final t in transactions.where((t) => t.transactionType == 'out' && t.referenceType == 'medicine_usage')) {
        total += t.totalAmount ?? 0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  static double _calculateEfficiency(Farm farm) {
    if (farm.chicken == null || farm.egg == null) return 0.0;
    
    final chickenCount = farm.chicken!.currentCount;
    if (chickenCount == 0) return 0.0;

    final dailyProduction = farm.egg!.productionDailyAverageLastNDays(30);
    final dailyProductionPerChicken = dailyProduction / chickenCount;
    
    // Idealda har bir tovuq kuniga 0.8 ta tuxum berishi kerak
    return (dailyProductionPerChicken / 0.8) * 100;
  }

  static Future<double> _calculateGrowthRate(Farm farm, DateTime startDate, DateTime endDate) async {
    // Bu yerda growth rate hisoblash logikasini qo'shish kerak
    return 0.0;
  }

  static List<Map<String, dynamic>> _getMonthlyCustomerStats(List<Customer> customers) {
    final monthlyStats = <String, Map<String, int>>{};
    
    for (final customer in customers) {
      final month = "${customer.createdAt.year}-${customer.createdAt.month.toString().padLeft(2, '0')}";
      monthlyStats[month] ??= {'new': 0, 'active': 0};
      monthlyStats[month]!['new'] = (monthlyStats[month]!['new'] ?? 0) + 1;
    }

    return monthlyStats.entries.map((entry) => {
      'month': entry.key,
      'newCustomers': entry.value['new'],
      'activeCustomers': entry.value['active'],
    }).toList();
  }

  static List<String> _generateCustomerInsights(
    List<Customer> allCustomers,
    List<Customer> activeCustomers, 
    List<Customer> debtorCustomers,
  ) {
    final insights = <String>[];
    
    if (debtorCustomers.length > allCustomers.length * 0.7) {
      insights.add('⚠️ Mijozlarning 70%dan ko\'pi qarzga ega');
    }
    
    if (activeCustomers.length < allCustomers.length * 0.3) {
      insights.add('📉 Aktiv mijozlar soni kam - marketing kerak');
    }
    
    final averageDebt = debtorCustomers.isNotEmpty 
        ? debtorCustomers.fold<double>(0, (sum, c) => sum + c.totalDebt) / debtorCustomers.length 
        : 0;
    
    if (averageDebt > 500000) {
      insights.add('💰 O\'rtacha qarz miqdori yuqori - to\'lovlarni tezlashtirish kerak');
    }

    return insights;
  }

  static Map<String, dynamic> _getBestProductionDay(Egg egg) {
    if (egg.production.isEmpty) return {};
    
    final dayStats = <String, int>{};
    for (final prod in egg.production) {
      final day = "${prod.date.year}-${prod.date.month}-${prod.date.day}";
      dayStats[day] = (dayStats[day] ?? 0) + prod.trayCount;
    }
    
    final best = dayStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return {
      'date': best.key,
      'production': best.value,
    };
  }

  static Map<String, dynamic> _getBestWeek(Egg egg) {
    // Bu yerda haftalik eng yaxshi natijani hisoblash
    return {};
  }

  static String _calculateProductionTrend(Egg egg) {
    final last7Days = egg.productionDailyAverageLastNDays(7);
    final previous7Days = egg.productionDailyAverageLastNDays(14) - last7Days;
    
    if (last7Days > previous7Days) {
      return 'Ortib bormoqda';
    } else if (last7Days < previous7Days) {
      return 'Kamayib bormoqda';
    } else {
      return 'Barqaror';
    }
  }

  static double _calculateProductionRate(Farm farm) {
    if (farm.chicken == null || farm.egg == null) return 0.0;
    
    final chickenCount = farm.chicken!.currentCount;
    if (chickenCount == 0) return 0.0;
    
    final dailyProduction = farm.egg!.productionDailyAverageLastNDays(7);
    return (dailyProduction / chickenCount) * 100;
  }

  static double _calculateConsistency(Egg egg) {
    final last30Days = List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      return egg.production.where((prod) =>
          prod.date.year == date.year &&
          prod.date.month == date.month &&
          prod.date.day == date.day).fold(0, (sum, prod) => sum + prod.trayCount);
    });

    if (last30Days.isEmpty) return 0.0;
    
    final average = last30Days.reduce((a, b) => a + b) / last30Days.length;
    final variance = last30Days.map((x) => (x - average) * (x - average)).reduce((a, b) => a + b) / last30Days.length;
    final standardDeviation = math.sqrt(variance);
    
    return average > 0 ? (1 - (standardDeviation / average)) * 100 : 0;
  }

  static int _projectNextWeek(Egg egg) {
    final weeklyAverage = egg.productionDailyAverageLastNDays(7);
    return (weeklyAverage * 7).round();
  }

  static int _projectNextMonth(Egg egg) {
    final monthlyAverage = egg.productionDailyAverageLastNDays(30);
    return (monthlyAverage * 30).round();
  }
}
