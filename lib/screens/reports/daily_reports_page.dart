import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import '../../models/egg.dart';
import '../../utils/app_theme.dart';

class DailyReportsPage extends StatefulWidget {
  final DateTime? initialDate;
  const DailyReportsPage({super.key, this.initialDate});

  @override
  State<DailyReportsPage> createState() => _DailyReportsPageState();
}

class _DailyReportsPageState extends State<DailyReportsPage> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kunlik hisobotlar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
      ),
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, _) {
          final egg = farmProvider.farm?.egg;
          if (egg == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Ma\'lumot yo\'q',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final lifetime = _lifetimeAggregates(egg);
          final daily = _buildPerDayAggregates(egg);

          final selected = _selectedDate;
          Map<String, dynamic>? selectedEntry;
          if (selected != null) {
            selectedEntry = daily.firstWhere(
              (e) => _isSameDay(e['date'] as DateTime, selected),
              orElse: () => {},
            );
            if (selectedEntry.isEmpty) selectedEntry = null;
          }

          return Column(
            children: [
              // Lifetime summary card - yangilangan dizayn
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.summarize_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Umrbod umumiy xulosa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryRow(
                        Icons.egg_outlined,
                        'Yig\'ilgan',
                        '${lifetime['production']} ta',
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        Icons.shopping_cart_outlined,
                        'Sotilgan',
                        '${lifetime['sales']} ta',
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        Icons.broken_image_outlined,
                        'Siniq',
                        '${lifetime['broken']} ta',
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        Icons.star_outline,
                        'Katta',
                        '${lifetime['large']} ta',
                      ),
                      const Divider(
                        color: Colors.white30,
                        height: 24,
                        thickness: 1,
                      ),
                      _buildSummaryRow(
                        Icons.attach_money,
                        'Umumiy daromad',
                        '${lifetime['revenue'].toStringAsFixed(0)} so\'m',
                        isLarge: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Kunlik hisobotlar ro'yxati
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = daily[index];
                    final date = item['date'] as DateTime;
                    final isSelected =
                        selected != null && _isSameDay(date, selected);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[600]!
                              : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: isSelected ? 10 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _selectedDate = date);
                          },
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
                                        color: isSelected
                                            ? Colors.blue[100]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: isSelected
                                            ? Colors.blue[700]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _formatDate(date),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.blue[700]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.blue[600],
                                        size: 24,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatChip(
                                      Icons.egg_outlined,
                                      'Yig\'ilgan',
                                      '${item['production']}',
                                      Colors.green,
                                    ),
                                    _buildStatChip(
                                      Icons.shopping_bag_outlined,
                                      'Sotilgan',
                                      '${item['sales']}',
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.monetization_on,
                                            size: 18,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Daromad:',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${(item['revenue'] as double).toStringAsFixed(0)} so\'m',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: daily.length,
                ),
              ),

              // Tanlangan sana uchun batafsil ma'lumot paneli
              if (selectedEntry != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(
                                    selectedEntry['date'] as DateTime,
                                  ),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _selectedDate = null),
                                  icon: const Icon(Icons.close),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey[100],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.egg_outlined,
                              'Yig\'ilgan tuxum',
                              '${selectedEntry['production']} fletka',
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.shopping_cart_outlined,
                              'Sotilgan tuxum',
                              '${selectedEntry['sales']} fletka',
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.broken_image_outlined,
                              'Siniq tuxum',
                              '${selectedEntry['broken']} fletka',
                              Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.star_outlined,
                              'Katta tuxum',
                              '${selectedEntry['large']} fletka',
                              Colors.purple,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[400]!,
                                    Colors.green[600]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Umumiy daromad',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${(selectedEntry['revenue'] as double).toStringAsFixed(0)} so\'m',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value, {
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: isLarge ? 24 : 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
