import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../providers/farm_provider.dart';
import '../../widgets/stat_card.dart';
import '../../models/egg.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobotlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDatePicker(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getMonthName(_selectedMonth)} $_selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showDatePicker(),
                  child: const Text('O\'zgartirish'),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Umumiy'),
              Tab(text: 'Tuxum'),
              Tab(text: 'Moliya'),
              Tab(text: 'Mijozlar'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewReport(),
                _buildEggReport(),
                _buildFinanceReport(),
                _buildCustomerReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null) {
          return const Center(child: Text('Ma\'lumot yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Umumiy ko\'rsatkichlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    title: 'Jami Tovuqlar',
                    value: '${farm.chicken?.currentCount ?? 0}',
                    icon: Icons.pets,
                    color: AppTheme.primaryColor,
                  ),
                  StatCard(
                    title: 'Jami Tuxum',
                    value: '${farm.egg?.currentStock ?? 0}',
                    icon: Icons.egg,
                    color: AppTheme.primaryColor,
                  ),
                  StatCard(
                    title: 'Jami Mijozlar',
                    value: '${farm.customers.length}',
                    icon: Icons.people,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Jami Qarz',
                    value: '${_calculateTotalDebt(farm.customers)} som',
                    icon: Icons.warning,
                    color: AppTheme.warning,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Bu oylik statistika',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _buildMonthlySummaryCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEggReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null || farm.egg == null) {
          return const Center(child: Text('Tuxum ma\'lumotlari yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tuxum hisoboti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    title: 'Yig\'ilgan Tuxum',
                    value: '${_getTotalEggProduction(farm.egg)} fletka',
                    icon: Icons.egg,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    title: 'Sotilgan Tuxum',
                    value: '${_getTotalEggSales(farm.egg)} fletka',
                    icon: Icons.shopping_cart,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Siniq Tuxum',
                    value: '${_getTotalBrokenEggs(farm.egg)} fletka',
                    icon: Icons.broken_image,
                    color: AppTheme.error,
                  ),
                  StatCard(
                    title: 'Katta Tuxum',
                    value: '${_getTotalLargeEggs(farm.egg)} fletka',
                    icon: Icons.expand,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildEggChart(),

              const SizedBox(height: 16),

              _buildRevenueChart(),

              const SizedBox(height: 24),

              // Lifetime and daily drilldown
              _buildDailyReportsSection(farm.egg!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null) {
          return const Center(child: Text('Moliyaviy ma\'lumotlar yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Moliyaviy hisobot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    title: 'Jami Daromad',
                    value: '${_getTotalRevenue(farm.egg)} som',
                    icon: Icons.trending_up,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    title: 'Oylik Daromad',
                    value:
                        '${_getMonthlyRevenue(farm.egg, _selectedMonth, _selectedYear).toStringAsFixed(0)} som',
                    icon: Icons.trending_down,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Sof Foyda',
                    value: '${_getNetProfit(farm.egg).toStringAsFixed(0)} som',
                    icon: Icons.attach_money,
                    color: _getNetProfit(farm.egg) > 0
                        ? AppTheme.success
                        : AppTheme.error,
                  ),
                  StatCard(
                    title: 'O\'rtacha Kun Daromadi',
                    value:
                        '${_getAverageDailyRevenue(farm.egg).toStringAsFixed(0)} som',
                    icon: Icons.calendar_today,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildRevenueChart(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null || farm.customers.isEmpty) {
          return const Center(child: Text('Mijozlar ma\'lumotlari yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mijozlar hisoboti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    title: 'Jami Mijozlar',
                    value: '${farm.customers.length}',
                    icon: Icons.people,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Qarzdor Mijozlar',
                    value: '${_getDebtorCustomers(farm.customers)}',
                    icon: Icons.warning,
                    color: AppTheme.warning,
                  ),
                  StatCard(
                    title: 'Jami Qarz',
                    value: '${_calculateTotalDebt(farm.customers)} som',
                    icon: Icons.money_off,
                    color: AppTheme.error,
                  ),
                  StatCard(
                    title: 'Faol Mijozlar',
                    value: '${_getActiveCustomers(farm.customers)}',
                    icon: Icons.person,
                    color: AppTheme.success,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildCustomerDebtChart(farm.customers),

              const SizedBox(height: 16),

              _buildCustomerList(farm.customers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Oylik xulosa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu oy uchun avtomatik hisobot tez orada tayyorlanadi.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEggChart() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm?.egg == null) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tuxum trendi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Ma\'lumot yo\'q',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final eggData = _generateEggChartData(farm!.egg!);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuxum trendi (7 kun)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              Widget text;
                              switch (value.toInt()) {
                                case 0:
                                  text = const Text('Dush', style: style);
                                  break;
                                case 1:
                                  text = const Text('Sesh', style: style);
                                  break;
                                case 2:
                                  text = const Text('Chor', style: style);
                                  break;
                                case 3:
                                  text = const Text('Pay', style: style);
                                  break;
                                case 4:
                                  text = const Text('Jum', style: style);
                                  break;
                                case 5:
                                  text = const Text('Shan', style: style);
                                  break;
                                case 6:
                                  text = const Text('Yak', style: style);
                                  break;
                                default:
                                  text = const Text('', style: style);
                                  break;
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: text,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: eggData['maxY'] + 2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: eggData['spots'],
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.primaryColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm?.egg == null) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daromad trendi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Ma\'lumot yo\'q',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final revenueData = _generateRevenueChartData(farm!.egg!);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daromad trendi (7 kun)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              Widget text;
                              switch (value.toInt()) {
                                case 0:
                                  text = const Text('Dush', style: style);
                                  break;
                                case 1:
                                  text = const Text('Sesh', style: style);
                                  break;
                                case 2:
                                  text = const Text('Chor', style: style);
                                  break;
                                case 3:
                                  text = const Text('Pay', style: style);
                                  break;
                                case 4:
                                  text = const Text('Jum', style: style);
                                  break;
                                case 5:
                                  text = const Text('Shan', style: style);
                                  break;
                                case 6:
                                  text = const Text('Yak', style: style);
                                  break;
                                default:
                                  text = const Text('', style: style);
                                  break;
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: text,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: revenueData['maxY'] + 1000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueData['spots'],
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success,
                              AppTheme.success.withOpacity(0.8),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.success,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.success.withOpacity(0.3),
                                AppTheme.success.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
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
      },
    );
  }

  Widget _buildCustomerDebtChart(List customers) {
    if (customers.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mijozlar qarzi taqsimoti',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                child: Center(
                  child: Text(
                    'Mijozlar yo\'q',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final debtData = _generateCustomerDebtData(customers);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mijozlar qarzi taqsimoti',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: debtData['sections'],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: debtData['legend'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List customers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eng ko\'p qarzdor mijozlar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...customers
                .take(5)
                .map(
                  (customer) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(customer.name),
                    subtitle: Text('${customer.totalDebt} som qarz'),
                    trailing: customer.totalDebt > 0
                        ? const Icon(Icons.warning, color: Colors.orange)
                        : const Icon(Icons.check, color: Colors.green),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sana tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: _selectedMonth,
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(_getMonthName(index + 1)),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                  });
                }
              },
            ),
            DropdownButton<int>(
              value: _selectedYear,
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: DateTime.now().year - index,
                  child: Text('${DateTime.now().year - index}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Tanlash'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hisobotni eksport qilish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Excel eksport tez orada qo\'shiladi');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('PDF eksport tez orada qo\'shiladi');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    return months[month - 1];
  }

  // Helper methods for calculations
  double _calculateTotalDebt(List customers) {
    return customers.fold(0.0, (sum, customer) => sum + customer.totalDebt);
  }

  int _getTotalEggProduction(Egg? egg) {
    if (egg == null) return 0;
    return egg.production.fold(0, (sum, prod) => sum + prod.trayCount);
  }

  int _getTotalEggSales(Egg? egg) {
    if (egg == null) return 0;
    return egg.sales.fold(0, (sum, sale) => sum + sale.trayCount);
  }

  int _getTotalBrokenEggs(Egg? egg) {
    if (egg == null) return 0;
    return egg.brokenEggs.fold(0, (sum, broken) => sum + broken.trayCount);
  }

  int _getTotalLargeEggs(Egg? egg) {
    if (egg == null) return 0;
    return egg.largeEggs.fold(0, (sum, large) => sum + large.trayCount);
  }

  double _getTotalRevenue(Egg? egg) {
    if (egg == null) return 0;
    return egg.sales.fold(
      0.0,
      (sum, sale) => sum + (sale.trayCount * sale.pricePerTray),
    );
  }

  double _getAverageDailyRevenue(Egg? egg) {
    if (egg == null || egg.sales.isEmpty) return 0;

    final totalRevenue = _getTotalRevenue(egg);
    final firstSaleDate = egg.sales
        .map((s) => s.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(firstSaleDate).inDays;

    return days > 0 ? totalRevenue / days : totalRevenue;
  }

  // Get monthly revenue
  double _getMonthlyRevenue(Egg? egg, int month, int year) {
    if (egg == null) return 0;

    double monthlyRevenue = 0;
    for (final sale in egg.sales) {
      if (sale.date.month == month && sale.date.year == year) {
        monthlyRevenue += sale.trayCount * sale.pricePerTray;
      }
    }
    return monthlyRevenue;
  }

  // Removed unused _getMonthlyProduction

  // Calculate net profit (revenue minus estimated costs)
  double _getNetProfit(Egg? egg) {
    if (egg == null) return 0;

    final totalRevenue = _getTotalRevenue(egg);
    // Estimate basic costs (simplified)
    final estimatedCosts =
        _getTotalEggProduction(egg) * 8000; // 8000 som per tray cost estimate

    return totalRevenue - estimatedCosts;
  }

  int _getDebtorCustomers(List customers) {
    return customers.where((customer) => customer.totalDebt > 0).length;
  }

  int _getActiveCustomers(List customers) {
    return customers.length; // TODO: Add logic for active customers
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryColor),
    );
  }

  // Generate egg chart data for the last 7 days
  Map<String, dynamic> _generateEggChartData(Egg egg) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    double maxY = 0;

    // Generate data for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayOfWeek = date.weekday - 1; // 0 = Monday, 6 = Sunday

      // Calculate total eggs for this day (simplified - using random data for demo)
      // In a real app, you'd query actual daily records
      final dailyEggs = _getDailyEggCount(egg, date);
      maxY = maxY > dailyEggs ? maxY : dailyEggs.toDouble();

      spots.add(FlSpot(dayOfWeek.toDouble(), dailyEggs.toDouble()));
    }

    return {'spots': spots, 'maxY': maxY};
  }

  // Get daily egg count from actual production data
  int _getDailyEggCount(Egg egg, DateTime date) {
    int dailyCount = 0;

    // Calculate production on this specific date
    for (final production in egg.production) {
      final productionDate = production.date;
      if (productionDate.year == date.year &&
          productionDate.month == date.month &&
          productionDate.day == date.day) {
        dailyCount += production.trayCount;
      }
    }

    return dailyCount;
  }

  // Generate revenue chart data
  Map<String, dynamic> _generateRevenueChartData(Egg egg) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayOfWeek = date.weekday - 1;

      // Calculate daily revenue
      final dailyRevenue = _getDailyRevenue(egg, date);
      maxY = maxY > dailyRevenue ? maxY : dailyRevenue.toDouble();

      spots.add(FlSpot(dayOfWeek.toDouble(), dailyRevenue));
    }

    return {'spots': spots, 'maxY': maxY};
  }

  // Get daily revenue from actual sales data
  double _getDailyRevenue(Egg egg, DateTime date) {
    double dailyRevenue = 0;

    // Calculate revenue from sales on this specific date
    for (final sale in egg.sales) {
      final saleDate = sale.date;
      if (saleDate.year == date.year &&
          saleDate.month == date.month &&
          saleDate.day == date.day) {
        dailyRevenue += sale.trayCount * sale.pricePerTray;
      }
    }

    return dailyRevenue;
  }

  // Generate customer debt data for pie chart
  Map<String, dynamic> _generateCustomerDebtData(List customers) {
    final debtors = customers.where((c) => c.totalDebt > 0).toList();
    final paidCustomers = customers.where((c) => c.totalDebt == 0).toList();

    final sections = <PieChartSectionData>[];
    final legend = <Widget>[];

    if (debtors.isNotEmpty) {
      final debtorPercentage = (debtors.length / customers.length) * 100;
      sections.add(
        PieChartSectionData(
          color: AppTheme.warning,
          value: debtorPercentage,
          title: '${debtorPercentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      legend.add(
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Qarzdorlar (${debtors.length})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (paidCustomers.isNotEmpty) {
      final paidPercentage = (paidCustomers.length / customers.length) * 100;
      sections.add(
        PieChartSectionData(
          color: AppTheme.success,
          value: paidPercentage,
          title: '${paidPercentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      legend.add(
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'To\'langan (${paidCustomers.length})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return {'sections': sections, 'legend': legend};
  }
}

// =========================
// Daily reports (lifetime + per-day details)
// =========================
extension _DailyReports on _ReportsScreenState {
  Widget _buildDailyReportsSection(Egg egg) {
    final lifetime = _lifetimeAggregates(egg);
    final dailyList = _buildPerDayAggregates(egg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kunlik hisobotlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Lifetime aggregate card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Umrbod umumiy xulosa'),
            subtitle: Text(
              'Yig\'ilgan: ${lifetime['production']} | Sotilgan: ${lifetime['sales']} | Siniq: ${lifetime['broken']} | Katta: ${lifetime['large']} | Daromad: ${lifetime['revenue'].toStringAsFixed(0)} som',
            ),
            onTap: () {
              _showDailyDetailDialog(
                title: 'Umrbod umumiy xulosa',
                details: lifetime,
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Per-day list (reverse chronological)
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: dailyList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = dailyList[index];
            final date = entry['date'] as DateTime;
            final d = _formatDate(date);
            final p = entry['production'] as int;
            final s = entry['sales'] as int;
            final b = entry['broken'] as int;
            final l = entry['large'] as int;
            final r = entry['revenue'] as double;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(d),
                subtitle: Text(
                  'Yig\'ilgan: $p | Sotilgan: $s | Siniq: $b | Katta: $l | Daromad: ${r.toStringAsFixed(0)} som',
                ),
                onTap: () {
                  _showDailyDetailDialog(
                    title: 'Kunlik hisobot ($d)',
                    details: entry,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _lifetimeAggregates(Egg egg) {
    final totalProduction = egg.production.fold<int>(
      0,
      (s, p) => s + p.trayCount,
    );
    final totalSales = egg.sales.fold<int>(0, (s, p) => s + p.trayCount);
    final totalBroken = egg.brokenEggs.fold<int>(0, (s, p) => s + p.trayCount);
    final totalLarge = egg.largeEggs.fold<int>(0, (s, p) => s + p.trayCount);
    final totalRevenue = egg.sales.fold<double>(
      0.0,
      (s, p) => s + (p.trayCount * p.pricePerTray),
    );

    return {
      'production': totalProduction,
      'sales': totalSales,
      'broken': totalBroken,
      'large': totalLarge,
      'revenue': totalRevenue,
    };
  }

  List<Map<String, dynamic>> _buildPerDayAggregates(Egg egg) {
    final Map<DateTime, Map<String, dynamic>> perDay = {};

    void addTo(DateTime date, String key, num value) {
      final d = DateTime(date.year, date.month, date.day);
      perDay[d] ??= {
        'date': d,
        'production': 0,
        'sales': 0,
        'broken': 0,
        'large': 0,
        'revenue': 0.0,
      };
      final map = perDay[d]!;
      if (key == 'revenue') {
        map[key] = (map[key] as double) + value.toDouble();
      } else {
        map[key] = (map[key] as int) + value.toInt();
      }
    }

    for (final p in egg.production) {
      addTo(p.date, 'production', p.trayCount);
    }
    for (final s in egg.sales) {
      addTo(s.date, 'sales', s.trayCount);
      addTo(s.date, 'revenue', s.trayCount * s.pricePerTray);
    }
    for (final b in egg.brokenEggs) {
      addTo(b.date, 'broken', b.trayCount);
    }
    for (final l in egg.largeEggs) {
      addTo(l.date, 'large', l.trayCount);
    }

    final list = perDay.values.toList();
    list.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return list;
  }

  void _showDailyDetailDialog({
    required String title,
    required Map<String, dynamic> details,
  }) {
    final production = details['production'] as int? ?? 0;
    final sales = details['sales'] as int? ?? 0;
    final broken = details['broken'] as int? ?? 0;
    final large = details['large'] as int? ?? 0;
    final revenue = details['revenue'] as double? ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yig\'ilgan tuxum: $production fletka'),
            Text('Sotilgan tuxum: $sales fletka'),
            Text('Siniq tuxum: $broken fletka'),
            Text('Katta tuxum: $large fletka'),
            const SizedBox(height: 8),
            Text('Daromad: ${revenue.toStringAsFixed(0)} som'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
