import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
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

  // Kok rang palettasi
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color blueDark = Color(0xFF1565C0);
  static const Color blueLight = Color(0xFF42A5F5);
  static const Color blueAccent = Color(0xFF448AFF);
  static const Color blueSurface = Color(0xFFE3F2FD);
  static const Color blueBackground = Color(0xFFF5F9FF);

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
      backgroundColor: blueBackground,
      appBar: AppBar(
        title: Text(
          'Kengaytirilgan Hisobotlar',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 2,
        shadowColor: primaryBlue.withOpacity(0.3),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () {
              final farmProvider = Provider.of<FarmProvider>(
                context,
                listen: false,
              );
              farmProvider.refreshData();
              _showSnackBar('Ma\'lumotlar yangilandi', Colors.green);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.calendar_today_outlined, size: 20),
              text: 'Oylik',
            ),
            Tab(
              icon: Icon(Icons.trending_up_outlined, size: 20),
              text: 'Yillik',
            ),
            Tab(
              icon: Icon(Icons.analytics_outlined, size: 20),
              text: 'Tahlillar',
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [blueBackground, blueBackground, Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMonthlyReportTab(),
            _buildYearlyReportTab(),
            _buildAnalyticsTab(),
          ],
        ),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sarlavha
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Oylik Hisobot',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: blueDark,
                    ),
                  ),
                ),

                // Oy tanlovi
                _buildMonthSelector(),
                const SizedBox(height: 20),

                // Real-time statistikalar
                _buildRealTimeStats(farmProvider, farm),
                const SizedBox(height: 20),

                // Samaradorlik ko'rsatkichlari
                _buildPerformanceIndicators(farm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: blueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blueDark,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: Icon(Icons.chevron_left, color: primaryBlue),
                  iconSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(Icons.chevron_right, color: primaryBlue),
                  iconSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeStats(FarmProvider farmProvider, dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sync, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Real-time Ma\'lumotlar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
              const Spacer(),
              if (farmProvider.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(primaryBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
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
                '${_formatCurrency(_getMonthlyRevenue(farm))}',
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
                '${_formatCurrency(_getTotalDebt(farm))}',
                Icons.account_balance_wallet,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Samaradorlik Ko\'rsatkichlari',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressIndicator(
            'Tovuq boshiga tuxum',
            _getEggPerChicken(farm),
            30,
            'fletka/oy',
            Colors.orange,
          ),
          _buildProgressIndicator(
            'O\'lim darajasi',
            _getDeathRate(farm),
            10,
            '%',
            Colors.red,
          ),
          _buildProgressIndicator(
            'Foydalilik',
            _getProfitability(farm),
            100,
            '%',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyReportTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Sarlavha
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Yillik Hisobot',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: blueDark,
                  ),
                ),
              ),

              // Yil tanlovi
              _buildYearSelector(),
              const SizedBox(height: 20),

              // Yillik xulosalar
              _buildYearlySummary(farm),
              const SizedBox(height: 20),

              // Oylik taqsimot
              _buildMonthlyBreakdown(farm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: blueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDate.year} yil',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blueDark,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _changeYear(-1),
                  icon: Icon(Icons.chevron_left, color: primaryBlue),
                  iconSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _changeYear(1),
                  icon: Icon(Icons.chevron_right, color: primaryBlue),
                  iconSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySummary(dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.summarize, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Yillik Xulosalar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildYearlyStatColumn(
                'Jami Tuxum',
                '${_getYearlyEggProduction(farm)}',
                Icons.egg_outlined,
                Colors.orange,
              ),
              _buildYearlyStatColumn(
                'Jami Daromad',
                _formatCurrency(_getYearlyRevenue(farm)),
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
    );
  }

  Widget _buildMonthlyBreakdown(dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Oylik Taqsimot',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: blueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_graph, color: primaryBlue, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Oylik Grafik Tahlili',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blueDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Har oyning tuxum ishlab chiqarish va daromad ko\'rsatkichlari',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Sarlavha
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Chuqur Tahlillar',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: blueDark,
                  ),
                ),
              ),

              // Trend tahlili
              _buildTrendAnalysis(farm),
              const SizedBox(height: 20),

              // Bashoratlar
              _buildPredictions(farm),
              const SizedBox(height: 20),

              // Eksport imkoniyatlari
              _buildExportOptions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendAnalysis(dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Trend Tahlili',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
    );
  }

  Widget _buildPredictions(dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Keyingi Oy Bashoratlari',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                _formatCurrency(_predictNextMonthRevenue(farm)),
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Hisobotlarni Yuklab Olish',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green[700]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // child: Material(
                  //   color: Colors.transparent,
                  //   child: InkWell(
                  //     borderRadius: BorderRadius.circular(12),
                  //     onPressed: _exportToExcel,
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(Icons.table_chart, color: Colors.white, size: 20),
                  //         const SizedBox(width: 8),
                  //         Text(
                  //           'Excel ga Eksport',
                  //           style: GoogleFonts.inter(
                  //             color: Colors.white,
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.red[700]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _exportToPDF,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PDF ga Eksport',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget builders
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    String title,
    double value,
    double max,
    String unit,
    Color color,
  ) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyStatColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.blueGrey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendItem(String title, String trend, IconData icon) {
    final isPositive = trend.contains('+') || trend.contains('↑');
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: blueDark,
              ),
            ),
          ),
          Text(
            trend,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods for calculations (REAL ISHLAYDI)
  int _getMonthlyEggProduction(dynamic farm) {
    if (farm?.egg?.production == null) return 0;
    return farm.egg.production
        .where(
          (p) =>
              p.date.year == _selectedDate.year &&
              p.date.month == _selectedDate.month,
        )
        .fold(0, (sum, p) => sum + (p.trayCount ?? 0));
  }

  int _getMonthlyEggSales(dynamic farm) {
    if (farm?.egg?.sales == null) return 0;
    return farm.egg.sales
        .where(
          (s) =>
              s.date.year == _selectedDate.year &&
              s.date.month == _selectedDate.month,
        )
        .fold(0, (sum, s) => sum + (s.trayCount ?? 0));
  }

  double _getMonthlyRevenue(dynamic farm) {
    if (farm?.egg?.sales == null) return 0.0;
    return farm.egg.sales
        .where(
          (s) =>
              s.date.year == _selectedDate.year &&
              s.date.month == _selectedDate.month,
        )
        .fold(
          0.0,
          (sum, s) => sum + ((s.trayCount ?? 0) * (s.pricePerTray ?? 0)),
        );
  }

  int _getActiveCustomersCount(dynamic farm) {
    if (farm?.customers == null) return 0;
    return farm.customers
        .where((c) => c.name != null && !c.name!.startsWith('QARZ:'))
        .length;
  }

  double _getTotalDebt(dynamic farm) {
    if (farm?.customers == null) return 0.0;
    return farm.customers.fold(0.0, (sum, c) => sum + (c.totalDebt ?? 0));
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
        .fold(0, (sum, d) => sum + (d.count ?? 0));

    final totalChickens = farm.chicken.totalCount ?? 1;
    return totalChickens > 0 ? (monthlyDeaths / totalChickens) * 100 : 0.0;
  }

  double _getProfitability(dynamic farm) {
    final revenue = _getMonthlyRevenue(farm);
    final estimatedCosts = _getMonthlyEggProduction(farm) * 5000;
    final profit = revenue - estimatedCosts;
    return revenue > 0 ? (profit / revenue) * 100 : 0.0;
  }

  // Yearly calculations
  int _getYearlyEggProduction(dynamic farm) {
    if (farm?.egg?.production == null) return 0;
    return farm.egg.production
        .where((p) => p.date.year == _selectedDate.year)
        .fold(0, (sum, p) => sum + (p.trayCount ?? 0));
  }

  double _getYearlyRevenue(dynamic farm) {
    if (farm?.egg?.sales == null) return 0.0;
    return farm.egg.sales
        .where((s) => s.date.year == _selectedDate.year)
        .fold(
          0.0,
          (sum, s) => sum + ((s.trayCount ?? 0) * (s.pricePerTray ?? 0)),
        );
  }

  String _getBestMonth(dynamic farm) {
    if (farm?.egg?.production == null) return 'Noma\'lum';

    final monthlyData = <int, int>{};
    for (final production in farm.egg.production) {
      if (production.date.year == _selectedDate.year) {
        final month = production.date.month;
        final currentValue = monthlyData[month] ?? 0;
        monthlyData[month] =
            currentValue + ((production.trayCount ?? 0) as int);
      }
    }

    if (monthlyData.isEmpty) return 'Noma\'lum';

    final bestMonth = monthlyData.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return DateFormat(
      'MMMM',
    ).format(DateTime(_selectedDate.year, bestMonth.key));
  }

  // Trend calculations
  String _getEggProductionTrend(dynamic farm) {
    final thisMonth = _getMonthlyEggProduction(farm);
    final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    int prevMonthProduction = 0;

    if (farm?.egg?.production != null) {
      prevMonthProduction = farm.egg.production
          .where(
            (p) =>
                p.date.year == prevDate.year && p.date.month == prevDate.month,
          )
          .fold(0, (sum, p) => sum + (p.trayCount ?? 0));
    }

    if (prevMonthProduction == 0)
      return thisMonth > 0 ? '+Yangi ✨' : 'Ma\'lumot yo\'q';

    final change = thisMonth - prevMonthProduction;
    final percentage = (change / prevMonthProduction * 100).abs();

    if (change > 0) return '+${percentage.toStringAsFixed(0)}% ↑';
    if (change < 0) return '-${percentage.toStringAsFixed(0)}% ↓';
    return '0% =';
  }

  String _getRevenueTrend(dynamic farm) {
    final thisMonth = _getMonthlyRevenue(farm);
    final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    double prevMonthRevenue = 0.0;

    if (farm?.egg?.sales != null) {
      prevMonthRevenue = farm.egg.sales
          .where(
            (s) =>
                s.date.year == prevDate.year && s.date.month == prevDate.month,
          )
          .fold(
            0.0,
            (sum, s) =>
                sum +
                ((s.trayCount ?? 0).toDouble() *
                    (s.pricePerTray ?? 0).toDouble()),
          );
    }

    if (prevMonthRevenue == 0)
      return thisMonth > 0 ? '+Yangi ✨' : 'Ma\'lumot yo\'q';

    final change = thisMonth - prevMonthRevenue;
    final percentage = (change / prevMonthRevenue * 100).abs();

    if (change > 0) return '+${percentage.toStringAsFixed(0)}% ↑';
    if (change < 0) return '-${percentage.toStringAsFixed(0)}% ↓';
    return '0% =';
  }

  String _getCustomerTrend(dynamic farm) {
    final count = _getActiveCustomersCount(farm);
    return count == 0 ? 'Mijoz yo\'q' : '$count mijoz';
  }

  // Predictions
  int _predictNextMonthEggs(dynamic farm) {
    final currentProduction = _getMonthlyEggProduction(farm);
    final daysInMonth = DateTime.now().day;
    final dailyAverage = daysInMonth > 0 ? currentProduction / daysInMonth : 0;
    return (dailyAverage * 30).round();
  }

  double _predictNextMonthRevenue(dynamic farm) {
    final currentRevenue = _getMonthlyRevenue(farm);
    final daysInMonth = DateTime.now().day;
    final dailyAverage = daysInMonth > 0 ? currentRevenue / daysInMonth : 0;
    return dailyAverage * 30;
  }

  // Utility methods
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M so\'m';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k so\'m';
    }
    return '${amount.toStringAsFixed(0)} so\'m';
  }

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

  void _exportToExcel() {
    _showSnackBar('Excel eksport qilish tez orada qo\'shiladi', Colors.green);
  }

  void _exportToPDF() {
    _showSnackBar('PDF eksport qilish tez orada qo\'shiladi', Colors.blue);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
