import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/service_provider.dart';
import '../../services/realtime_service.dart';
import '../../providers/farm_provider.dart';
import '../../widgets/chart_widget.dart';
import '../../widgets/stat_card.dart';
import '../../utils/app_theme.dart';

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
  
  // Chart data
  List<ChartData> _dailyEggsData = [];
  List<ChartData> _salesData = [];
  List<ChartData> _debtorsData = [];
  
  // Loading states
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Realtime service
  late RealtimeService _realtimeService;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serviceProvider = ServiceProvider.of(context);
    _realtimeService = serviceProvider.realtimeService;
    _loadData();
    _setupRealtimeSubscriptions();
  }
  
  @override
  void dispose() {
    _realtimeService.unsubscribeAll();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final farmProvider = Provider.of<FarmProvider>(context, listen: false);
      
      // Load daily eggs data
      final DateTimeRange dateRange = DateTimeRange(
        start: DateTime(_selectedYear, _selectedMonth, 1),
        end: DateTime(_selectedYear, _selectedMonth + 1, 0),
      );
      
      // Fetch data in parallel
      await Future.wait([
        _loadDailyEggsData(farmProvider, dateRange),
        _loadSalesData(farmProvider, dateRange),
        _loadDebtorsData(farmProvider),
      ]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Xatolik yuz berdi: $e';
        });
      }
    }
  }
  
  Future<void> _loadDailyEggsData(FarmProvider farmProvider, DateTimeRange dateRange) async {
    try {
      final eggRecords = await farmProvider.getEggRecordsByDateRange(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      // Group egg records by date
      final dailyEggs = <String, double>{};
      
      for (final record in eggRecords) {
        final date = DateFormat('MMM d').format(record.date);
        dailyEggs[date] = (dailyEggs[date] ?? 0) + record.totalEggs.toDouble();
      }

      setState(() {
        _dailyEggsData = dailyEggs.entries
            .map((e) => ChartData(
                  x: e.key,
                  y: e.value.toDouble(),
                  label: '${e.value} tuxum',
                ))
            .toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Tuxum ma\'lumotlarini yuklashda xatolik: $e';
      });
    }
  }
  
  Future<void> _loadSalesData(
    FarmProvider farmProvider, 
    DateTimeRange dateRange
  ) async {
    final sales = await farmProvider.getSalesByDateRange(
      dateRange.start,
      dateRange.end,
    );
    
    if (!mounted) return;
    
    // Group sales by day
    final salesByDay = <int, double>{};
    for (final sale in sales) {
      final day = sale.date.day;
      salesByDay[day] = (salesByDay[day] ?? 0) + sale.totalAmount;
    }
    
    setState(() {
      _salesData = salesByDay.entries.map((entry) => ChartData(
        x: entry.key,
        y: entry.value,
        label: '${entry.key}-kun',
      )).toList();
    });
  }
  
  Future<void> _loadDebtorsData(FarmProvider farmProvider) async {
    final customers = await farmProvider.getCustomersWithDebt();
    
    if (!mounted) return;
    
    setState(() {
      _debtorsData = customers.map((customer) => ChartData(
        x: customer.name,
        y: customer.debtAmount,
        label: customer.name,
      )).toList();
    });
  }
  
  void _setupRealtimeSubscriptions() {
    final realtimeService = ServiceProvider().realtime;
    
    // Subscribe to egg records changes
    realtimeService.subscribeToEggRecords(onEggRecordChanged: (payload) {
      if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE' || payload.eventType == 'DELETE') {
        if (mounted) {
          _loadData();
        }
      }
    });
    
    // Subscribe to sales changes
    realtimeService.subscribeToTable(
      table: 'sales', 
      event: '*',
      callback: (payload) {
        if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE' || payload.eventType == 'DELETE') {
          if (mounted) {
            _loadData();
          }
        }
      },
    );
    
    // Subscribe to customer changes
    realtimeService.subscribeToCustomers(onCustomerChanged: (payload) {
      if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE' || payload.eventType == 'DELETE') {
        if (mounted) {
          _loadData();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    _realtimeService = ServiceProvider().realtime;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupRealtimeSubscriptions();
    });
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

          // Loading and error states
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildEggsTab(),
                  _buildFinanceTab(),
                  _buildCustomersTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Umumiy statistika',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Daily Eggs Chart
          if (_dailyEggsData.isNotEmpty)
            ChartWidget(
              title: 'Kunlik tuxum ishlab chiqarish',
              data: _dailyEggsData,
              xField: 'Kun',
              yField: 'Soni',
              chartType: ChartType.bar,
              color: Colors.blue,
            ),
            
          const SizedBox(height: 16),
          
          // Sales Chart
          if (_salesData.isNotEmpty)
            ChartWidget(
              title: 'Kunlik savdo',
              data: _salesData,
              xField: 'Kun',
              yField: 'Summa',
              chartType: ChartType.line,
              color: Colors.green,
            ),
            
          const SizedBox(height: 16),
          
          // Top Debtors Chart
          if (_debtorsData.isNotEmpty && _debtorsData.length <= 10) // Only show if not too many debtors
            ChartWidget(
              title: 'Qarzdorlar',
              data: _debtorsData,
              xField: 'Mijoz',
              yField: 'Qarz miqdori',
              chartType: ChartType.pie,
            ),
        ],
      ),
    );
  }

  Widget _buildEggsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_dailyEggsData.isNotEmpty)
            ChartWidget(
              title: 'Kunlik tuxum ishlab chiqarish',
              data: _dailyEggsData,
              xField: 'Kun',
              yField: 'Soni',
              chartType: ChartType.bar,
              color: Colors.blue,
            ),
          const SizedBox(height: 16),
          // Add more egg-related charts here
        ],
      ),
    );
  }

  Widget _buildFinanceTab() {
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
                    value: '${_getTotalRevenue()} som',
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
                    value: '${_getTotalRevenue()} som',
                    icon: Icons.attach_money,
                    color: AppTheme.info,
                  ),
                  StatCard(
                    title: 'O\'rtacha Kun Daromadi',
                    value: '${_getAverageDailyRevenue().toStringAsFixed(0)} som',
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

  Widget _buildCustomersTab() {
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

  int _getTotalEggProduction() {
    return _dailyEggsData.fold(0, (sum, data) => sum + data.y.toInt());
  }

  int _getTotalEggSales() {
    return _salesData.fold(0, (sum, data) => sum + data.y.toInt());
  }

  int _getTotalBrokenEggs() {
    return _dailyEggsData.fold(0, (sum, data) => sum + data.y.toInt() ~/ 10); // Assuming 10% broken eggs for demo
  }

  int _getTotalLargeEggs() {
    return _dailyEggsData.fold(0, (sum, data) => sum + (data.y.toInt() ~/ 4)); // Assuming 25% large eggs for demo
  }

  double _getTotalRevenue() {
    return _salesData.fold(0.0, (sum, data) => sum + data.y);
  }

  double _getAverageDailyRevenue() {
    if (_salesData.isEmpty) return 0;
    
    // If we have sales data but no date range, just return the total revenue
    if (_salesData.length == 1) return _getTotalRevenue();
    
    // Calculate the date range based on the selected month and year
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = _selectedMonth < 12 
        ? DateTime(_selectedYear, _selectedMonth + 1, 0)
        : DateTime(_selectedYear + 1, 1, 0);
    
    final days = lastDay.difference(firstDay).inDays + 1; // +1 to include both start and end days
    final totalRevenue = _getTotalRevenue();
    
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
