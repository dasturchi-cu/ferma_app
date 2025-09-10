import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/farm_provider.dart';
import '../../widgets/stat_card.dart';
import '../../models/egg.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobotlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDatePicker(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getMonthName(_selectedMonth)} $_selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showDatePicker(),
                  child: const Text('O\'zgartirish'),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Umumiy'),
              Tab(text: 'Tuxum'),
              Tab(text: 'Moliya'),
              Tab(text: 'Mijozlar'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewReport(),
                _buildEggReport(),
                _buildFinanceReport(),
                _buildCustomerReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null) {
          return const Center(child: Text('Ma\'lumot yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Umumiy ko\'rsatkichlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    title: 'Jami Tovuqlar',
                    value: '${farm.chicken?.currentCount ?? 0}',
                    icon: Icons.pets,
                    color: AppTheme.primaryColor,
                  ),
                  StatCard(
                    title: 'Jami Tuxum',
                    value: '${farm.egg?.currentStock ?? 0}',
                    icon: Icons.egg,
                    color: AppTheme.primaryColor,
                  ),
                  StatCard(
                    title: 'Jami Mijozlar',
                    value: '${farm.customers.length}',
                    icon: Icons.people,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Jami Qarz',
                    value: '${_calculateTotalDebt(farm.customers)} som',
                    icon: Icons.warning,
                    color: AppTheme.warning,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Bu oylik statistika',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _buildMonthlySummaryCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEggReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null || farm.egg == null) {
          return const Center(child: Text('Tuxum ma\'lumotlari yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tuxum hisoboti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    title: 'Yig\'ilgan Tuxum',
                    value: '${_getTotalEggProduction(farm.egg)} fletka',
                    icon: Icons.egg,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    title: 'Sotilgan Tuxum',
                    value: '${_getTotalEggSales(farm.egg)} fletka',
                    icon: Icons.shopping_cart,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Siniq Tuxum',
                    value: '${_getTotalBrokenEggs(farm.egg)} fletka',
                    icon: Icons.broken_image,
                    color: AppTheme.error,
                  ),
                  StatCard(
                    title: 'Katta Tuxum',
                    value: '${_getTotalLargeEggs(farm.egg)} fletka',
                    icon: Icons.expand,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildEggChart(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null) {
          return const Center(child: Text('Moliyaviy ma\'lumotlar yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Moliyaviy hisobot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    title: 'Jami Daromad',
                    value: '${_getTotalRevenue(farm.egg)} som',
                    icon: Icons.trending_up,
                    color: AppTheme.success,
                  ),
                  StatCard(
                    title: 'Jami Xarajat',
                    value: '0 som', // TODO: Add expenses tracking
                    icon: Icons.trending_down,
                    color: AppTheme.error,
                  ),
                  StatCard(
                    title: 'Sof Foyda',
                    value: '${_getTotalRevenue(farm.egg)} som',
                    icon: Icons.attach_money,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'O\'rtacha Kun Daromadi',
                    value: '${_getAverageDailyRevenue(farm.egg)} som',
                    icon: Icons.calendar_today,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerReport() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        if (farm == null || farm.customers.isEmpty) {
          return const Center(child: Text('Mijozlar ma\'lumotlari yo\'q'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mijozlar hisoboti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    title: 'Jami Mijozlar',
                    value: '${farm.customers.length}',
                    icon: Icons.people,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'Qarzdor Mijozlar',
                    value: '${_getDebtorCustomers(farm.customers)}',
                    icon: Icons.warning,
                    color: AppTheme.warning,
                  ),
                  StatCard(
                    title: 'Jami Qarz',
                    value: '${_calculateTotalDebt(farm.customers)} som',
                    icon: Icons.money_off,
                    color: AppTheme.error,
                  ),
                  StatCard(
                    title: 'Faol Mijozlar',
                    value: '${_getActiveCustomers(farm.customers)}',
                    icon: Icons.person,
                    color: AppTheme.success,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildCustomerList(farm.customers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Oylik xulosa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu oy uchun avtomatik hisobot tez orada tayyorlanadi.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEggChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuxum trendi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              child: const Center(
                child: Text(
                  'Grafik tez orada qo\'shiladi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List customers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eng ko\'p qarzdor mijozlar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...customers
                .take(5)
                .map(
                  (customer) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(customer.name),
                    subtitle: Text('${customer.totalDebt} som qarz'),
                    trailing: customer.totalDebt > 0
                        ? const Icon(Icons.warning, color: Colors.orange)
                        : const Icon(Icons.check, color: Colors.green),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sana tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: _selectedMonth,
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(_getMonthName(index + 1)),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                  });
                }
              },
            ),
            DropdownButton<int>(
              value: _selectedYear,
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: DateTime.now().year - index,
                  child: Text('${DateTime.now().year - index}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Tanlash'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hisobotni eksport qilish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Excel eksport tez orada qo\'shiladi');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('PDF eksport tez orada qo\'shiladi');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    return months[month - 1];
  }

  // Helper methods for calculations
  double _calculateTotalDebt(List customers) {
    return customers.fold(0.0, (sum, customer) => sum + customer.totalDebt);
  }

  int _getTotalEggProduction(Egg? egg) {
    if (egg == null) return 0;
    return egg.production.fold(0, (sum, prod) => sum + prod.trayCount);
  }

  int _getTotalEggSales(Egg? egg) {
    if (egg == null) return 0;
    return egg.sales.fold(0, (sum, sale) => sum + sale.trayCount);
  }

  int _getTotalBrokenEggs(Egg? egg) {
    if (egg == null) return 0;
    return egg.brokenEggs.fold(0, (sum, broken) => sum + broken.trayCount);
  }

  int _getTotalLargeEggs(Egg? egg) {
    if (egg == null) return 0;
    return egg.largeEggs.fold(0, (sum, large) => sum + large.trayCount);
  }

  double _getTotalRevenue(Egg? egg) {
    if (egg == null) return 0;
    return egg.sales.fold(
      0.0,
      (sum, sale) => sum + (sale.trayCount * sale.pricePerTray),
    );
  }

  double _getAverageDailyRevenue(Egg? egg) {
    if (egg == null || egg.sales.isEmpty) return 0;

    final totalRevenue = _getTotalRevenue(egg);
    final firstSaleDate = egg.sales
        .map((s) => s.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final days = DateTime.now().difference(firstSaleDate).inDays;

    return days > 0 ? totalRevenue / days : totalRevenue;
  }

  int _getDebtorCustomers(List customers) {
    return customers.where((customer) => customer.totalDebt > 0).length;
  }

  int _getActiveCustomers(List customers) {
    return customers.length; // TODO: Add logic for active customers
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryColor),
    );
  }
}
