import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import '../../utils/app_theme.dart';
import '../../widgets/progress_visualization.dart';
import '../../services/smart_analytics.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AnimationController? _pulseController;
  AnimationController? _fadeController;
  Timer? _realTimeTimer;

  int _selectedPeriod = 0; // 0: 7 kun, 1: 30 kun, 2: 90 kun

  // Real-time data
  List<FlSpot> _eggTrendData = [];
  List<BarChartGroupData> _revenueData = [];
  List<FlSpot> _chickenCountData = [];

  // Stats variables for real-time updates
  int _currentEggs = 28;
  int _currentProfit = 75000;
  double _mortalityRate = 2.4;
  int _activeCustomers = 12;
  bool _isLiveMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeData();
    _startRealTimeUpdates();
  }

  void _initializeData() {
    // Initialize egg trend data
    _eggTrendData = [
      const FlSpot(0, 25),
      const FlSpot(1, 28),
      const FlSpot(2, 30),
      const FlSpot(3, 27),
      const FlSpot(4, 32),
      const FlSpot(5, 29),
      const FlSpot(6, 31),
    ];

    // Initialize revenue data
    _revenueData = List.generate(
      7,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: 75000 + (index * 2000) + Random().nextInt(10000).toDouble(),
            color: AppTheme.success,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );

    // Initialize chicken count data
    _chickenCountData = [
      const FlSpot(0, 250),
      const FlSpot(1, 248),
      const FlSpot(2, 247),
      const FlSpot(3, 245),
      const FlSpot(4, 244),
      const FlSpot(5, 243),
      const FlSpot(6, 242),
    ];
  }

  void _startRealTimeUpdates() {
    _realTimeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isLiveMode && mounted) {
        _updateRealTimeData();
      }
    });
  }

  void _updateRealTimeData() {
    setState(() {
      // Update stats with small random changes
      _currentEggs += Random().nextInt(5) - 2; // -2 to +2
      _currentEggs = _currentEggs.clamp(20, 40);

      _currentProfit += Random().nextInt(10000) - 5000; // -5000 to +5000
      _currentProfit = _currentProfit.clamp(50000, 100000);

      _mortalityRate += (Random().nextDouble() - 0.5) * 0.2; // Small changes
      _mortalityRate = _mortalityRate.clamp(1.0, 4.0);

      if (Random().nextBool()) {
        _activeCustomers += Random().nextBool() ? 1 : -1;
        _activeCustomers = _activeCustomers.clamp(8, 20);
      }

      // Update chart data
      _updateChartData();
    });

    // Trigger fade animation for smooth updates
    _fadeController?.forward().then((_) {
      _fadeController?.reverse();
    });
  }

  void _updateChartData() {
    // Update egg trend (shift data and add new point)
    if (_eggTrendData.length >= 7) {
      _eggTrendData.removeAt(0);
      for (int i = 0; i < _eggTrendData.length; i++) {
        _eggTrendData[i] = FlSpot(i.toDouble(), _eggTrendData[i].y);
      }
    }
    _eggTrendData.add(FlSpot(6, _currentEggs.toDouble()));

    // Update revenue data
    if (_revenueData.length >= 7) {
      _revenueData.removeAt(0);
      for (int i = 0; i < _revenueData.length; i++) {
        _revenueData[i] = BarChartGroupData(
          x: i,
          barRods: _revenueData[i].barRods,
        );
      }
    }
    _revenueData.add(
      BarChartGroupData(
        x: 6,
        barRods: [
          BarChartRodData(
            toY: _currentProfit.toDouble(),
            color: AppTheme.success,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );

    // Update chicken count (gradual decrease with occasional increase)
    if (_chickenCountData.length >= 7) {
      _chickenCountData.removeAt(0);
      for (int i = 0; i < _chickenCountData.length; i++) {
        _chickenCountData[i] = FlSpot(i.toDouble(), _chickenCountData[i].y);
      }
    }
    double lastCount = _chickenCountData.last.y;
    double newCount =
        lastCount + (Random().nextDouble() - 0.7) * 2; // Slight decrease trend
    _chickenCountData.add(FlSpot(6, newCount.clamp(200, 300)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController?.dispose();
    _fadeController?.dispose();
    _realTimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Tahlillar va Statistika',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // Live indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedBuilder(
              animation: _pulseController ?? const AlwaysStoppedAnimation(0.0),
              builder: (context, child) {
                return Container(
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isLiveMode ? Colors.red : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isLiveMode ? 'LIVE' : 'OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
                Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Yutuqlar'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLiveMode = !_isLiveMode;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLiveMode
                    ? 'Real-time yangilanish yoqildi'
                    : 'Real-time yangilanish o\'chirildi',
              ),
              backgroundColor: _isLiveMode ? AppTheme.success : Colors.grey,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: _isLiveMode ? AppTheme.success : Colors.grey,
        child: Icon(_isLiveMode ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smart Analytics Hints with enhanced design
          _buildSmartHints(),

          const SizedBox(height: 24),

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

          // Enhanced Stats Cards with real-time data
          AnimatedBuilder(
            animation: _fadeController ?? const AlwaysStoppedAnimation(0.0),
            builder: (context, child) {
              return Opacity(
                opacity: 1.0 - ((_fadeController?.value ?? 0.0) * 0.3),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildEnhancedStatsCard(
                      title: 'O\'rtacha tuxum',
                      value: _currentEggs.toString(),
                      subtitle: 'fletka/kun',
                      icon: Icons.egg_outlined,
                      color: AppTheme.accentColor,
                      trend: '+5%',
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
                      title: 'O\'rtacha foyda',
                      value: '${(_currentProfit / 1000).toStringAsFixed(0)}K',
                      subtitle: 'som/kun',
                      icon: Icons.trending_up,
                      color: AppTheme.success,
                      trend: '+12%',
                      isPositive: true,
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
                      title: 'Tovuq o\'limi',
                      value: '${_mortalityRate.toStringAsFixed(1)}%',
                      subtitle: 'bu oy',
                      icon: Icons.warning_outlined,
                      color: AppTheme.warning,
                      trend: '-1%',
                      isPositive: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _buildEnhancedStatsCard(
                      title: 'Mijozlar',
                      value: _activeCustomers.toString(),
                      subtitle: 'faol mijozlar',
                      icon: Icons.people_outline,
                      color: AppTheme.info,
                      trend: '+2',
                      isPositive: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.info, AppTheme.info.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Progress Visualization with enhanced design
          Row(
            children: [
              Icon(Icons.timeline, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Taraqqiyot',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ProgressVisualization(
            progress: AchievementProgress(
              totalPoints: 1250,
              currentLevel: 5,
              nextLevelPoints: 1500,
              consecutiveDays: 15,
              totalEggs: 850,
              totalProfit: 2250000,
              healthyDays: 12,
            ),
          ),
        ],
      ),
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
}
