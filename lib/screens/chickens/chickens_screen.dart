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
      appBar: AppBar(
        title: const Text('Tovuqlar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, child) {
          final farm = farmProvider.farm;
          final chicken = farm?.chicken;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.mediumPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Umumiy ma'lumotlar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
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
                            AppConstants.chickenIcon,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: AppConstants.mediumPadding),
                          Text(
                            'Tovuqlar Boshqaruvi',
                            style: AppConstants.titleStyle.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.mediumPadding),
                      Text(
                        'Joriy tovuqlar soni: ${chicken?.currentCount ?? 0}',
                        style: AppConstants.subtitleStyle.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Umumiy: ${chicken?.totalCount ?? 0} | Bugungi o\'limlar: ${chicken?.todayDeaths ?? 0}',
                        style: AppConstants.bodyStyle.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        value: '${chicken.deathStats['totalDeaths']}',
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
                            '${chicken.deathStats['averageDeaths'].toStringAsFixed(1)} ta',
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
          );
        },
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

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count ta tovuq qo\'shildi'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                } else {
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

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count ta tovuq o\'limi kiritildi'),
                      backgroundColor: AppConstants.warningColor,
                    ),
                  );
                } else {
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
