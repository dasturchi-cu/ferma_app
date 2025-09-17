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

class _ChickensScreenState extends State<ChickensScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _chickenCountController = TextEditingController();
  final _deathCountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chickenCountController.dispose();
    _deathCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('chickens_scaffold'),
      body: Consumer<FarmProvider>(
        key: const Key('chickens_consumer'),
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
                    colors: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
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
                                chicken?.todayDeaths != null &&
                                        chicken!.todayDeaths > 0
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

              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.secondary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.secondary,
                tabs: const [
                  Tab(child: Text('Tovuqlar')),
                  Tab(child: Text('O\'limlar')),
                  Tab(child: Text('Statistika')),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  key: const Key('chickens_tab_view'),
                  controller: _tabController,
                  children: [
                    _buildChickensTab(chicken),
                    _buildDeathsTab(chicken),
                    _buildStatsTab(chicken),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'chickens_fab',
          onPressed: () => _showQuickActionsDialog(context),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
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
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                child: Icon(icon, color: accentColor, size: 20),
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
          Expanded(child: Text(title, style: AppConstants.bodyStyle)),
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

  Widget _buildChickensTab(chicken) {
    return SingleChildScrollView(
      key: const Key('chickens_tab_scroll'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddChickensDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tovuq Qo\'shish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Statistics
          if (chicken != null) ...[
            const Text(
              'Statistikalar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
                _buildStatCard(
                  'Umumiy Tovuqlar',
                  '${chicken.totalCount} ta',
                  Icons.pets,
                ),
                _buildStatCard(
                  'Joriy Soni',
                  '${chicken.currentCount} ta',
                  Icons.check_circle,
                ),
                _buildStatCard(
                  'O\'rtacha O\'lim',
                  '${chicken.deathStats?['averageDeaths']?.toStringAsFixed(1) ?? '0.0'} ta/kun',
                  Icons.analytics,
                ),
                _buildStatCard(
                  'Sog\'lom Kunlar',
                  '${chicken.deathStats?['healthyDays'] ?? 0} kun',
                  Icons.health_and_safety,
                ),
              ],
            ),
          ],

          if (chicken == null) ...[
            _buildEmptyState('Hali tovuqlar qo\'shilmagan', Icons.pets),
          ],
        ],
      ),
    );
  }

  Widget _buildDeathsTab(chicken) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordDeathDialog(context),
                  icon: const Icon(Icons.remove),
                  label: const Text('O\'lim Kiritish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Death statistics
          if (chicken != null) ...[
            Text(
              'O\'limlar Statistikasi',
              style: Theme.of(context).textTheme.titleMedium,
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
                  title: 'Bugungi O\'limlar',
                  value: '${chicken.todayDeaths ?? 0} ta',
                  icon: Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Umumiy O\'limlar',
                  value: '${chicken.deathStats?['totalDeaths'] ?? 0} ta',
                  icon: Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Eng Ko\'p O\'lim',
                  value: chicken.deathStats?['mostDeathsDay'] != null
                      ? '${chicken.deathStats!['mostDeathsDay']['count']} ta'
                      : 'Ma\'lumot yo\'q',
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'O\'rtacha O\'lim',
                  value:
                      '${chicken.deathStats?['averageDeaths']?.toStringAsFixed(1) ?? '0.0'} ta/kun',
                  icon: Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Death history
            if (chicken.deaths.isNotEmpty) ...[
              Text(
                'So\'nggi O\'limlar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chicken.deaths.length > 10
                    ? 10
                    : chicken.deaths.length,
                itemBuilder: (context, index) {
                  final death = chicken.deaths.reversed.toList()[index];
                  return Card(
                    key: ValueKey(
                      'death_${death.date.millisecondsSinceEpoch}_$index',
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.1),
                        child: Icon(
                          Icons.remove,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      title: Text('${death.count} ta tovuq'),
                      subtitle: Text(
                        '${death.date.day}/${death.date.month}/${death.date.year}',
                      ),
                      trailing: death.note != null
                          ? Tooltip(
                              message: death.note!,
                              child: const Icon(Icons.note),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ],

          if (chicken == null) ...[
            _buildEmptyState('Hali o\'lim ma\'lumotlari yo\'q', Icons.warning),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsTab(chicken) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chicken != null) ...[
            Text(
              'Batafsil Statistikalar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Detailed stats cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3,
              children: [
                _buildDetailedStatCard('Umumiy Ma\'lumotlar', [
                  'Jami tovuqlar: ${chicken.totalCount} ta',
                  'Joriy soni: ${chicken.currentCount} ta',
                  'O\'lganlar: ${chicken.deathStats?['totalDeaths'] ?? 0} ta',
                ], Icons.info),
                _buildDetailedStatCard('O\'limlar Tahlili', [
                  'Bugungi o\'limlar: ${chicken.todayDeaths ?? 0} ta',
                  'O\'rtacha kunlik: ${chicken.deathStats?['averageDeaths']?.toStringAsFixed(1) ?? '0.0'} ta',
                  'Sog\'lom kunlar: ${chicken.deathStats?['healthyDays'] ?? 0} kun',
                ], Icons.analytics),
                _buildDetailedStatCard('Trend Ma\'lumotlari', [
                  'Eng ko\'p o\'lim: ${chicken.deathStats?['mostDeathsDay']?['count'] ?? 0} ta',
                  'Eng kam o\'lim: ${chicken.deathStats?['leastDeathsDay']?['count'] ?? 0} ta',
                  'O\'lim foizi: ${((chicken.deathStats?['totalDeaths'] ?? 0) / chicken.totalCount * 100).toStringAsFixed(1)}%',
                ], Icons.trending_up),
              ],
            ),
          ],

          if (chicken == null) ...[
            _buildEmptyState('Statistika ma\'lumotlari yo\'q', Icons.analytics),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatCard(
    String title,
    List<String> stats,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(stat, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
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
        title: const Text('Tovuqlarni Qo\'shish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tovuqlar soni',
            border: OutlineInputBorder(),
            suffixText: 'dona',
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
                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
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
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'lim Kiritish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'O\'lgan tovuqlar soni',
                border: OutlineInputBorder(),
                suffixText: 'dona',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                border: OutlineInputBorder(),
                hintText: 'O\'lim sababi...',
              ),
            ),
          ],
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
                final note = noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim();

                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
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
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text(
              'Kiritish',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tezkor Amallar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildQuickActionButton(
                  'Tovuq Qo\'shish',
                  Icons.add,
                  Theme.of(context).colorScheme.secondary,
                  () {
                    Navigator.pop(context);
                    _showAddChickensDialog(context);
                  },
                ),
                _buildQuickActionButton(
                  'O\'lim Kiritish',
                  Icons.remove,
                  Theme.of(context).colorScheme.error,
                  () {
                    Navigator.pop(context);
                    _showRecordDeathDialog(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
