import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../models/chicken.dart';
import '../../utils/app_theme.dart';
import '../../utils/modern_theme.dart';
import '../../widgets/modern_components.dart';
import 'package:google_fonts/google_fonts.dart';

class ChickenManagementScreen extends StatefulWidget {
  const ChickenManagementScreen({super.key});

  @override
  State<ChickenManagementScreen> createState() =>
      _ChickenManagementScreenState();
}

class _ChickenManagementScreenState extends State<ChickenManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _addChickenController = TextEditingController();
  final _deathCountController = TextEditingController();
  final _deathReasonController = TextEditingController();

  // Yangi kok rang palettasi
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
    _addChickenController.dispose();
    _deathCountController.dispose();
    _deathReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blueBackground,
      appBar: AppBar(
        title: Text(
          'Tovuq Boshqaruvi',
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.add_circle_outline, size: 20),
              text: 'Qo\'shish',
            ),
            Tab(
              icon: Icon(Icons.warning_amber_outlined, size: 20),
              text: 'O\'limlar',
            ),
            Tab(
              icon: Icon(Icons.analytics_outlined, size: 20),
              text: 'Hisobot',
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
            _buildAddChickenTab(),
            _buildDeathManagementTab(),
            _buildReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddChickenTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final chicken = farm?.chicken;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sarlavha
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Tovuqlarni Boshqarish',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: blueDark,
                  ),
                ),
              ),

              // Joriy statistikalar
              _buildStatsCard(chicken),
              const SizedBox(height: 24),

              // Yangi tovuq qo'shish formasi
              _buildAddChickenForm(farmProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(dynamic chicken) {
    final totalChickens = chicken?.currentCount ?? 0;
    final todayDeaths = _getTodayDeaths(chicken);
    final healthy = totalChickens - todayDeaths;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Joriy Statistikalar',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Jami Tovuqlar',
                '$totalChickens',
                Icons.pets,
                Colors.white,
              ),
              _buildStatItem(
                'Bugungi O\'limlar',
                '$todayDeaths',
                Icons.warning,
                Colors.amber[100]!,
              ),
              _buildStatItem(
                'Sog\'lom',
                '$healthy',
                Icons.favorite,
                Colors.green[100]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAddChickenForm(FarmProvider farmProvider) {
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
              Icon(Icons.add_circle, color: primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                'Yangi Tovuqlar Qo\'shish',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _QuantityStepper(
            controller: _addChickenController,
            label: 'Tovuqlar soni',
            min: 1,
            max: 100000,
            primaryColor: primaryBlue,
          ),
          const SizedBox(height: 16),
          _QuickPresets(
            values: const [10, 25, 50, 100],
            onTap: (v) {
              _addChickenController.text = v.toString();
              setState(() {});
            },
            primaryColor: primaryBlue,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, blueDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: farmProvider.isLoading
                    ? null
                    : () => _addChickens(farmProvider),
                child: Center(
                  child: farmProvider.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tovuqlar Qo\'shish',
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
    );
  }

  Widget _buildDeathManagementTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final chicken = farmProvider.farm?.chicken;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sarlavha
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'O\'limlarni Boshqarish',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: blueDark,
                  ),
                ),
              ),

              // O'lim hisoboti formasi
              _buildDeathReportForm(farmProvider),
              const SizedBox(height: 24),

              // So'nggi o'limlar ro'yxati
              if (chicken?.deaths.isNotEmpty == true)
                _buildRecentDeathsList(chicken),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeathReportForm(FarmProvider farmProvider) {
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
              Icon(Icons.report_problem, color: Colors.orange[700], size: 22),
              const SizedBox(width: 8),
              Text(
                'O\'lim Hisoboti',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _QuantityStepper(
            controller: _deathCountController,
            label: 'O\'lgan tovuqlar soni',
            min: 1,
            max: 100000,
            primaryColor: Colors.orange[700]!,
          ),
          const SizedBox(height: 16),
          _QuickPresets(
            values: const [1, 2, 5, 10],
            onTap: (v) {
              _deathCountController.text = v.toString();
              setState(() {});
            },
            primaryColor: Colors.orange[700]!,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: blueSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: blueLight.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _deathReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'O\'lim sababi (ixtiyoriy)',
                labelStyle: GoogleFonts.inter(color: Colors.blueGrey),
                hintText: 'Kasallik, jarohat, tabiiy o\'lim...',
                hintStyle: GoogleFonts.inter(color: Colors.blueGrey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.inter(color: blueDark),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[700]!, Colors.red[700]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: farmProvider.isLoading
                    ? null
                    : () => _reportDeath(farmProvider),
                child: Center(
                  child: farmProvider.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.report, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'O\'lim Hisobotini Saqlash',
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
    );
  }

  Widget _buildRecentDeathsList(dynamic chicken) {
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
              Icon(Icons.history, color: primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                'So\'nggi O\'limlar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...chicken.deaths
              .take(10)
              .map(
                (death) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning,
                          color: Colors.red[700],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${death.count} dona tovuq',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.red[800],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(death.date),
                              style: GoogleFonts.inter(
                                color: Colors.blueGrey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (death.note?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                death.note!,
                                style: GoogleFonts.inter(
                                  color: Colors.blueGrey[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final chicken = farmProvider.farm?.chicken;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Sarlavha
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Statistik Hisobotlar',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: blueDark,
                  ),
                ),
              ),

              // Haftalik hisobot
              _buildReportCard('Haftalik Hisobot', Icons.weekend, [
                _buildReportItem(
                  'Jami Tovuqlar',
                  '${chicken?.currentCount ?? 0}',
                ),
                _buildReportItem(
                  'Haftalik O\'limlar',
                  '${_getWeeklyDeaths(chicken)}',
                ),
                _buildReportItem(
                  'O\'lim Darajasi',
                  '${_getDeathRate(chicken).toStringAsFixed(1)}%',
                ),
              ]),
              const SizedBox(height: 20),

              // Oylik hisobot
              _buildReportCard('Oylik Hisobot', Icons.calendar_today, [
                _buildReportItem(
                  'Oylik O\'limlar',
                  '${_getMonthlyDeaths(chicken)}',
                ),
                _buildReportItem(
                  'Kunlik O\'rtacha',
                  '${(_getMonthlyDeaths(chicken) / 30).toStringAsFixed(1)}',
                ),
                _buildReportItem(
                  'Sog\'lom Foiz',
                  '${(100 - _getDeathRate(chicken)).toStringAsFixed(1)}%',
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard(String title, IconData icon, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods (strongly typed to avoid runtime type errors)
  int _getTodayDeaths(Chicken? chicken) {
    final deaths = chicken?.deaths ?? const <ChickenDeath>[];
    final today = DateTime.now();
    return deaths
        .where(
          (ChickenDeath death) =>
              death.date.year == today.year &&
              death.date.month == today.month &&
              death.date.day == today.day,
        )
        .fold<int>(0, (sum, death) => sum + death.count);
  }

  int _getWeeklyDeaths(Chicken? chicken) {
    final deaths = chicken?.deaths ?? const <ChickenDeath>[];
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return deaths
        .where((ChickenDeath death) => death.date.isAfter(weekAgo))
        .fold<int>(0, (sum, death) => sum + death.count);
  }

  int _getMonthlyDeaths(Chicken? chicken) {
    final deaths = chicken?.deaths ?? const <ChickenDeath>[];
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return deaths
        .where((ChickenDeath death) => death.date.isAfter(monthAgo))
        .fold<int>(0, (sum, death) => sum + death.count);
  }

  double _getDeathRate(Chicken? chicken) {
    final total = chicken?.totalCount ?? 0;
    if (total == 0) return 0.0;
    final monthlyDeaths = _getMonthlyDeaths(chicken);
    return (monthlyDeaths / total) * 100;
  }

  Future<void> _addChickens(FarmProvider farmProvider) async {
    final countText = _addChickenController.text.trim();
    if (countText.isEmpty) {
      _showSnackBar('Tovuqlar sonini kiriting', Colors.orange);
      return;
    }

    final count = int.tryParse(countText);
    if (count == null || count <= 0) {
      _showSnackBar('To\'g\'ri son kiriting', Colors.red);
      return;
    }

    final success = await farmProvider.addChickens(count);
    if (success) {
      _addChickenController.clear();
      _showSnackBar(
        '$count dona tovuq muvaffaqiyatli qo\'shildi',
        Colors.green,
      );
    } else {
      _showSnackBar('Xatolik: ${farmProvider.error}', Colors.red);
    }
  }

  Future<void> _reportDeath(FarmProvider farmProvider) async {
    final countText = _deathCountController.text.trim();
    if (countText.isEmpty) {
      _showSnackBar('O\'lgan tovuqlar sonini kiriting', Colors.orange);
      return;
    }

    final count = int.tryParse(countText);
    if (count == null || count <= 0) {
      _showSnackBar('To\'g\'ri son kiriting', Colors.red);
      return;
    }

    final note = _deathReasonController.text.trim();
    final success = await farmProvider.addChickenDeath(
      count,
      note: note.isEmpty ? null : note,
    );
    if (success) {
      _deathCountController.clear();
      _deathReasonController.clear();
      _showSnackBar('O\'lim hisoboti saqlandi', Colors.blue);
    } else {
      _showSnackBar('Xatolik: ${farmProvider.error}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _QuantityStepper extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int min;
  final int max;
  final Color primaryColor;

  const _QuantityStepper({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    required this.primaryColor,
  });

  @override
  State<_QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<_QuantityStepper> {
  void _change(int delta) {
    final n = int.tryParse(widget.controller.text.trim()) ?? 0;
    final next = (n + delta).clamp(widget.min, widget.max);
    widget.controller.text = next.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ChickenManagementScreenState.blueSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ChickenManagementScreenState.blueDark,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: GoogleFonts.inter(color: Colors.blueGrey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: widget.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _change(1),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: widget.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 24,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _change(-1),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: widget.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPresets extends StatelessWidget {
  final List<int> values;
  final void Function(int) onTap;
  final Color primaryColor;

  const _QuickPresets({
    required this.values,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (v) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(v),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '+$v',
                    style: GoogleFonts.inter(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
