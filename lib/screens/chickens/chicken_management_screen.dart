import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/modern_theme.dart';
import '../../widgets/modern_components.dart';
import 'package:google_fonts/google_fonts.dart';

class ChickenManagementScreen extends StatefulWidget {
  const ChickenManagementScreen({super.key});

  @override
  State<ChickenManagementScreen> createState() => _ChickenManagementScreenState();
}

class _ChickenManagementScreenState extends State<ChickenManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _addChickenController = TextEditingController();
  final _deathCountController = TextEditingController();
  final _deathReasonController = TextEditingController();

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
      appBar: AppBar(
        title: Text(
          'Tovuq Boshqaruvi',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: ModernTheme.textPrimary,
          ),
        ),
        backgroundColor: ModernTheme.surfaceColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: 'Qo\'shish'),
            Tab(icon: Icon(Icons.warning), text: 'O\'limlar'),
            Tab(icon: Icon(Icons.analytics), text: 'Hisobot'),
          ],
          labelColor: ModernTheme.primaryGreen,
          unselectedLabelColor: ModernTheme.textTertiary,
          indicatorColor: ModernTheme.primaryGreen,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddChickenTab(),
          _buildDeathManagementTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildAddChickenTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final chicken = farm?.chicken;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Stats Card
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Hozirgi Holat',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Jami Tovuqlar',
                            value: '${chicken?.currentCount ?? 0}',
                            icon: Icons.pets,
                            color: ModernTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Bugungi O\'limlar',
                            value: '${_getTodayDeaths(chicken)}',
                            icon: Icons.warning,
                            color: ModernTheme.errorColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Sog\'lom',
                            value: '${(chicken?.currentCount ?? 0) - _getTodayDeaths(chicken)}',
                            icon: Icons.favorite,
                            color: ModernTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Add Chickens Form
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Yangi Tovuqlar Qo\'shish',
                    ),
                    const SizedBox(height: 16),
                    ModernInput(
                      controller: _addChickenController,
                      labelText: 'Tovuqlar soni',
                      hintText: 'Qo\'shiladigan tovuqlar soni',
                      prefixIcon: Icons.add,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    ModernButton(
                      text: farmProvider.isLoading ? 'Saqlanmoqda...' : 'Tovuqlar Qo\'shish',
                      icon: farmProvider.isLoading ? null : Icons.add_circle,
                      onPressed: farmProvider.isLoading ? null : () => _addChickens(farmProvider),
                      isLoading: farmProvider.isLoading,
                      isFullWidth: true,
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

  Widget _buildDeathManagementTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final chicken = farmProvider.farm?.chicken;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Death Report Form
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'O\'lim Hisoboti',
                    ),
                    const SizedBox(height: 16),
                    ModernInput(
                      controller: _deathCountController,
                      labelText: 'O\'lgan tovuqlar soni',
                      hintText: 'O\'lgan tovuqlar soni',
                      prefixIcon: Icons.warning,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ModernInput(
                      controller: _deathReasonController,
                      labelText: 'O\'lim sababi (ixtiyoriy)',
                      hintText: 'Kasallik, jarohat, tabiiy o\'lim...',
                      prefixIcon: Icons.note,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ModernButton(
                      text: farmProvider.isLoading ? 'Saqlanmoqda...' : 'O\'lim Hisoboti',
                      icon: farmProvider.isLoading ? null : Icons.report,
                      onPressed: farmProvider.isLoading ? null : () => _reportDeath(farmProvider),
                      isLoading: farmProvider.isLoading,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Recent Deaths List
              if (chicken?.deaths.isNotEmpty == true)
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'So\'nggi O\'limlar',
                      ),
                      const SizedBox(height: 16),
                      ...chicken!.deaths.take(10).map((death) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: Icon(Icons.warning, color: Colors.red[700]),
                        ),
                        title: Text('${death.count} dona tovuq'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd.MM.yyyy HH:mm').format(death.date)),
                            if (death.note?.isNotEmpty == true) Text(death.note!),
                          ],
                        ),
                        isThreeLine: death.note?.isNotEmpty == true,
                      )),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final chicken = farmProvider.farm?.chicken;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Weekly Report
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Haftalik Hisobot',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildReportItem('Jami Tovuqlar', '${chicken?.currentCount ?? 0}'),
                        _buildReportItem('Haftalik O\'limlar', '${_getWeeklyDeaths(chicken)}'),
                        _buildReportItem('O\'lim Darajasi', '${_getDeathRate(chicken).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Monthly Report
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Oylik Hisobot',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildReportItem('Oylik O\'limlar', '${_getMonthlyDeaths(chicken)}'),
                        _buildReportItem('O\'rtacha Kunlik O\'lim', '${(_getMonthlyDeaths(chicken) / 30).toStringAsFixed(1)}'),
                        _buildReportItem('Sog\'lom %', '${(100 - _getDeathRate(chicken)).toStringAsFixed(1)}%'),
                      ],
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

  Widget _buildReportItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ModernTheme.primaryGreen,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: ModernTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods
  int _getTodayDeaths(dynamic chicken) {
    if (chicken?.deaths == null) return 0;
    final today = DateTime.now();
    return chicken.deaths
        .where((death) =>
            death.date.year == today.year &&
            death.date.month == today.month &&
            death.date.day == today.day)
        .fold(0, (sum, death) => sum + death.count);
  }

  int _getWeeklyDeaths(dynamic chicken) {
    if (chicken?.deaths == null) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return chicken.deaths
        .where((death) => death.date.isAfter(weekAgo))
        .fold(0, (sum, death) => sum + death.count);
  }

  int _getMonthlyDeaths(dynamic chicken) {
    if (chicken?.deaths == null) return 0;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return chicken.deaths
        .where((death) => death.date.isAfter(monthAgo))
        .fold(0, (sum, death) => sum + death.count);
  }

  double _getDeathRate(dynamic chicken) {
    if (chicken?.totalCount == null || chicken.totalCount == 0) return 0.0;
    final monthlyDeaths = _getMonthlyDeaths(chicken);
    return (monthlyDeaths / chicken.totalCount) * 100;
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
      _showSnackBar('$count dona tovuq muvaffaqiyatli qo\'shildi', Colors.green);
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

    final success = await farmProvider.addChickenDeath(count);
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
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}