import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/stat_card.dart';

class ChickensScreen extends StatefulWidget {
  const ChickensScreen({super.key});

  @override
  State<ChickensScreen> createState() => _ChickensScreenState();
}

class _ChickensScreenState extends State<ChickensScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, child) {
          final farm = farmProvider.farm;
          final chicken = farm?.chicken;

          return Column(
            children: [
              // Modern Header with Gradient Background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9C27B0),
                      const Color(0xFFBA68C8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Section with Icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tovuqlar Boshqaruvi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tovuqlar soni va o\'limlar kuzatuvi',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Modern Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernStatCard(
                                'Joriy soni',
                                '${chicken?.currentCount ?? 0}',
                                'tovuq',
                                Icons.pets_outlined,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernStatCard(
                                'Bugungi o\'limlar',
                                '${chicken?.todayDeaths ?? 0}',
                                'tovuq',
                                Icons.warning_rounded,
                                chicken?.todayDeaths != null && chicken!.todayDeaths > 0
                                    ? Colors.red[300]!
                                    : Colors.green[300]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.mediumPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppConstants.mediumPadding),

                      // Tezkor amallar
                      Text(
                        'Tezkor Amallar',
                        style: AppConstants.subtitleStyle,
                      ),
                      const SizedBox(height: AppConstants.smallPadding),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: farm == null
                                  ? null
                                  : () => _showAddChickensDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Tovuq Qo\'shish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppConstants.mediumPadding),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: farm == null
                                  ? null
                                  : () => _showRecordDeathDialog(context),
                              icon: const Icon(Icons.remove),
                              label: const Text('O\'lim Kiritish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.errorColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.mediumPadding),

                      // Statistikalar
                      if (chicken != null) ...[
                        const SizedBox(height: AppConstants.smallPadding),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: AppConstants.mediumPadding,
                          mainAxisSpacing: AppConstants.mediumPadding,
                          childAspectRatio: 1.2,
                          children: [
                            StatCard(
                              title: 'Umumiy Tovuqlar',
                              value: '${chicken.totalCount}',
                              icon: AppConstants.chickenIcon,
                              color: AppConstants.primaryColor,
                            ),
                            StatCard(
                              title: 'Joriy Soni',
                              value: '${chicken.currentCount}',
                              icon: Icons.check_circle,
                              color: AppConstants.successColor,
                            ),
                            StatCard(
                              title: 'Bugungi O\'limlar',
                              value: '${chicken.todayDeaths}',
                              icon: Icons.warning,
                              color: AppConstants.warningColor,
                            ),
                            StatCard(
                              title: 'Umumiy O\'limlar',
                              value: '${chicken.deathStats['totalDeaths'] ?? 0}',
                              icon: Icons.error,
                              color: AppConstants.errorColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.mediumPadding),

                        // O'limlar statistikasi
                        if (chicken.deaths.isNotEmpty) ...[
                          Text(
                            'O\'limlar Tahlili',
                            style: AppConstants.subtitleStyle,
                          ),
                          const SizedBox(height: AppConstants.mediumPadding),
                          Container(
                            padding: const EdgeInsets.all(AppConstants.mediumPadding),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(AppConstants.mediumRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildStatRow(
                                  'Eng ko\'p o\'lim bo\'lgan kun',
                                  chicken.deathStats['mostDeathsDay'] != null
                                      ? '${chicken.deathStats['mostDeathsDay']['count']} ta'
                                      : 'Ma\'lumot yo\'q',
                                  Icons.trending_up,
                                  AppConstants.errorColor,
                                ),
                                const Divider(),
                                _buildStatRow(
                                  'Eng kam o\'lim bo\'lgan kun',
                                  chicken.deathStats['leastDeathsDay'] != null
                                      ? '${chicken.deathStats['leastDeathsDay']['count']} ta'
                                      : 'Ma\'lumot yo\'q',
                                  Icons.trending_down,
                                  AppConstants.successColor,
                                ),
                                const Divider(),
                                _buildStatRow(
                                  'O\'rtacha kunlik o\'lim',
                                  '${(chicken.deathStats['averageDeaths'] ?? 0.0).toStringAsFixed(1)} ta',
                                  Icons.analytics,
                                  AppConstants.infoColor,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppConstants.mediumPadding),

                        // O'limlar tarixi
                        if (chicken.deaths.isNotEmpty) ...[
                          Text(
                            'So\'nggi O\'limlar Tarixi',
                            style: AppConstants.subtitleStyle,
                          ),
                          const SizedBox(height: AppConstants.mediumPadding),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(AppConstants.mediumRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: chicken.deaths.length > 5
                                  ? 5
                                  : chicken.deaths.length,
                              separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final death = chicken.deaths.reversed.toList()[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                    AppConstants.errorColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.remove,
                                      color: AppConstants.errorColor,
                                    ),
                                  ),
                                  title: Text('${death.count} ta tovuq'),
                                  subtitle: Text(
                                    '${death.date.day}.${death.date.month}.${death.date.year}',
                                  ),
                                  trailing: death.note != null
                                      ? Tooltip(
                                    message: death.note!,
                                    child: const Icon(Icons.note),
                                  )
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ],

                      if (chicken == null) ...[
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
                              Icon(
                                AppConstants.chickenIcon,
                                size: 80,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Hali tovuqlar qo\'shilmagan',
                                style: AppConstants.subtitleStyle.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: farm == null
                                    ? null
                                    : () => _showAddChickensDialog(context),
                                child: const Text('Birinchi Tovuqlarni Qo\'shish'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernStatCard(
      String title,
      String value,
      String unit,
      IconData icon,
      Color accentColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 2),
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
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppConstants.bodyStyle,
            ),
          ),
          Text(
            value,
            style: AppConstants.subtitleStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChickensDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tovuq Qo\'shish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tovuqlar soni',
            border: OutlineInputBorder(),
            suffixText: 'ta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                final farmProvider =
                Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addChickens(count);

                if (mounted) Navigator.pop(context);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count ta tovuq qo\'shildi'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(farmProvider.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showRecordDeathDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tovuq O\'limi Kiritish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'O\'lgan tovuqlar soni',
            border: OutlineInputBorder(),
            suffixText: 'ta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                final farmProvider =
                Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addChickenDeath(count);

                if (mounted) Navigator.pop(context);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count ta tovuq o\'limi kiritildi'),
                      backgroundColor: AppConstants.warningColor,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(farmProvider.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor),
            child:
            const Text('Kiritish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}