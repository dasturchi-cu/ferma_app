import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';

class AdvancedStatisticsScreen extends StatefulWidget {
  const AdvancedStatisticsScreen({super.key});

  @override
  State<AdvancedStatisticsScreen> createState() => _AdvancedStatisticsScreenState();
}

class _AdvancedStatisticsScreenState extends State<AdvancedStatisticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, child) {
          final farm = farmProvider.farm;
          
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Statistika va Tahlil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.analytics,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Content
              SliverFillRemaining(
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: const [
                          Tab(text: 'Tuxumlar', icon: Icon(Icons.egg)),
                          Tab(text: 'Tovuqlar', icon: Icon(Icons.pets)),
                          Tab(text: 'Qarzlar', icon: Icon(Icons.money_off)),
                        ],
                      ),
                    ),
                    
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEggStatistics(farm),
                          _buildChickenStatistics(farm),
                          _buildDebtStatistics(farm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEggStatistics(farm) {
    final egg = farm?.egg;
    if (egg == null) return _buildEmptyState('Tuxum ma\'lumotlari yo\'q');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Bugungi Ishlab Chiqarish',
                '${egg.todayProduction} fletka',
                Icons.today,
                Colors.blue,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Joriy Zaxira',
                '${egg.currentStock} fletka',
                Icons.inventory,
                Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Bugungi Sotuvlar',
                '${egg.todaySales} fletka',
                Icons.shopping_cart,
                Colors.orange,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Siniq Tuxumlar',
                '${egg.todayBroken} fletka',
                Icons.warning,
                Colors.red,
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Production Chart
          _buildChartCard(
            'Haftalik Ishlab Chiqarish Trendi',
            _buildProductionChart(egg),
          ),
          
          const SizedBox(height: 24),
          
          // Sales Chart
          _buildChartCard(
            'Sotuvlar Tahlili',
            _buildSalesChart(egg),
          ),
        ],
      ),
    );
  }

  Widget _buildChickenStatistics(farm) {
    final chicken = farm?.chicken;
    if (chicken == null) return _buildEmptyState('Tovuq ma\'lumotlari yo\'q');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Umumiy Tovuqlar',
                '${chicken.totalCount} ta',
                Icons.pets,
                Colors.blue,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Joriy Soni',
                '${chicken.currentCount} ta',
                Icons.check_circle,
                Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Bugungi O\'limlar',
                '${chicken.todayDeaths} ta',
                Icons.warning,
                Colors.orange,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Umumiy O\'limlar',
                '${chicken.deathStats['totalDeaths']} ta',
                Icons.error,
                Colors.red,
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Death Trend Chart
          _buildChartCard(
            'O\'limlar Trendi',
            _buildDeathChart(chicken),
          ),
          
          const SizedBox(height: 24),
          
          // Survival Rate
          _buildChartCard(
            'Omon Qolish Ko\'rsatkichi',
            _buildSurvivalChart(chicken),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtStatistics(farm) {
    final customers = farm?.customers ?? [];
    final customersWithDebt = customers.where((c) => c.totalDebt > 0).toList();
    
    if (customersWithDebt.isEmpty) return _buildEmptyState('Qarzdor mijozlar yo\'q');

    final totalDebt = customersWithDebt.fold(0.0, (sum, c) => sum + c.totalDebt);
    final avgDebt = totalDebt / customersWithDebt.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Qarzdor Mijozlar',
                '${customersWithDebt.length} ta',
                Icons.people,
                Colors.blue,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Umumiy Qarz',
                '${totalDebt.toStringAsFixed(0)} so\'m',
                Icons.money_off,
                Colors.red,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'O\'rtacha Qarz',
                '${avgDebt.toStringAsFixed(0)} so\'m',
                Icons.analytics,
                Colors.orange,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Eng Katta Qarz',
                '${customersWithDebt.map((c) => c.totalDebt).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} so\'m',
                Icons.trending_up,
                Colors.purple,
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Debt Distribution Chart
          _buildChartCard(
            'Qarz Taqsimoti',
            _buildDebtChart(customersWithDebt),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
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
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionChart(egg) {
    // Mock data for demonstration
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 4),
              const FlSpot(2, 3.5),
              const FlSpot(3, 5),
              const FlSpot(4, 4),
              const FlSpot(5, 6),
              const FlSpot(6, 5.5),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(egg) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.orange)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: Colors.orange)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 6, color: Colors.orange)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.orange)]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 9, color: Colors.orange)]),
        ],
      ),
    );
  }

  Widget _buildDeathChart(chicken) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 0),
              const FlSpot(1, 2),
              const FlSpot(2, 1),
              const FlSpot(3, 0),
              const FlSpot(4, 3),
              const FlSpot(5, 1),
              const FlSpot(6, 0),
            ],
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSurvivalChart(chicken) {
    final currentCount = chicken.currentCount;
    final totalCount = chicken.totalCount;
    final survivalRate = totalCount > 0 ? (currentCount / totalCount) * 100 : 0;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: survivalRate,
                    title: '${survivalRate.toStringAsFixed(1)}%',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: (100 - survivalRate).toDouble(),
                    title: '${(100 - survivalRate).toStringAsFixed(1)}%',
                    radius: 60,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Tirik', Colors.green),
              const SizedBox(width: 20),
              _buildLegendItem('O\'lgan', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtChart(List<dynamic> customers) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: customers.take(5).map((customer) {
          return BarChartGroupData(
            x: customers.indexOf(customer),
            barRods: [
              BarChartRodData(
                toY: customer.totalDebt / 1000, // Scale for better visualization
                color: Colors.red,
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}