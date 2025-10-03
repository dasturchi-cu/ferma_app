import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../widgets/stat_card.dart';
import '../main/main_screen.dart';
import '../../widgets/search_bar_with_filters.dart';
import '../../providers/search_provider.dart';

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
  final _pricePerTrayController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _defaultPricePerTray = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDefaultPrice();
  }

  Future<void> _loadDefaultPrice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultPricePerTray = prefs.getDouble('default_price_per_tray') ?? 0;
      if (_defaultPricePerTray > 0) {
        _pricePerTrayController.text = _defaultPricePerTray.toStringAsFixed(0);
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trayCountController.dispose();
    _notesController.dispose();
    _pricePerTrayController.dispose();
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pricePerTrayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tuxum narxi (fletka)',
                      border: OutlineInputBorder(),
                      suffixText: "so'm",
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) return null; // optional
                      final d = double.tryParse(value!);
                      if (d == null || d <= 0) return 'To\'g\'ri narx kiriting';
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
    final note = _notesController.text.isNotEmpty
        ? _notesController.text
        : null;

    // Save default price if provided
    final enteredPrice = double.tryParse(_pricePerTrayController.text);
    if (enteredPrice != null && enteredPrice > 0) {
      _defaultPricePerTray = enteredPrice;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('default_price_per_tray', enteredPrice);
      } catch (_) {}
    }

    final success = await farmProvider.addEggProduction(trayCount, note: note);

    if (success) {
      // Reset form
      _trayCountController.clear();
      _notesController.clear();
      // Keep price field as last used value
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tuxum yig\'imi muvaffaqiyatli saqlandi'),
          ),
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
      body: Consumer2<FarmProvider, SearchProvider>(
        builder: (context, farmProvider, sp, _) {
          final egg = farmProvider.farm?.egg;
          return Column(
            children: [
              // Modern Header with Gradient Background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
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
                            if (Navigator.canPop(context))
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).maybePop(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
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
                                Icons.egg_alt_rounded,
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
                                    'Tuxum Boshqaruvi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ishlab chiqarish va sotuvlarni kuzatish',
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
                              child: GestureDetector(
                                onTap: () => _showTodayProductionDetails(egg),
                                child: _buildModernStatCard(
                                  'Bugungi yigim',
                                  '${egg?.todayProduction ?? 0}',
                                  'fletka',
                                  Icons.today_rounded,
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernStatCard(
                                'Joriy zaxira',
                                '${egg?.currentStock ?? 0}',
                                'fletka',
                                Icons.inventory_rounded,
                                Colors.amber[300]!,
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
                  Tab(child: Text('Ishlab Chiqarish')),
                  Tab(child: Text('Sotuvlar')),
                  Tab(child: Text('Siniq')),
                  Tab(child: Text('Katta')),
                ],
              ),

              // Note: Search removed for eggs screen per requirements

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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'eggs_fab',
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
                  '${egg.productionStats?['totalProduction'] ?? 0} fletka',
                  Icons.production_quantity_limits,
                ),
                _buildStatCard(
                  'Eng Ko\'p Kun',
                  egg.productionStats?['mostProductionDay'] != null
                      ? '${egg.productionStats!['mostProductionDay']['count']} fletka'
                      : 'Ma\'lumot yo\'q',
                  Icons.trending_up,
                ),
                _buildStatCard(
                  'O\'rtacha Kunlik',
                  '${(egg.productionStats?['averageProduction'] ?? 0.0).toStringAsFixed(1)} fletka',
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
                      '${egg.sales?.fold(0, (sum, sale) => sum + sale.trayCount) ?? 0} fletka',
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
                  value: '${egg.sales?.length ?? 0} ta',
                  icon: Icons.receipt,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Bugungi daromad (sum of today's sales)
            Builder(
              builder: (context) {
                final now = DateTime.now();
                double todaysRevenue = 0;
                for (final s in (egg.sales ?? [])) {
                  if (s.date.year == now.year &&
                      s.date.month == now.month &&
                      s.date.day == now.day) {
                    todaysRevenue += (s.trayCount * (s.pricePerTray ?? 0));
                  }
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      const Text(
                        'Daromad:',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${todaysRevenue.toStringAsFixed(0)} so\'m',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            // Recent sales list (filtered, themed)
            Builder(
              builder: (context) {
                final sp = Provider.of<SearchProvider>(context);
                final q = sp.query.trim().toLowerCase();
                final min = sp.minAmount;
                final max = sp.maxAmount;
                final from = sp.fromDate;
                final to = sp.toDate;

                final sales = (egg.sales ?? [])
                    .where((s) {
                      if (q.isNotEmpty) {
                        final note = (s.note ?? '').toLowerCase();
                        final dateStr = '${s.date.year}-${s.date.month}-${s.date.day}'.toLowerCase();
                        final amount = (s.trayCount * (s.pricePerTray ?? 0)).toString();
                        if (!(note.contains(q) || dateStr.contains(q) || amount.contains(q))) {
                          return false;
                        }
                      }
                      if (from != null && s.date.isBefore(from)) return false;
                      if (to != null && s.date.isAfter(to)) return false;
                      final total = s.trayCount * (s.pricePerTray ?? 0);
                      if (min != null && total < min) return false;
                      if (max != null && total > max) return false;
                      return true;
                    })
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'So\'nggi Sotuvlar (${sales.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sales.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.search_off, color: Colors.grey[500]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sotuvlar topilmadi',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          itemCount: sales.length.clamp(0, 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = sales[index];
                            final total = (s.trayCount * (s.pricePerTray ?? 0)).toStringAsFixed(0);
                            return InkWell(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.sell, color: Theme.of(context).colorScheme.secondary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${s.trayCount} fletka · ${total} so\'m',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            s.note?.isNotEmpty == true ? s.note! : 'Izoh yo\'q',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormat('yyyy-MM-dd').format(s.date),
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
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
                  value: '${egg.todayBroken ?? 0} fletka',
                  icon: Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Umumiy Siniq',
                  value: '${egg.brokenStats?['totalBroken'] ?? 0} fletka',
                  icon: Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Eng Ko\'p Siniq Kun',
                  value: egg.brokenStats?['mostBrokenDay'] != null
                      ? '${egg.brokenStats!['mostBrokenDay']['count']} fletka'
                      : 'Ma\'lumot yo\'q',
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Siniq Bo\'lmagan Kunlar',
                  value: '${egg.brokenStats?['zeroBrokenDays'] ?? 0} kun',
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
                  value: '${egg.todayLarge ?? 0} fletka',
                  icon: Icons.expand,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                StatCard(
                  title: 'Umumiy Katta',
                  value: '${egg.largeEggStats?['totalLarge'] ?? 0} fletka',
                  icon: Icons.expand_circle_down,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                StatCard(
                  title: 'Eng Ko\'p Katta Kun',
                  value: egg.largeEggStats?['mostLargeDay'] != null
                      ? '${egg.largeEggStats!['mostLargeDay']['count']} fletka'
                      : 'Ma\'lumot yo\'q',
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatCard(
                  title: 'O\'rtacha Kunlik',
                  value:
                      '${(egg.largeEggStats?['averageLarge'] ?? 0.0).toStringAsFixed(1)} fletka',
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
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final currentStock = farmProvider.farm?.egg?.currentStock ?? 0;

    // Controllers
    final trayController = TextEditingController();
    final priceController = TextEditingController(
      text: _defaultPricePerTray > 0
          ? _defaultPricePerTray.toStringAsFixed(0)
          : '',
    );
    final totalController = TextEditingController();
    final paidController = TextEditingController();
    final remainingController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void calculateAmounts() {
      final count = int.tryParse(trayController.text) ?? 0;
      final price = double.tryParse(priceController.text) ?? 0.0;
      final paid = double.tryParse(paidController.text) ?? 0.0;
      final total = count * price;
      final remaining = total - paid;

      totalController.text = total > 0 ? total.toStringAsFixed(0) : '';
      remainingController.text = remaining != 0
          ? remaining.toStringAsFixed(0)
          : '0';
    }

    // Listen to changes
    trayController.addListener(calculateAmounts);
    priceController.addListener(calculateAmounts);
    paidController.addListener(calculateAmounts);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSubmitting = false;
          return AlertDialog(
            title: const Text('Tuxum Sotish'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mavjud zaxira: $currentStock fletka',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mijoz ma'lumotlari
                    const Text(
                      'Mijoz ma\'lumotlari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Mijoz ismi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Ism kiritish majburiy'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon raqami',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true)
                          return 'Telefon kiritish majburiy';
                        final digits = v!.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 7)
                          return 'Telefon raqami juda qisqa';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Manzil (ixtiyoriy)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tuxum ma'lumotlari
                    const Text(
                      'Tuxum ma\'lumotlari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: trayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sotilgan fletka soni',
                        border: OutlineInputBorder(),
                        suffixText: 'fletka',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0)
                          return 'To\'g\'ri son kiriting';
                        if (n > currentStock) return 'Yetarli zaxira yo\'q';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fletka narxi',
                        border: OutlineInputBorder(),
                        suffixText: "so'm",
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d <= 0)
                          return 'To\'g\'ri narx kiriting';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: totalController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Umumiy summa',
                        border: const OutlineInputBorder(),
                        suffixText: "so'm",
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.1),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // To'lov ma'lumotlari
                    const Text(
                      'To\'lov ma\'lumotlari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: paidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mijoz bergan pul',
                        border: OutlineInputBorder(),
                        suffixText: "so'm",
                        hintText: '0',
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '0');
                        if (d == null || d < 0)
                          return 'To\'g\'ri summa kiriting';

                        // Check if paid amount is more than total
                        final count = int.tryParse(trayController.text) ?? 0;
                        final price =
                            double.tryParse(priceController.text) ?? 0.0;
                        final total = count * price;

                        if (d > total && total > 0) {
                          return 'Bergan pul (${d.toStringAsFixed(0)}) umumiy summadan (${total.toStringAsFixed(0)}) ko\'p bo\'lmasligi kerak';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remainingController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Qolgan qarz',
                        border: const OutlineInputBorder(),
                        suffixText: "so'm",
                        filled: true,
                        fillColor: Colors.red.withOpacity(0.1),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (isSubmitting) return;
                  if (formKey.currentState!.validate()) {
                    isSubmitting = true;
                    setStateDialog(() {});
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();
                    final count = int.parse(trayController.text);
                    final price = double.parse(priceController.text);
                    final paid = double.tryParse(paidController.text) ?? 0.0;
                    final total = count * price;
                    final remaining = total - paid;

                    final success = await farmProvider.addEggSaleWithCustomer(
                      customerName: name,
                      customerPhone: phone,
                      customerAddress: address,
                      trayCount: count,
                      pricePerTray: price,
                      paidAmount: paid,
                      onSuccess: () {
                        // Switch to customers tab after successful sale with new customer
                        MainScreen.switchToCustomersTab();
                      },
                    );

                    // Safe navigation check
                    if (context.mounted) {
                      Navigator.pop(context);

                      if (success) {
                        // Ensure navigation to Customers tab even if callback timing changes
                        MainScreen.switchToCustomersTab();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$name ga $count fletka tuxum sotildi.\n'
                              'Umumiy: ${total.toStringAsFixed(0)} so\'m\n'
                              'To\'landi: ${paid.toStringAsFixed(0)} so\'m\n'
                              'Qarz: ${remaining.toStringAsFixed(0)} so\'m',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              farmProvider.error ?? 'Xatolik yuz berdi',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    isSubmitting = false;
                    setStateDialog(() {});
                  }
                },
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Sotish'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddBrokenDialog(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final currentStock = farmProvider.farm?.egg?.currentStock ?? 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siniq Tuxum Kiritish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mavjud zaxira: $currentStock fletka',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Siniq fletka soni',
                border: OutlineInputBorder(),
                suffixText: 'fletka',
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

              if (count == null || count <= 0) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('To\'g\'ri son kiriting'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              if (count > currentStock) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Yetarli tuxum yo\'q! Mavjud: $currentStock fletka',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final success = await farmProvider.addBrokenEgg(count);

              if (context.mounted) {
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$count fletka siniq tuxum muvaffaqiyatli kiritildi',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  // Return to main dashboard tab after successful insert
                  try {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).maybePop();
                  } catch (_) {}
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(farmProvider.error ?? 'Xatolik yuz berdi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final currentStock = farmProvider.farm?.egg?.currentStock ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katta Tuxum Kiritish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mavjud zaxira: $currentStock fletka',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Katta tuxum fletka soni',
                border: OutlineInputBorder(),
                suffixText: 'fletka',
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
                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
                final success = await farmProvider.addLargeEgg(count);

                if (context.mounted) {
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$count fletka katta tuxum muvaffaqiyatli kiritildi',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          farmProvider.error ?? 'Xatolik yuz berdi',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
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

  void _showTodayProductionDetails(egg) {
    if (egg == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcha Statistika'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bugungi ma'lumotlar
              const Text(
                'Bugungi ma\'lumotlar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Bugungi yig\'im:',
                '${egg.todayProduction ?? 0} fletka',
              ),
              _buildDetailRow(
                'Bugungi sotuv:',
                '${egg.todaySales ?? 0} fletka',
              ),
              _buildDetailRow(
                'Bugungi siniq:',
                '${egg.todayBroken ?? 0} fletka',
              ),
              _buildDetailRow(
                'Bugungi katta:',
                '${egg.todayLarge ?? 0} fletka',
              ),

              const Divider(),

              // Umumiy ma'lumotlar
              const Text(
                'Umumiy statistika:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Joriy zaxira:',
                '${egg.currentStock ?? 0} fletka',
              ),
              _buildDetailRow(
                'Umumiy ishlab chiqarish:',
                '${egg.productionStats?['totalProduction'] ?? 0} fletka',
              ),
              _buildDetailRow(
                'O\'rtacha kunlik:',
                '${(egg.productionStats?['averageProduction'] ?? 0.0).toStringAsFixed(1)} fletka',
              ),
              if (egg.productionStats?['mostProductionDay'] != null)
                _buildDetailRow(
                  'Eng ko\'p yig\'ilgan kun:',
                  '${egg.productionStats!['mostProductionDay']['count']} fletka',
                ),

              const Divider(),

              // Sotuvlar statistikasi
              const Text(
                'Sotuvlar statistikasi:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Umumiy sotuv:',
                '${egg.sales?.fold(0, (sum, sale) => sum + sale.trayCount) ?? 0} fletka',
              ),

              const Divider(),

              // Siniq tuxumlar statistikasi
              const Text(
                'Siniq tuxumlar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Umumiy siniq:',
                '${egg.brokenStats?['totalBroken'] ?? 0} fletka',
              ),
              if (egg.brokenStats?['mostBrokenDay'] != null)
                _buildDetailRow(
                  'Eng ko\'p siniq kun:',
                  '${egg.brokenStats!['mostBrokenDay']['count']} fletka',
                ),

              const Divider(),

              // Katta tuxumlar statistikasi
              const Text(
                'Katta tuxumlar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Umumiy katta:',
                '${egg.largeEggStats?['totalLarge'] ?? 0} fletka',
              ),
              _buildDetailRow(
                'O\'rtacha kunlik katta:',
                '${(egg.largeEggStats?['averageLarge'] ?? 0.0).toStringAsFixed(1)} fletka',
              ),
              if (egg.largeEggStats?['mostLargeDay'] != null)
                _buildDetailRow(
                  'Eng ko\'p katta kun:',
                  '${egg.largeEggStats!['mostLargeDay']['count']} fletka',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.blue)),
      ],
    ),
  );
}
