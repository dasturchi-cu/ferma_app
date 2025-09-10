import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/egg.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Statistikalar'),
      //   backgroundColor: AppConstants.infoColor,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, child) {
          final farm = farmProvider.farm;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.mediumPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.infoColor,
                        AppConstants.infoColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppConstants.largeRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: AppConstants.mediumPadding),
                          Text(
                            'Statistika va Tahlil',
                            style: AppConstants.titleStyle.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        'Ferma faoliyati bo\'yicha batafsil ma\'lumotlar',
                        style: AppConstants.bodyStyle.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding),

                if (farm != null) ...[
                  // Umumiy ko'rsatkichlar
                  _buildOverviewSection(farm),

                  const SizedBox(height: AppConstants.largePadding),

                  // Tuxum statistikasi (umumiy va davriy)
                  if (farm.egg != null) ...[
                    _buildSectionTitle('Tuxum Statistikasi (Umumiy va Davriy)'),
                    _buildEggStats(farm.egg!),
                    const SizedBox(height: AppConstants.largePadding),
                    _buildSectionTitle('Tuxum Tarixi'),
                    _buildEggHistory(farm.egg!),
                    const SizedBox(height: AppConstants.largePadding),
                  ],

                  // Tovuqlar statistikasi
                  if (farm.chicken != null) ...[
                    _buildSectionTitle('Tovuqlar Tarixi'),
                    _buildChickenList(farm.chicken!),
                    const SizedBox(height: AppConstants.largePadding),
                  ],

                  // Mijozlar va qarzdorlik
                  if (farm.customers.isNotEmpty) ...[
                    _buildSectionTitle('Mijozlar'),
                    _buildCustomerList(farm),
                  ],
                ] else ...[
                  _buildEmptyState(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Date range helpers
  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _tomorrowStart => _todayStart.add(const Duration(days: 1));

  DateTime get _weekStart {
    final now = DateTime.now();
    final weekday = now.weekday; // Monday = 1
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
  }

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _yearStart {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  // Generic sum in [start, end) for items with `date` and `trayCount`
  int _sumInRange<T>(
    Iterable<T> items,
    DateTime Function(T) getDate,
    int Function(T) getCount,
    DateTime start,
    DateTime endExclusive,
  ) {
    return items.where((e) {
      final d = getDate(e);
      return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endExclusive);
    }).fold<int>(0, (sum, e) => sum + getCount(e));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.mediumPadding),
      child: Text(
        title,
        style: AppConstants.subtitleStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOverviewSection(farm) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Umumiy Ko\'rsatkichlar',
            style: AppConstants.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.mediumPadding),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.mediumPadding,
            mainAxisSpacing: AppConstants.mediumPadding,
            childAspectRatio: 1.5,
            children: [
              _buildOverviewCard(
                'Tovuqlar',
                '${farm.chicken?.currentCount ?? 0}',
                '${farm.chicken?.totalCount ?? 0} umumiy',
                AppConstants.primaryColor,
                Icons.pets,
              ),
              _buildOverviewCard(
                'Tuxum Zaxirasi',
                '${farm.egg?.currentStock ?? 0}',
                'fletka',
                AppConstants.secondaryColor,
                Icons.egg,
              ),
              _buildOverviewCard(
                'Mijozlar',
                '${farm.customers.length}',
                'aktiv',
                AppConstants.accentColor,
                Icons.people,
              ),
              _buildOverviewCard(
                'Qarzdorlik',
                '${farm.customers.fold(0.0, (sum, customer) => sum + customer.totalDebt).toStringAsFixed(0)}',
                'so\'m',
                AppConstants.errorColor,
                Icons.money_off,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
      String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppConstants.titleStyle.copyWith(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppConstants.captionStyle.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            title,
            style: AppConstants.bodyStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEggHistory(egg) {
    // Sort lists by date desc
    final prod = [...egg.production]..sort((a, b) => b.date.compareTo(a.date));
    final sales = [...egg.sales]..sort((a, b) => b.date.compareTo(a.date));
    final broken = [...egg.brokenEggs]..sort((a, b) => b.date.compareTo(a.date));
    final large = [...egg.largeEggs]..sort((a, b) => b.date.compareTo(a.date));

    Widget section(String title, IconData icon, Color color, List<Map<String, String>> rows) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppConstants.mediumPadding),
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text('Ma\'lumot yo\'q', style: AppConstants.captionStyle)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return Row(
                    children: [
                      Expanded(child: Text(r['left']!, style: AppConstants.bodyStyle)),
                      Text(r['right']!, style: AppConstants.captionStyle),
                    ],
                  );
                },
              ),
          ],
        ),
      );
    }

    String d(DateTime x) => '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}.${x.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(
          'Ishlab chiqarish tarixi',
          Icons.factory,
          AppConstants.secondaryColor,
          prod.map((p) => {
                'left': '${p.trayCount} fletka',
                'right': d(p.date),
              }).toList(),
        ),
        section(
          'Sotuvlar tarixi',
          Icons.shopping_cart,
          AppConstants.accentColor,
          sales.map((s) => {
                'left': '${s.trayCount} fletka • ${(s.pricePerTray * s.trayCount).toStringAsFixed(0)} so\'m',
                'right': d(s.date),
              }).toList(),
        ),
        section(
          'Siniq tuxumlar tarixi',
          Icons.warning_amber_rounded,
          AppConstants.errorColor,
          broken.map((b) => {
                'left': '${b.trayCount} fletka',
                'right': d(b.date),
              }).toList(),
        ),
        section(
          'Katta tuxumlar tarixi',
          Icons.egg,
          AppConstants.primaryColor,
          large.map((l) => {
                'left': '${l.trayCount} fletka',
                'right': d(l.date),
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildEggStats(egg) {
    // Date ranges
    final todayStart = _todayStart;
    final tomorrowStart = _tomorrowStart;
    final weekStart = _weekStart;
    final monthStart = _monthStart;
    final yearStart = _yearStart;

    // Totals since inception
    final prodTotal = egg.production.fold<int>(0, (s, p) => s + p.trayCount);
    final saleTotal = egg.sales.fold<int>(0, (s, p) => s + p.trayCount);
    final brokenTotal = egg.brokenEggs.fold<int>(0, (s, p) => s + p.trayCount);
    final largeTotal = egg.largeEggs.fold<int>(0, (s, p) => s + p.trayCount);

    // Period sums
    final prodToday = _sumInRange<EggProduction>(egg.production, (p) => p.date,
        (p) => p.trayCount, todayStart, tomorrowStart);
    final prodWeek = _sumInRange<EggProduction>(egg.production, (p) => p.date,
        (p) => p.trayCount, weekStart, tomorrowStart);
    final prodMonth = _sumInRange<EggProduction>(egg.production, (p) => p.date,
        (p) => p.trayCount, monthStart, tomorrowStart);
    final prodYear = _sumInRange<EggProduction>(egg.production, (p) => p.date,
        (p) => p.trayCount, yearStart, tomorrowStart);

    final saleToday = _sumInRange<EggSale>(egg.sales, (s) => s.date,
        (s) => s.trayCount, todayStart, tomorrowStart);
    final saleWeek = _sumInRange<EggSale>(egg.sales, (s) => s.date,
        (s) => s.trayCount, weekStart, tomorrowStart);
    final saleMonth = _sumInRange<EggSale>(egg.sales, (s) => s.date,
        (s) => s.trayCount, monthStart, tomorrowStart);
    final saleYear = _sumInRange<EggSale>(egg.sales, (s) => s.date,
        (s) => s.trayCount, yearStart, tomorrowStart);

    final brokenToday = _sumInRange<BrokenEgg>(egg.brokenEggs, (b) => b.date,
        (b) => b.trayCount, todayStart, tomorrowStart);
    final brokenWeek = _sumInRange<BrokenEgg>(egg.brokenEggs, (b) => b.date,
        (b) => b.trayCount, weekStart, tomorrowStart);
    final brokenMonth = _sumInRange<BrokenEgg>(egg.brokenEggs, (b) => b.date,
        (b) => b.trayCount, monthStart, tomorrowStart);
    final brokenYear = _sumInRange<BrokenEgg>(egg.brokenEggs, (b) => b.date,
        (b) => b.trayCount, yearStart, tomorrowStart);

    final largeToday = _sumInRange<LargeEgg>(egg.largeEggs, (l) => l.date,
        (l) => l.trayCount, todayStart, tomorrowStart);
    final largeWeek = _sumInRange<LargeEgg>(egg.largeEggs, (l) => l.date,
        (l) => l.trayCount, weekStart, tomorrowStart);
    final largeMonth = _sumInRange<LargeEgg>(egg.largeEggs, (l) => l.date,
        (l) => l.trayCount, monthStart, tomorrowStart);
    final largeYear = _sumInRange<LargeEgg>(egg.largeEggs, (l) => l.date,
        (l) => l.trayCount, yearStart, tomorrowStart);

    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.egg_alt, color: AppConstants.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Tuxumlar (ishlab chiqarish, sotuv, siniq, katta, zaxira)',
                style: AppConstants.subtitleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mediumPadding),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.mediumPadding,
            mainAxisSpacing: AppConstants.mediumPadding,
            childAspectRatio: 1.6,
            children: [
              _buildEggStatCard(
                title: 'Ishlab chiqarish',
                color: AppConstants.secondaryColor,
                icon: Icons.factory,
                total: prodTotal,
                today: prodToday,
                week: prodWeek,
                month: prodMonth,
                year: prodYear,
              ),
              _buildEggStatCard(
                title: 'Sotuv',
                color: AppConstants.accentColor,
                icon: Icons.shopping_cart,
                total: saleTotal,
                today: saleToday,
                week: saleWeek,
                month: saleMonth,
                year: saleYear,
              ),
              _buildEggStatCard(
                title: 'Siniq',
                color: AppConstants.errorColor,
                icon: Icons.warning_amber_rounded,
                total: brokenTotal,
                today: brokenToday,
                week: brokenWeek,
                month: brokenMonth,
                year: brokenYear,
              ),
              _buildEggStatCard(
                title: 'Katta tuxum',
                color: AppConstants.primaryColor,
                icon: Icons.egg,
                total: largeTotal,
                today: largeToday,
                week: largeWeek,
                month: largeMonth,
                year: largeYear,
              ),
              _buildStockCard(stock: egg.currentStock),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEggStatCard({
    required String title,
    required Color color,
    required IconData icon,
    required int total,
    required int today,
    required int week,
    required int month,
    required int year,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppConstants.bodyStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Jami: $total',
                  style: AppConstants.captionStyle.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniMetric('Bugun', today, color),
          _miniMetric('Hafta', week, color),
          _miniMetric('Oy', month, color),
          _miniMetric('Yil', year, color),
        ],
      ),
    );
  }

  Widget _buildStockCard({required int stock}) {
    final color = AppConstants.successColor;
    return Container(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zaxira',
                  style: AppConstants.bodyStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$stock fletka',
                  style: AppConstants.captionStyle.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Joriy zaxira (ishlab chiqarish - sotuv - siniq)',
            style: AppConstants.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: AppConstants.captionStyle),
          const Spacer(),
          Text(
            '$value',
            style: AppConstants.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChickenList(chicken) {
    final deaths = [...chicken.deaths]..sort((a, b) => b.date.compareTo(a.date));
    String d(DateTime x) => '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}.${x.year}';

    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppConstants.chickenIcon, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              Text('Tovuqlar tarixi',
                  style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Hozirgi: ${chicken.currentCount}', style: AppConstants.captionStyle),
            ],
          ),
          const SizedBox(height: AppConstants.mediumPadding),
          if (deaths.isEmpty)
            Text('Ma\'lumot yo\'q', style: AppConstants.captionStyle)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deaths.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, i) {
                final it = deaths[i];
                return Row(
                  children: [
                    Expanded(child: Text('O\'lim: ${it.count} ta', style: AppConstants.bodyStyle)),
                    Text(d(it.date), style: AppConstants.captionStyle),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(farm) {
    final customers = [...farm.customers]
      ..sort((a, b) => b.totalDebt.compareTo(a.totalDebt));

    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppConstants.customerIcon, color: AppConstants.accentColor),
              const SizedBox(width: 8),
              Text('Mijozlar',
                  style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppConstants.mediumPadding),
          if (customers.isEmpty)
            Text('Mijozlar mavjud emas', style: AppConstants.captionStyle)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, i) {
                final c = customers[i];
                final debt = c.totalDebt;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: AppConstants.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(c.phone, style: AppConstants.captionStyle),
                        ],
                      ),
                    ),
                    Text(
                      debt == 0 ? 'Qarz yo\'q' : '${debt.toStringAsFixed(0)} so\'m',
                      style: AppConstants.captionStyle.copyWith(
                        color: debt == 0 ? AppConstants.successColor : AppConstants.errorColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(
            Icons.analytics,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Statistika mavjud emas',
            style: AppConstants.subtitleStyle.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ma\'lumotlarni kiritgandan so\'ng\nstatistikalar ko\'rsatiladi',
            style: AppConstants.bodyStyle.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
