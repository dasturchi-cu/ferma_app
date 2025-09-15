import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/modern_theme.dart';
import '../../widgets/modern_components.dart';
import '../../providers/farm_provider.dart';
import '../../widgets/activity_log_widget.dart';
import '../../providers/auth_provider.dart';
import '../reports/advanced_reports_screen.dart';
import '../chickens/chicken_management_screen.dart';

class ModernDashboard extends StatefulWidget {
  final void Function(int index)? onTabSelected;
  const ModernDashboard({super.key, this.onTabSelected});

  @override
  State<ModernDashboard> createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> {
  bool _isRealtimeActive = false;
  FarmProvider? _farmProvider;

  @override
  void initState() {
    super.initState();
    // Listen to farm provider changes to detect realtime updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _farmProvider = Provider.of<FarmProvider>(context, listen: false);
        _farmProvider?.addListener(_onFarmDataChanged);
      }
    });
  }

  void _onFarmDataChanged() {
    if (mounted) {
      setState(() {
        _isRealtimeActive = true;
      });

      // Reset the indicator after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isRealtimeActive = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // SAFE DISPOSE - Remove listener to prevent memory leaks
    try {
      _farmProvider?.removeListener(_onFarmDataChanged);
      print('🧹 Dashboard listener removed');
    } catch (e) {
      print('! Dashboard dispose error: $e');
      // Continue with disposal even if error occurs
    } finally {
      _farmProvider = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: ModernTheme.textPrimary,
          ),
        ),
        backgroundColor: ModernTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Refresh button
          Consumer<FarmProvider>(
            builder: (context, farmProvider, child) {
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
                onSelected: (value) async {
                  switch (value) {
                    case 'refresh':
                      await farmProvider.refreshData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔄 Ma\'lumotlar yangilandi!')),
                        );
                      }
                      break;
                    case 'clear_cache':
                      await farmProvider.clearCacheAndRefresh();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🧹 Cache tozalandi va ma\'lumotlar yangilandi!')),
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh),
                        const SizedBox(width: 8),
                        const Text('Ma\'lumotlarni yangilash'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_cache',
                    child: Row(
                      children: [
                        const Icon(Icons.clear_all),
                        const SizedBox(width: 8),
                        const Text('Cache tozalash'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          // Realtime indicator
          if (_isRealtimeActive)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Offline mode indicator
          Consumer<FarmProvider>(
            builder: (context, farmProvider, child) {
              if (farmProvider.isOfflineMode) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final farmProvider = Provider.of<FarmProvider>(context, listen: false);
          await farmProvider.refreshData();
        },
        child: Column(
          children: [
            // Stats Overview
            Consumer<FarmProvider>(
              builder: (context, farmProvider, child) {
                return _buildStatsOverview(farmProvider.farm);
              },
            ),

            // Main Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Tezkor Amallar',
                      ),
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                      SectionHeader(
                        title: 'So\'nggi Harakatlar',
                      ),
                      Consumer<FarmProvider>(
                        builder: (context, farmProvider, child) {
                          if (farmProvider.farm != null) {
                            return ActivityLogWidget(
                              farmId: farmProvider.farm!.id,
                              maxItems: 10,
                              height: 250,
                            );
                          } else {
                            return Container(
                              height: 100,
                              child: Center(
                                child: Text(
                                  'Farm ma\'lumotlari yuklanmoqda...',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(farm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: ModernTheme.primaryGradientDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugungi Statistika',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Bugungi Tuxum',
                '${farm?.egg?.todayProduction ?? 0}',
                Icons.egg_outlined,
              ),
              _buildStatItem(
                'Jami Zaxira',
                '${farm?.egg?.currentStock ?? 0}',
                Icons.inventory,
              ),
              _buildStatItem(
                'Tovuqlar',
                '${farm?.chicken?.currentCount ?? 0}',
                Icons.pets,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return ActionButton(
      title: label,
      icon: icon,
      color: color,
      onTap: onTap,
      isCompact: true,
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3,
          children: [
            _buildActionButton(
              Icons.add_circle_outline,
              'Tuxum Qo\'shish',
              ModernTheme.primaryGreen,
              onTap: () => widget.onTabSelected?.call(2),
            ),
            _buildActionButton(
              Icons.person_add_alt_1_outlined,
              'Mijoz Qo\'shish',
              ModernTheme.accentBlue,
              onTap: () => widget.onTabSelected?.call(1),
            ),
            _buildActionButton(
              Icons.receipt_long_outlined,
              'Qarz Qo\'shish',
              ModernTheme.accentOrange,
              onTap: () => widget.onTabSelected?.call(4),
            ),
            _buildActionButton(
              Icons.analytics_outlined,
              'Hisobot',
              ModernTheme.accentYellow,
              onTap: () => widget.onTabSelected?.call(3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Featured Quick Access Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Advanced Reports Card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ModernTheme.accentBlue, ModernTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                  borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ModernTheme.accentBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedReportsScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                              'Kengaytirilgan Hisobotlar',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                              'Real-time tahlillar va 50+ yillik arxiv',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Chicken Management Card
              Container(
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ModernTheme.accentOrange, ModernTheme.accentYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                  borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ModernTheme.accentOrange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChickenManagementScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tovuq Boshqaruvi',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tovuqlarni qo\'shish va o\'limni kuzatish',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // Helper method to calculate total debt
  double _calculateTotalDebt(List customers) {
    return customers.fold(0.0, (sum, customer) => sum + customer.totalDebt);
  }
}
