import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/farm_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0; // 0: 7 kun, 1: 30 kun, 2: 90 kun

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Tahlillar va Hisobotlar',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('7 kun')),
              const PopupMenuItem(value: 1, child: Text('30 kun')),
              const PopupMenuItem(value: 2, child: Text('90 kun')),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Tab Bar
          Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Umumiy'),
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Grafiklar'),
                Tab(icon: Icon(Icons.report_outlined), text: 'Hisobotlar'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final chicken = farm?.chicken;
        final egg = farm?.egg;
        final customers = farm?.customers ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Statistics Header
              Row(
                children: [
                  Icon(Icons.bar_chart, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Asosiy ko\'rsatkichlar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Enhanced Stats Cards with trend analysis
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildEnhancedStatsCard(
                    title: 'Joriy tuxum',
                    value: '${egg?.currentStock ?? 0}',
                    subtitle: 'fletka',
                    icon: Icons.egg_outlined,
                    color: AppTheme.accentColor,
                    trend: _getTrendText(egg, 'production'),
                    isPositive: _isTrendPositive(egg, 'production'),
                  ),
                  _buildEnhancedStatsCard(
                    title: 'Tovuqlar soni',
                    value: '${chicken?.currentCount ?? 0}',
                    subtitle: 'tovuq',
                    icon: Icons.pets,
                    color: AppTheme.success,
                    trend: _getTrendText(chicken, 'deaths'),
                    isPositive: _isTrendPositive(chicken, 'deaths'),
                  ),
                  _buildEnhancedStatsCard(
                    title: 'Mijozlar',
                    value: '${customers.length}',
                    subtitle: 'mijoz',
                    icon: Icons.people_outline,
                    color: AppTheme.info,
                    trend: '+0',
                    isPositive: true,
                  ),
                  _buildEnhancedStatsCard(
                    title: 'Bugungi foyda',
                    value:
                        '${_calculateDailyProfit(egg, chicken).toStringAsFixed(0)}',
                    subtitle: 'so\'m',
                    icon: Icons.attach_money,
                    color: AppTheme.warning,
                    trend: _getProfitTrend(egg),
                    isPositive: _isProfitTrendPositive(egg),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Farm Summary
              Row(
                children: [
                  Icon(Icons.timeline, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Ferma xulosasi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugungi holatlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      'Bugungi tuxum yig\'imi',
                      '${egg?.todayProduction ?? 0} fletka',
                    ),
                    _buildSummaryRow(
                      'Bugungi o\'limlar',
                      '${chicken?.todayDeaths ?? 0} tovuq',
                    ),
                    _buildSummaryRow(
                      'Umumiy zaxira',
                      '${egg?.currentStock ?? 0} fletka',
                    ),
                    _buildSummaryRow(
                      'Faol mijozlar',
                      '${customers.length} mijoz',
                    ),
                    _buildSummaryRow(
                      'Qarzlar miqdori',
                      '${customers.fold<double>(0, (sum, c) => sum + c.totalDebt).toStringAsFixed(0)} so\'m',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final egg = farm?.egg;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Egg Production Chart
              _buildEggProductionChart(egg),
              const SizedBox(height: 20),
              // Sales Chart
              _buildSalesChart(egg),
              const SizedBox(height: 20),
              // Stock Chart
              _buildStockChart(egg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final chicken = farm?.chicken;
        final egg = farm?.egg;
        final customers = farm?.customers ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.report, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Batafsil hisobotlar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Production Report
              _buildReportCard(
                'Ishlab chiqarish hisoboti',
                [
                  'Umumiy ishlab chiqarish: ${egg?.production.fold<int>(0, (sum, p) => sum + p.trayCount) ?? 0} fletka',
                  'Bugungi ishlab chiqarish: ${egg?.todayProduction ?? 0} fletka',
                  'O\'rtacha kunlik: ${egg?.production.isNotEmpty ?? false ? (egg!.production.fold<int>(0, (sum, p) => sum + p.trayCount) / egg.production.length).toStringAsFixed(1) : '0'} fletka',
                  'Eng ko\'p kun: ${_getMostProductiveDay(egg)} fletka',
                ],
                Icons.egg,
                AppTheme.accentColor,
              ),

              const SizedBox(height: 16),

              // Sales Report
              _buildReportCard(
                'Sotuvlar hisoboti',
                [
                  'Umumiy sotuvlar: ${egg?.sales.fold<int>(0, (sum, s) => sum + s.trayCount) ?? 0} fletka',
                  'Bugungi sotuvlar: ${egg?.todaySales ?? 0} fletka',
                  'O\'rtacha narx: ${egg?.sales.isNotEmpty ?? false ? (egg!.sales.fold<double>(0, (sum, s) => sum + s.pricePerTray) / egg.sales.length).toStringAsFixed(0) : '0'} so\'m',
                  'Jami daromad: ${egg?.sales.fold<double>(0, (sum, s) => sum + (s.trayCount * s.pricePerTray))?.toStringAsFixed(0) ?? '0'} so\'m',
                ],
                Icons.sell,
                AppTheme.success,
              ),

              const SizedBox(height: 16),

              // Chicken Report
              _buildReportCard(
                'Tovuqlar hisoboti',
                [
                  'Umumiy tovuqlar: ${chicken?.totalCount ?? 0} ta',
                  'Joriy soni: ${chicken?.currentCount ?? 0} ta',
                  'Bugungi o\'limlar: ${chicken?.todayDeaths ?? 0} ta',
                  'Umumiy o\'limlar: ${chicken?.deaths.fold<int>(0, (sum, d) => sum + d.count) ?? 0} ta',
                ],
                Icons.pets,
                AppTheme.info,
              ),

              const SizedBox(height: 16),

              // Customer Report
              _buildReportCard(
                'Mijozlar hisoboti',
                [
                  'Jami mijozlar: ${customers.length} ta',
                  'Qarzli mijozlar: ${customers.where((c) => c.totalDebt > 0).length} ta',
                  'Jami qarz: ${customers.fold<double>(0, (sum, c) => sum + c.totalDebt).toStringAsFixed(0)} so\'m',
                  'O\'rtacha qarz: ${customers.where((c) => c.totalDebt > 0).isNotEmpty ? (customers.fold<double>(0, (sum, c) => sum + c.totalDebt) / customers.where((c) => c.totalDebt > 0).length).toStringAsFixed(0) : '0'} so\'m',
                ],
                Icons.people,
                AppTheme.warning,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStatsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.1), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEggProductionChart(egg) {
    if (egg == null || egg.production.isEmpty) {
      return _buildEmptyChart('Ishlab chiqarish ma\'lumotlari yo\'q');
    }

    // Get last 7 production records
    final productions = egg.production.take(7).toList().reversed.toList();
    final spots = productions.asMap().entries.map<FlSpot>((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.trayCount.toDouble());
    }).toList();

    return _buildChart(
      'Haftalik tuxum ishlab chiqarish',
      spots,
      AppTheme.accentColor,
      Icons.egg,
    );
  }

  Widget _buildSalesChart(egg) {
    if (egg == null || egg.sales.isEmpty) {
      return _buildEmptyChart('Sotuvlar ma\'lumotlari yo\'q');
    }

    final sales = egg.sales.take(7).toList().reversed.toList();
    final spots = sales.asMap().entries.map<FlSpot>((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.trayCount.toDouble());
    }).toList();

    return _buildChart(
      'Haftalik tuxum sotuvlari',
      spots,
      AppTheme.success,
      Icons.sell,
    );
  }

  Widget _buildStockChart(egg) {
    if (egg == null) {
      return _buildEmptyChart('Zaxira ma\'lumotlari yo\'q');
    }

    // Simple stock visualization
    final currentStock = egg.currentStock.toDouble();
    final spots = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), currentStock),
    );

    return _buildChart(
      'Joriy tuxum zaxirasi',
      spots,
      AppTheme.info,
      Icons.inventory,
    );
  }

  Widget _buildChart(
    String title,
    List<FlSpot> spots,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(item, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMostProductiveDay(egg) {
    if (egg == null || egg.production.isEmpty) return '0';

    final maxProduction = egg.production.reduce(
      (a, b) => a.trayCount > b.trayCount ? a : b,
    );
    return maxProduction.trayCount.toString();
  }

  // AI-powered trend analysis methods
  String _getTrendText(dynamic data, String type) {
    if (data == null) return '0';

    if (type == 'production' && data.production != null) {
      final recentProduction = _getRecentAverageProduction(data, 3);
      final historicalAverage = _getHistoricalAverageProduction(data, 14);

      if (recentProduction > historicalAverage * 1.2) {
        return '+${((recentProduction - historicalAverage) / historicalAverage * 100).toStringAsFixed(0)}%';
      } else if (recentProduction < historicalAverage * 0.8) {
        return '-${((historicalAverage - recentProduction) / historicalAverage * 100).toStringAsFixed(0)}%';
      }
      return '0%';
    }

    if (type == 'deaths' && data.deaths != null) {
      final recentDeaths = _getRecentDeaths(data, 3);
      final historicalDeaths = _getHistoricalDeaths(data, 14);

      if (recentDeaths < historicalDeaths * 0.8) {
        return 'Yaxshi';
      } else if (recentDeaths > historicalDeaths * 1.5) {
        return 'Ogohlik';
      }
      return 'Normal';
    }

    return '0';
  }

  bool _isTrendPositive(dynamic data, String type) {
    if (data == null) return true;

    if (type == 'production' && data.production != null) {
      final recentProduction = _getRecentAverageProduction(data, 3);
      final historicalAverage = _getHistoricalAverageProduction(data, 14);
      return recentProduction >= historicalAverage;
    }

    if (type == 'deaths' && data.deaths != null) {
      final recentDeaths = _getRecentDeaths(data, 3);
      final historicalDeaths = _getHistoricalDeaths(data, 14);
      return recentDeaths <= historicalDeaths;
    }

    return true;
  }

  double _calculateDailyProfit(dynamic egg, dynamic chicken) {
    if (egg == null) return 0.0;

    final todayProduction = egg.todayProduction ?? 0;
    final todayRevenue = todayProduction * 10000; // 10,000 so'm per tray

    // Estimate daily costs
    final feedCost =
        (chicken?.currentCount ?? 0) * 500; // 500 so'm per chicken daily
    final maintenanceCost = 5000; // Fixed daily cost

    return todayRevenue - feedCost - maintenanceCost;
  }

  String _getProfitTrend(dynamic egg) {
    if (egg == null || egg.sales == null || egg.sales.isEmpty) return '0%';

    final recentSales = _getRecentSales(egg, 7);
    final previousSales = _getPreviousSales(egg, 7, 14);

    if (previousSales > 0) {
      final change = ((recentSales - previousSales) / previousSales * 100);
      return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
    }

    return '0%';
  }

  bool _isProfitTrendPositive(dynamic egg) {
    if (egg == null || egg.sales == null || egg.sales.isEmpty) return true;

    final recentSales = _getRecentSales(egg, 7);
    final previousSales = _getPreviousSales(egg, 7, 14);

    return recentSales >= previousSales;
  }

  // Helper methods for trend analysis
  double _getRecentAverageProduction(dynamic egg, int days) {
    if (egg.production == null || egg.production.isEmpty) return 0.0;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    final recentProductions = egg.production
        .where((p) => p.date.isAfter(cutoff))
        .toList();
    if (recentProductions.isEmpty) return 0.0;

    final total = recentProductions.fold<int>(0, (sum, p) => sum + p.trayCount);
    return total / days;
  }

  double _getHistoricalAverageProduction(dynamic egg, int days) {
    if (egg.production == null || egg.production.isEmpty) return 0.0;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final endDate = now.subtract(Duration(days: 3)); // Exclude recent 3 days

    final historicalProductions = egg.production
        .where((p) => p.date.isAfter(startDate) && p.date.isBefore(endDate))
        .toList();

    if (historicalProductions.isEmpty) return 0.0;

    final total = historicalProductions.fold<int>(
      0,
      (sum, p) => sum + p.trayCount,
    );
    return total / (days - 3);
  }

  double _getRecentDeaths(dynamic chicken, int days) {
    if (chicken.deaths == null || chicken.deaths.isEmpty) return 0.0;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    final recentDeaths = chicken.deaths
        .where((d) => d.date.isAfter(cutoff))
        .toList();
    final total = recentDeaths.fold<int>(0, (sum, d) => sum + d.count);
    return total / days;
  }

  double _getHistoricalDeaths(dynamic chicken, int days) {
    if (chicken.deaths == null || chicken.deaths.isEmpty) return 0.0;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final endDate = now.subtract(Duration(days: 3));

    final historicalDeaths = chicken.deaths
        .where((d) => d.date.isAfter(startDate) && d.date.isBefore(endDate))
        .toList();

    if (historicalDeaths.isEmpty) return 0.0;

    final total = historicalDeaths.fold<int>(0, (sum, d) => sum + d.count);
    return total / (days - 3);
  }

  double _getRecentSales(dynamic egg, int days) {
    if (egg.sales == null || egg.sales.isEmpty) return 0.0;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    final recentSales = egg.sales.where((s) => s.date.isAfter(cutoff)).toList();
    return recentSales.fold<double>(
      0,
      (sum, s) => sum + (s.trayCount * s.pricePerTray),
    );
  }

  double _getPreviousSales(dynamic egg, int recentDays, int totalDays) {
    if (egg.sales == null || egg.sales.isEmpty) return 0.0;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: totalDays));
    final endDate = now.subtract(Duration(days: recentDays));

    final previousSales = egg.sales
        .where((s) => s.date.isAfter(startDate) && s.date.isBefore(endDate))
        .toList();

    return previousSales.fold<double>(
      0,
      (sum, s) => sum + (s.trayCount * s.pricePerTray),
    );
  }
}
