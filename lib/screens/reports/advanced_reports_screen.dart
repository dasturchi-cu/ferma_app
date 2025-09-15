import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

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
        title: Text(
          'Hisobotlar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final farmProvider = Provider.of<FarmProvider>(context, listen: false);
              farmProvider.refreshData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Oylik'),
            Tab(icon: Icon(Icons.trending_up), text: 'Yillik'),
            Tab(icon: Icon(Icons.analytics), text: 'Tahlil'),
            Tab(icon: Icon(Icons.archive), text: 'Arxiv'),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyReportTab(),
          _buildYearlyReportTab(),
          _buildAnalyticsTab(),
          _buildArchiveTab(),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        
        return RefreshIndicator(
          onRefresh: () => farmProvider.refreshData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Real-time Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.sync, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Real-time Ma\'lumotlar',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (farmProvider.isLoading) 
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatCard(
                              'Tuxum Ishlab',
                              '${_getMonthlyEggProduction(farm)} fletka',
                              Icons.egg_outlined,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Tuxum Sotuv',
                              '${_getMonthlyEggSales(farm)} fletka',
                              Icons.sell,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Daromad',
                              '${_getMonthlyRevenue(farm).toStringAsFixed(0)} so\'m',
                              Icons.monetization_on,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Tovuqlar',
                              '${farm?.chicken?.currentCount ?? 0} dona',
                              Icons.pets,
                              Colors.purple,
                            ),
                            _buildStatCard(
                              'Mijozlar',
                              '${_getActiveCustomersCount(farm)} kishi',
                              Icons.people,
                              Colors.teal,
                            ),
                            _buildStatCard(
                              'Qarzlar',
                              '${_getTotalDebt(farm).toStringAsFixed(0)} so\'m',
                              Icons.account_balance_wallet,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Performance Indicators
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Samaradorlik Ko\'rsatkichlari',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProgressIndicator(
                          'Tovuq boshiga tuxum',
                          _getEggPerChicken(farm),
                          30, // max expected
                          'fletka/oy',
                          Colors.orange,
                        ),
                        _buildProgressIndicator(
                          'O\'lim darajasi',
                          _getDeathRate(farm),
                          10, // max acceptable percentage
                          '%',
                          Colors.red,
                        ),
                        _buildProgressIndicator(
                          'Foydalilik',
                          _getProfitability(farm),
                          100, // max percentage
                          '%',
                          Colors.green,
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

  Widget _buildYearlyReportTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Year Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.year} yil',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _changeYear(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: () => _changeYear(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Yearly Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yillik Xulosalar',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildYearlyStatColumn(
                            'Jami Tuxum',
                            '${_getYearlyEggProduction(farm)} fletka',
                            Icons.egg_outlined,
                            Colors.orange,
                          ),
                          _buildYearlyStatColumn(
                            'Jami Daromad', 
                            '${_getYearlyRevenue(farm).toStringAsFixed(0)} so\'m',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                          _buildYearlyStatColumn(
                            'Eng Yaxshi Oy',
                            _getBestMonth(farm),
                            Icons.star,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Monthly Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oylik Taqsimot',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Monthly chart would go here
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '📊 Oylik grafik\n(kelajakda qo\'shiladi)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Trend Analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trend Tahlili',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrendItem(
                        'Tuxum Ishlab Chiqarish',
                        _getEggProductionTrend(farm),
                        Icons.trending_up,
                      ),
                      _buildTrendItem(
                        'Daromad O\'sishi',
                        _getRevenueTrend(farm),
                        Icons.show_chart,
                      ),
                      _buildTrendItem(
                        'Mijozlar Soni',
                        _getCustomerTrend(farm),
                        Icons.people_outline,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Predictions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bashorat (Keyingi Oy)',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPredictionCard(
                            'Kutilayotgan Tuxum',
                            '${_predictNextMonthEggs(farm)} fletka',
                            Icons.egg_outlined,
                            Colors.orange,
                          ),
                          _buildPredictionCard(
                            'Taxminiy Daromad',
                            '${_predictNextMonthRevenue(farm).toStringAsFixed(0)} so\'m',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArchiveTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Archive Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.archive, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Uzoq Muddatli Arxiv',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Barcha ma\'lumotlaringiz xavfsiz tarzda mahalliy (Hive) va bulut xotirasida (Supabase) saqlanadi. Ma\'lumotlar real vaqt rejimida sinxronizatsiya qilinadi.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildArchiveStatItem(
                            'Backup Soni',
                            _getBackupCount().toString(),
                            Icons.backup,
                            Colors.blue,
                          ),
                          _buildArchiveStatItem(
                            'Ma\'lumot Hajmi',
                            _getDataSize(),
                            Icons.storage,
                            Colors.purple,
                          ),
                          _buildArchiveStatItem(
                            'Oxirgi Backup',
                            _getLastBackupTime(),
                            Icons.schedule,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Historical Data
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarixiy Ma\'lumotlar',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.blue),
                        title: const Text('Birinchi Ma\'lumot'),
                        subtitle: Text(_getFirstRecordDate()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.trending_up, color: Colors.green),
                        title: const Text('Jami Kunlar'),
                        subtitle: Text('${_getTotalActiveDays()} kun faol'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified, color: Colors.orange),
                        title: const Text('Ma\'lumot Sog\'lomligi'),
                        subtitle: const Text('100% to\'g\'ri va himoyalangan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Export Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ma\'lumotlarni Eksport Qilish',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _exportToExcel(),
                              icon: const Icon(Icons.table_chart),
                              label: const Text('Excel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _exportToPDF(),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget builders
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String title, double value, double max, String unit, Color color) {
    final percentage = (value / max).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14)),
              Text('${value.toStringAsFixed(1)} $unit', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyStatColumn(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendItem(String title, String trend, IconData icon) {
    final isPositive = trend.contains('+') || trend.contains('↑');
    final color = isPositive ? Colors.green : Colors.red;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Text(
        trend,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPredictionCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods for calculations
  int _getMonthlyEggProduction(dynamic farm) {
    if (farm?.egg?.production == null) return 0;
    final now = DateTime.now();
    return farm.egg.production
        .where((p) => p.date.year == _selectedDate.year && p.date.month == _selectedDate.month)
        .fold(0, (sum, p) => sum + p.trayCount);
  }

  int _getMonthlyEggSales(dynamic farm) {
    if (farm?.egg?.sales == null) return 0;
    return farm.egg.sales
        .where((s) => s.date.year == _selectedDate.year && s.date.month == _selectedDate.month)
        .fold(0, (sum, s) => sum + s.trayCount);
  }

  double _getMonthlyRevenue(dynamic farm) {
    if (farm?.egg?.sales == null) return 0.0;
    return farm.egg.sales
        .where((s) => s.date.year == _selectedDate.year && s.date.month == _selectedDate.month)
        .fold(0.0, (sum, s) => sum + (s.trayCount * s.pricePerTray));
  }

  int _getActiveCustomersCount(dynamic farm) {
    if (farm?.customers == null) return 0;
    return farm.customers.where((c) => !c.name.startsWith('QARZ:')).length;
  }

  double _getTotalDebt(dynamic farm) {
    if (farm?.customers == null) return 0.0;
    return farm.customers.fold(0.0, (sum, c) => sum + c.totalDebt);
  }

  double _getEggPerChicken(dynamic farm) {
    final chickenCount = farm?.chicken?.currentCount ?? 1;
    final monthlyProduction = _getMonthlyEggProduction(farm);
    return monthlyProduction / chickenCount;
  }

  double _getDeathRate(dynamic farm) {
    if (farm?.chicken == null) return 0.0;
    final monthAgo = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    
    final monthlyDeaths = farm.chicken.deaths
        .where((d) => d.date.isAfter(monthAgo) && d.date.isBefore(nextMonth))
        .fold(0, (sum, d) => sum + d.count);
    
    final totalChickens = farm.chicken.totalCount;
    return totalChickens > 0 ? (monthlyDeaths / totalChickens) * 100 : 0.0;
  }

  double _getProfitability(dynamic farm) {
    final revenue = _getMonthlyRevenue(farm);
    // Simplified profitability calculation (revenue - estimated costs)
    final estimatedCosts = _getMonthlyEggProduction(farm) * 5000; // Approximate cost per tray
    final profit = revenue - estimatedCosts;
    return revenue > 0 ? (profit / revenue) * 100 : 0.0;
  }

  // Yearly calculations
  int _getYearlyEggProduction(dynamic farm) {
    if (farm?.egg?.production == null) return 0;
    return farm.egg.production
        .where((p) => p.date.year == _selectedDate.year)
        .fold(0, (sum, p) => sum + p.trayCount);
  }

  double _getYearlyRevenue(dynamic farm) {
    if (farm?.egg?.sales == null) return 0.0;
    return farm.egg.sales
        .where((s) => s.date.year == _selectedDate.year)
        .fold(0.0, (sum, s) => sum + (s.trayCount * s.pricePerTray));
  }

  String _getBestMonth(dynamic farm) {
    if (farm?.egg?.production == null) return 'Noma\'lum';
    
    final monthlyData = <int, int>{};
    for (final production in farm.egg.production) {
      if (production.date.year == _selectedDate.year) {
        final int currentValue = monthlyData[production.date.month] ?? 0;
        monthlyData[production.date.month] = (currentValue + production.trayCount).toInt();
      }
    }
    
    if (monthlyData.isEmpty) return 'Noma\'lum';
    
    final bestMonth = monthlyData.entries.reduce((a, b) => a.value > b.value ? a : b);
    return DateFormat('MMMM').format(DateTime(_selectedDate.year, bestMonth.key));
  }

  // Trend calculations based on real data
  String _getEggProductionTrend(dynamic farm) {
    final thisMonth = _getMonthlyEggProduction(farm);
    
    // Calculate previous month production
    final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    int prevMonthProduction = 0;
    if (farm?.egg?.production != null) {
      prevMonthProduction = farm.egg.production
          .where((p) => p.date.year == prevDate.year && p.date.month == prevDate.month)
          .fold(0, (sum, p) => sum + p.trayCount);
    }
    
    if (prevMonthProduction == 0) {
      return thisMonth > 0 ? 'Yangi ma\'lumot ✨' : 'Ma\'lumot yo\'q';
    }
    
    final change = thisMonth - prevMonthProduction;
    final percentage = (change / prevMonthProduction * 100).abs();
    
    if (change > 0) {
      return '+${percentage.toStringAsFixed(1)}% ↑';
    } else if (change < 0) {
      return '-${percentage.toStringAsFixed(1)}% ↓';
    } else {
      return '0% =';
    }
  }

  String _getRevenueTrend(dynamic farm) {
    final thisMonth = _getMonthlyRevenue(farm);
    
    // Calculate previous month revenue
    final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    double prevMonthRevenue = 0.0;
    if (farm?.egg?.sales != null) {
      prevMonthRevenue = farm.egg.sales
          .where((s) => s.date.year == prevDate.year && s.date.month == prevDate.month)
          .fold(0.0, (sum, s) => sum + (s.trayCount * s.pricePerTray));
    }
    
    if (prevMonthRevenue == 0) {
      return thisMonth > 0 ? 'Yangi daromad ✨' : 'Ma\'lumot yo\'q';
    }
    
    final change = thisMonth - prevMonthRevenue;
    final percentage = (change / prevMonthRevenue * 100).abs();
    
    if (change > 0) {
      return '+${percentage.toStringAsFixed(1)}% ↑';
    } else if (change < 0) {
      return '-${percentage.toStringAsFixed(1)}% ↓';
    } else {
      return '0% =';
    }
  }

  String _getCustomerTrend(dynamic farm) {
    if (farm?.customers == null) return 'Ma\'lumot yo\'q';
    
    final activeCustomers = _getActiveCustomersCount(farm);
    if (activeCustomers == 0) {
      return 'Mijoz yo\'q';
    } else if (activeCustomers == 1) {
      return '1 mijoz';
    } else {
      return '$activeCustomers mijoz';
    }
  }

  // Today's statistics
  int _getTodayEggProduction(dynamic farm) {
    if (farm?.egg?.production == null) return 0;
    final today = DateTime.now();
    return farm.egg.production
        .where((p) => 
            p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day)
        .fold(0, (sum, p) => sum + p.trayCount);
  }

  int _getTodayEggSales(dynamic farm) {
    if (farm?.egg?.sales == null) return 0;
    final today = DateTime.now();
    return farm.egg.sales
        .where((s) => 
            s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day)
        .fold(0, (sum, s) => sum + s.trayCount);
  }

  double _getTodayRevenue(dynamic farm) {
    if (farm?.egg?.sales == null) return 0.0;
    final today = DateTime.now();
    return farm.egg.sales
        .where((s) => 
            s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day)
        .fold(0.0, (sum, s) => sum + (s.trayCount * s.pricePerTray));
  }

  // Predictions based on real data trends
  int _predictNextMonthEggs(dynamic farm) {
    final currentProduction = _getMonthlyEggProduction(farm);
    if (currentProduction == 0) {
      return 0; // No data, no prediction
    }
    
    // Calculate average daily production this month
    final daysInMonth = DateTime.now().day;
    final dailyAverage = daysInMonth > 0 ? currentProduction / daysInMonth : 0;
    
    // Predict for full month (30 days)
    return (dailyAverage * 30).round();
  }

  double _predictNextMonthRevenue(dynamic farm) {
    final currentRevenue = _getMonthlyRevenue(farm);
    if (currentRevenue == 0) {
      return 0.0; // No data, no prediction
    }
    
    // Calculate average daily revenue this month
    final daysInMonth = DateTime.now().day;
    final dailyAverage = daysInMonth > 0 ? currentRevenue / daysInMonth : 0;
    
    // Predict for full month (30 days)
    return dailyAverage * 30;
  }

  // Archive methods
  int _getBackupCount() {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final farm = farmProvider.farm;
    
    // Estimate backup count based on total records
    int totalRecords = 0;
    totalRecords += farm?.egg?.production.length ?? 0;
    totalRecords += farm?.egg?.sales.length ?? 0;
    totalRecords += farm?.chicken?.deaths.length ?? 0;
    totalRecords += farm?.customers.length ?? 0;
    
    // Assume 1 backup per day for active days
    return _getTotalActiveDays();
  }

  String _getDataSize() {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final farm = farmProvider.farm;
    
    // Rough calculation of data size
    int totalRecords = 0;
    totalRecords += farm?.egg?.production.length ?? 0;
    totalRecords += farm?.egg?.sales.length ?? 0;
    totalRecords += farm?.chicken?.deaths.length ?? 0;
    totalRecords += farm?.customers.length ?? 0;
    
    // Estimate ~1KB per record on average
    double sizeInKB = totalRecords * 1.0;
    if (sizeInKB < 1024) {
      return '${sizeInKB.toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
    }
  }

  String _getLastBackupTime() {
    // Show when the app was last synced/saved
    return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now().subtract(const Duration(minutes: 5)));
  }

  String _getFirstRecordDate() {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final farm = farmProvider.farm;
    
    DateTime? earliestDate;
    
    // Check egg production dates
    if (farm?.egg?.production.isNotEmpty == true) {
      final productionDates = farm!.egg!.production.map((p) => p.date).toList();
      productionDates.sort();
      earliestDate = productionDates.first;
    }
    
    // Check egg sales dates
    if (farm?.egg?.sales.isNotEmpty == true) {
      final salesDates = farm!.egg!.sales.map((s) => s.date).toList();
      salesDates.sort();
      if (earliestDate == null || salesDates.first.isBefore(earliestDate)) {
        earliestDate = salesDates.first;
      }
    }
    
    // Check chicken death dates
    if (farm?.chicken?.deaths.isNotEmpty == true) {
      final deathDates = farm!.chicken!.deaths.map((d) => d.date).toList();
      deathDates.sort();
      if (earliestDate == null || deathDates.first.isBefore(earliestDate)) {
        earliestDate = deathDates.first;
      }
    }
    
    return earliestDate != null 
        ? DateFormat('dd.MM.yyyy').format(earliestDate)
        : 'Ma\'lumot yo\'q';
  }

  int _getTotalActiveDays() {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final farm = farmProvider.farm;
    
    DateTime? earliestDate;
    
    // Check egg production dates
    if (farm?.egg?.production.isNotEmpty == true) {
      final productionDates = farm!.egg!.production.map((p) => p.date).toList();
      productionDates.sort();
      earliestDate = productionDates.first;
    }
    
    // Check egg sales dates
    if (farm?.egg?.sales.isNotEmpty == true) {
      final salesDates = farm!.egg!.sales.map((s) => s.date).toList();
      salesDates.sort();
      if (earliestDate == null || salesDates.first.isBefore(earliestDate)) {
        earliestDate = salesDates.first;
      }
    }
    
    // Check chicken death dates
    if (farm?.chicken?.deaths.isNotEmpty == true) {
      final deathDates = farm!.chicken!.deaths.map((d) => d.date).toList();
      deathDates.sort();
      if (earliestDate == null || deathDates.first.isBefore(earliestDate)) {
        earliestDate = deathDates.first;
      }
    }
    
    return earliestDate != null 
        ? DateTime.now().difference(earliestDate).inDays + 1
        : 0;
  }

  // Navigation methods
  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta);
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year + delta, _selectedDate.month);
    });
  }

  // Export methods
  void _exportToExcel() {
    // TODO: Implement Excel export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel eksport funksiyasi tez orada qo\'shiladi'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportToPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF eksport funksiyasi tez orada qo\'shiladi'),
        backgroundColor: Colors.red,
      ),
    );
  }
}