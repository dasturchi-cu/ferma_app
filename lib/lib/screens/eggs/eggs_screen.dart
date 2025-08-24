import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart' as AppConstants;
import '../../widgets/stat_card.dart';

class EggsScreen extends StatefulWidget {
  const EggsScreen({super.key});

  @override
  State<EggsScreen> createState() => _EggsScreenState();
}

class _EggsScreenState extends State<EggsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _trayCountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trayCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _showAddProductionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tuxum Yig\'ish Qo\'shish'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _trayCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fletka soni',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Iltimos, fletka sonini kiriting';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Iltimos, raqam kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Sana'),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  ListTile(
                    title: const Text('Vaqt'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Izoh (ixtiyoriy)',
                      border: OutlineInputBorder(),
                      hintText: 'Qo\'shimcha ma\'lumotlar...',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveProduction();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProduction() async {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final trayCount = int.parse(_trayCountController.text);
    final note =
        _notesController.text.isNotEmpty ? _notesController.text : null;

    final success = await farmProvider.addEggProduction(trayCount, note: note);

    if (success) {
      // Reset form
      _trayCountController.clear();
      _notesController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tuxum yig\'imi saqlandi')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: ${farmProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, _) {
          final egg = farmProvider.farm?.egg;
          return Column(
            children: [
              // Header with stats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (Navigator.canPop(context))
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).maybePop(),
                              tooltip: 'Ortga',
                            ),
                          if (Navigator.canPop(context)) const SizedBox(width: 8),
                          const Icon(
                            Icons.egg_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Tuxum Boshqaruvi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeaderStat(
                              'Bugungi Tuxumlar',
                              '${egg?.todayProduction ?? 0} fletka',
                              Icons.today,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildHeaderStat(
                              'Joriy Zaxira',
                              '${egg?.currentStock ?? 0} fletka',
                              Icons.inventory,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  Tab(child: Text('Ishlab Chiqarish')),
                  Tab(child: Text('Sotuvlar')),
                  Tab(child: Text('Siniq')),
                  Tab(child: Text('Katta')),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductionTab(egg),
                    _buildSalesTab(egg),
                    _buildBrokenTab(egg),
                    _buildLargeTab(egg),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsDialog(context),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionTab(egg) {
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
                  onPressed: _showAddProductionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tuxum Yig\'ish'),
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
          if (egg != null) ...[
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
                  'Bugungi Ishlab Chiqarish',
                  '${egg.todayProduction} fletka',
                  Icons.egg_outlined,
                ),
                _buildStatCard(
                  'Umumiy Ishlab Chiqarish',
                  '${egg.productionStats['totalProduction']} fletka',
                  Icons.production_quantity_limits,
                ),
                _buildStatCard(
                  'Eng Ko\'p Kun',
                  egg.productionStats['mostProductionDay'] != null
                      ? '${egg.productionStats['mostProductionDay']['count']} fletka'
                      : 'Ma\'lumot yo\'q',
                  Icons.trending_up,
                ),
                _buildStatCard(
                  'O\'rtacha Kunlik',
                  '${egg.productionStats['averageProduction'].toStringAsFixed(1)} fletka',
                  Icons.analytics,
                ),
              ],
            ),
          ],

          if (egg == null) ...[
            _buildEmptyState('Hali tuxum yig\'ilmagan', Icons.egg_alt),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesTab(egg) {
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
                  onPressed: () => _showAddSaleDialog(context),
                  icon: const Icon(Icons.sell),
                  label: const Text('Sotuv Qo\'shish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Statistics
          if (egg != null) ...[
            Text(
              'Sotuvlar Statistikasi',
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
                  title: 'Bugungi Sotuvlar',
                  value: '${egg.todaySales} fletka',
                  icon: Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatCard(
                  title: 'Umumiy Sotuvlar',
                  value:
                      '${egg.sales.fold(0, (sum, sale) => sum + sale.trayCount)} fletka',
                  icon: Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatCard(
                  title: 'Joriy Zaxira',
                  value: '${egg.currentStock} fletka',
                  icon: Icons.inventory,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                StatCard(
                  title: 'Sotuvlar Soni',
                  value: '${egg.sales.length} ta',
                  icon: Icons.receipt,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
          ],

          if (egg == null) ...[
            _buildEmptyState('Hali sotuvlar yo\'q', Icons.sell),
          ],
        ],
      ),
    );
  }

  Widget _buildBrokenTab(egg) {
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
                  onPressed: () => _showAddBrokenDialog(context),
                  icon: const Icon(Icons.broken_image),
                  label: const Text('Siniq Tuxum Kiritish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Statistics
          if (egg != null) ...[
            Text(
              'Siniq Tuxumlar Statistikasi',
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
                  title: 'Bugungi Siniq',
                  value: '${egg.todayBroken} fletka',
                  icon: Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Umumiy Siniq',
                  value: '${egg.brokenStats['totalBroken']} fletka',
                  icon: Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Eng Ko\'p Siniq Kun',
                  value: egg.brokenStats['mostBrokenDay'] != null
                      ? '${egg.brokenStats['mostBrokenDay']['count']} fletka'
                      : 'Ma\'lumot yo\'q',
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Siniq Bo\'lmagan Kunlar',
                  value: '${egg.brokenStats['zeroBrokenDays']} kun',
                  icon: Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],

          if (egg == null) ...[
            _buildEmptyState('Hali siniq tuxumlar yo\'q', Icons.broken_image),
          ],
        ],
      ),
    );
  }

  Widget _buildLargeTab(egg) {
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
                  onPressed: () => _showAddLargeDialog(context),
                  icon: const Icon(Icons.expand),
                  label: const Text('Katta Tuxum Kiritish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Statistics
          if (egg != null) ...[
            Text(
              'Katta Tuxumlar Statistikasi',
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
                  title: 'Bugungi Katta',
                  value: '${egg.todayLarge} fletka',
                  icon: Icons.expand,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                StatCard(
                  title: 'Umumiy Katta',
                  value: '${egg.largeEggStats['totalLarge']} fletka',
                  icon: Icons.expand_circle_down,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                StatCard(
                  title: 'Eng Ko\'p Katta Kun',
                  value: egg.largeEggStats['mostLargeDay'] != null
                      ? '${egg.largeEggStats['mostLargeDay']['count']} fletka'
                      : 'Ma\'lumot yo\'q',
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatCard(
                  title: 'O\'rtacha Kunlik',
                  value:
                      '${egg.largeEggStats['averageLarge'].toStringAsFixed(1)} fletka',
                  icon: Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],

          if (egg == null) ...[
            _buildEmptyState('Hali katta tuxumlar yo\'q', Icons.expand),
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
                  'Tuxum Yig\'ish',
                  Icons.egg,
                  Theme.of(context).colorScheme.secondary,
                  () {
                    Navigator.pop(context);
                    _showAddProductionDialog();
                  },
                ),
                _buildQuickActionButton(
                  'Sotuv',
                  Icons.sell,
                  Theme.of(context).colorScheme.primary,
                  () {
                    Navigator.pop(context);
                    _showAddSaleDialog(context);
                  },
                ),
                _buildQuickActionButton(
                  'Siniq',
                  Icons.broken_image,
                  Theme.of(context).colorScheme.error,
                  () {
                    Navigator.pop(context);
                    _showAddBrokenDialog(context);
                  },
                ),
                _buildQuickActionButton(
                  'Katta',
                  Icons.expand,
                  Theme.of(context).colorScheme.tertiary,
                  () {
                    Navigator.pop(context);
                    _showAddLargeDialog(context);
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

  void _showAddSaleDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tuxum Sotish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sotilgan fletka soni',
            border: OutlineInputBorder(),
            suffixText: 'fletka',
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
                final success = await farmProvider.addEggSale(count, 10000.0);

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count fletka tuxum sotildi'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(farmProvider.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Sotish'),
          ),
        ],
      ),
    );
  }

  void _showAddBrokenDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siniq Tuxum Kiritish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Siniq fletka soni',
            border: OutlineInputBorder(),
            suffixText: 'fletka',
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
                final success = await farmProvider.addBrokenEgg(count);

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count fletka siniq tuxum kiritildi'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(farmProvider.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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

  void _showAddLargeDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katta Tuxum Kiritish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Katta tuxum fletka soni',
            border: OutlineInputBorder(),
            suffixText: 'fletka',
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
                final success = await farmProvider.addLargeEgg(count);

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count fletka katta tuxum kiritildi'),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(farmProvider.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
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
}
