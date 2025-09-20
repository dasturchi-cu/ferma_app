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
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  int _selectedPeriod = 0; // 0: 7 kun, 1: 30 kun, 2: 90 kun

  // Sample data for charts
  List<FlSpot> _eggTrendData = [
    const FlSpot(0, 25),
    const FlSpot(1, 30),
    const FlSpot(2, 28),
    const FlSpot(3, 35),
    const FlSpot(4, 32),
    const FlSpot(5, 38),
    const FlSpot(6, 40),
  ];

  List<BarChartGroupData> _revenueData = [
    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 80000, width: 20)]),
    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 95000, width: 20)]),
    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 75000, width: 20)]),
    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 110000, width: 20)]),
    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 88000, width: 20)]),
    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 120000, width: 20)]),
    BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 105000, width: 20)]),
  ];

  List<FlSpot> _chickenCountData = [
    const FlSpot(0, 150),
    const FlSpot(1, 148),
    const FlSpot(2, 145),
    const FlSpot(3, 143),
    const FlSpot(4, 140),
    const FlSpot(5, 138),
    const FlSpot(6, 135),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
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

  // Copy the content from the simple analytics screen
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

              // Stats Cards with real farm data
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
                    trend: '+${egg?.todayProduction ?? 0}',
                    isPositive: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentColor,
                        AppTheme.accentColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  _buildEnhancedStatsCard(
                    title: 'Tovuqlar soni',
                    value: '${chicken?.currentCount ?? 0}',
                    subtitle: 'tovuq',
                    icon: Icons.pets,
                    color: AppTheme.success,
                    trend:
                        '${chicken?.todayDeaths != null && chicken!.todayDeaths > 0 ? '-${chicken.todayDeaths}' : '0'}',
                    isPositive: (chicken?.todayDeaths ?? 0) == 0,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success,
                        AppTheme.success.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  _buildEnhancedStatsCard(
                    title: 'Mijozlar',
                    value: '${customers.length}',
                    subtitle: 'mijoz',
                    icon: Icons.people_outline,
                    color: AppTheme.info,
                    trend: '+0',
                    isPositive: true,
                    gradient: LinearGradient(
                      colors: [AppTheme.info, AppTheme.info.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  _buildEnhancedStatsCard(
                    title: 'Qarzlar',
                    value: '${customers.where((c) => c.totalDebt > 0).length}',
                    subtitle: 'qarzli mijoz',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.warning,
                    trend:
                        '${customers.fold<double>(0, (sum, c) => sum + c.totalDebt).toStringAsFixed(0)} so\'m',
                    isPositive: false,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning,
                        AppTheme.warning.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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

  Widget _buildEnhancedStatsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
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

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time charts with enhanced animations
          _buildEnhancedEggTrendChart(),
          const SizedBox(height: 20),
          _buildEnhancedRevenueChart(),
          const SizedBox(height: 20),
          _buildEnhancedChickenCountChart(),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Yutuqlar va mukofotlar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Achievement cards
          _buildEnhancedAchievementCard(
            '🔥 Bir hafta ketma-ket!',
            '7 kun ketma-ket ma\'lumot kiritdingiz',
            '🔥',
            Colors.orange,
            true,
            85,
          ),

          const SizedBox(height: 12),

          _buildEnhancedAchievementCard(
            '🥚 Ming fletka!',
            'Jami 1000 fletka tuxum yig\'dingiz',
            '🥚',
            AppTheme.accentColor,
            true,
            100,
          ),

          const SizedBox(height: 12),

          _buildEnhancedAchievementCard(
            '🌟 Eng yaxshi kun!',
            'Bir kunda 40 fletka tuxum yig\'dingiz',
            '🌟',
            Colors.amber,
            true,
            92,
          ),

          const SizedBox(height: 12),

          _buildEnhancedAchievementCard(
            '💰 Millioner!',
            'Bu oy 1 million som foyda qildingiz',
            '💰',
            Colors.green,
            false,
            45,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartHints() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.1),
            AppTheme.warning.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warning.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outlined,
                  color: AppTheme.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Aqlli tavsiyalar',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation:
                    _pulseController ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + ((_pulseController?.value ?? 0.0) * 0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'YANGI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'So\'nggi 3 kun davomida tuxum soni kamaydi. Yem sifatini tekshiring yoki veterinarni chaqiring.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedEggTrendChart() {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.show_chart,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '7 kunlik tuxum trendi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'REAL-TIME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _fadeController ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Du',
                                'Se',
                                'Ch',
                                'Pa',
                                'Ju',
                                'Sh',
                                'Ya',
                              ];
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _eggTrendData,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.accentColor,
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppTheme.primaryColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.3),
                                AppTheme.primaryColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedRevenueChart() {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Oylik daromad grafigi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+12%',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _fadeController ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 120000,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          // Tooltip: AppTheme.success.withOpacity(0.8),
                          // getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          //   return BarTooltipItem(
                          //     '${(rod.toY / 1000).toStringAsFixed(0)}K som\n',
                          //     const TextStyle(
                          //       color: Colors.white,
                          //       fontWeight: FontWeight.bold,
                          //     ),
                          //   );
                          // },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toInt()}K',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Du',
                                'Se',
                                'Ch',
                                'Pa',
                                'Ju',
                                'Sh',
                                'Ya',
                              ];
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barGroups: _revenueData.map((data) {
                        return BarChartGroupData(
                          x: data.x,
                          barRods: [
                            BarChartRodData(
                              toY: data.barRods[0].toY,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.success,
                                  AppTheme.success.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedChickenCountChart() {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.pets, color: AppTheme.warning, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tovuqlar soni o\'zgarishi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: AppTheme.warning,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'KUZATISH',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _fadeController ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Du',
                                'Se',
                                'Ch',
                                'Pa',
                                'Ju',
                                'Sh',
                                'Ya',
                              ];
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chickenCountData,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [AppTheme.warning, Colors.orange],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppTheme.warning,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.warning.withOpacity(0.3),
                                AppTheme.warning.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAchievementCard(
    String title,
    String description,
    String icon,
    Color color,
    bool unlocked,
    double progress,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: unlocked
            ? LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (unlocked ? color : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: unlocked
                        ? LinearGradient(
                            colors: [
                              color.withOpacity(0.3),
                              color.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: unlocked ? color : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? color.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        unlocked ? Icons.check_circle : Icons.lock,
                        color: unlocked ? color : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: unlocked
                          ? [color, color.withOpacity(0.7)]
                          : [Colors.grey, Colors.grey.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final egg = farm?.egg;
        final chicken = farm?.chicken;
        final customers = farm?.customers ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reports Header
              Row(
                children: [
                  Icon(
                    Icons.assessment,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hisobotlar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Daily Report Card
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.today,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Bugungi hisobot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportRow(
                      'Tuxum yig\'imi',
                      '${egg?.todayProduction ?? 0} fletka',
                    ),
                    _buildReportRow(
                      'Tovuq o\'limlari',
                      '${chicken?.todayDeaths ?? 0} tovuq',
                    ),
                    _buildReportRow(
                      'Joriy zaxira',
                      '${egg?.currentStock ?? 0} fletka',
                    ),
                    _buildReportRow(
                      'Faol mijozlar',
                      '${customers.length} mijoz',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Weekly Report Card
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_view_week,
                            color: AppTheme.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Haftalik hisobot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportRow(
                      'O\'rtacha kunlik yig\'im',
                      '${((egg?.todayProduction ?? 0) * 0.9).toStringAsFixed(1)} fletka',
                    ),
                    _buildReportRow(
                      'Jami o\'limlar',
                      '${(chicken?.todayDeaths ?? 0) * 2} tovuq',
                    ),
                    _buildReportRow(
                      'Sotilgan tuxum',
                      '${((egg?.todayProduction ?? 0) * 5).toStringAsFixed(0)} fletka',
                    ),
                    _buildReportRow(
                      'Daromad',
                      '${((egg?.todayProduction ?? 0) * 5 * 1500).toStringAsFixed(0)} so\'m',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Monthly Report Card
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: AppTheme.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Oylik hisobot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReportRow(
                      'Jami yig\'ilgan tuxum',
                      '${((egg?.todayProduction ?? 0) * 25).toStringAsFixed(0)} fletka',
                    ),
                    _buildReportRow(
                      'Jami o\'limlar',
                      '${(chicken?.todayDeaths ?? 0) * 8} tovuq',
                    ),
                    _buildReportRow(
                      'Jami sotilgan',
                      '${((egg?.todayProduction ?? 0) * 20).toStringAsFixed(0)} fletka',
                    ),
                    _buildReportRow(
                      'Jami daromad',
                      '${((egg?.todayProduction ?? 0) * 20 * 1500).toStringAsFixed(0)} so\'m',
                    ),
                    _buildReportRow(
                      'Foyda',
                      '${((egg?.todayProduction ?? 0) * 20 * 1500 * 0.3).toStringAsFixed(0)} so\'m',
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

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
