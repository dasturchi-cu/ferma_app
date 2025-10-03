import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import '../../models/customer.dart';
import '../../widgets/search_bar_with_filters.dart';
import '../../providers/search_provider.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Start initial animations so items are visible
    _animationController.forward();

    // Force refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Customer> _getFilteredDebts(
    List<Customer> customers,
    SearchProvider sp,
  ) {
    // Show ONLY debt-only customers (QARZ:) having unpaid debt
    final debtCustomers = customers
        .where((c) => c.name.startsWith('QARZ:') && c.totalDebt > 0)
        .where((c) {
          // query filter (name/phone)
          final q = sp.query.trim().toLowerCase();
          if (q.isNotEmpty) {
            final name = c.name.replaceFirst('QARZ: ', '').toLowerCase();
            final phone = c.phone.toLowerCase();
            if (!(name.contains(q) || phone.contains(q))) return false;
          }
          // amount range filter
          if (sp.minAmount != null && c.totalDebt < sp.minAmount!) return false;
          if (sp.maxAmount != null && c.totalDebt > sp.maxAmount!) return false;
          // date range filter (by unpaid order delivery dates)
          if (sp.fromDate != null || sp.toDate != null) {
            final from = sp.fromDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final to = sp.toDate ?? DateTime(2100);
            final hasInRange = c.orders.any(
              (o) =>
                  !o.isPaid &&
                  o.deliveryDate.isAfter(
                    from.subtract(const Duration(days: 1)),
                  ) &&
                  o.deliveryDate.isBefore(to.add(const Duration(days: 1))),
            );
            if (!hasInRange) return false;
          }
          // status filter (optional)
          if (sp.status != null) {
            final now = DateTime.now();
            if (sp.status == 'overdue') {
              final overdue = c.orders.any(
                (o) => !o.isPaid && o.deliveryDate.isBefore(now),
              );
              if (!overdue) return false;
            } else if (sp.status == 'completed') {
              // Debts page shows unpaid; completed means zero debt
              if (c.totalDebt > 0) return false;
            }
          }
          return true;
        })
        .map(
          (customer) => Customer(
            id: customer.id,
            name: customer.name.replaceFirst('QARZ: ', ''),
            phone: customer.phone,
            address: customer.address,
            orders: customer.orders,
          ),
        )
        .toList();

    print('🔍 Qarzdorlar ro\'yxati: ${debtCustomers.length} ta');
    for (var customer in debtCustomers) {
      print('  - ${customer.name} (qarz: ${customer.totalDebt})');
    }

    if (_searchQuery.isEmpty) return debtCustomers;
    return debtCustomers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  double _getTotalDebt(List<Customer> customers) {
    // Only count dedicated debt-only customers (names prefixed with 'QARZ:')
    return customers
        .where((c) => c.name.startsWith('QARZ:'))
        .fold(0.0, (sum, customer) => sum + customer.totalDebt);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FarmProvider, SearchProvider>(
      builder: (context, farmProvider, sp, child) {
        final farm = farmProvider.farm;
        final customers = farm?.customers ?? [];
        final filteredDebts = _getFilteredDebts(customers, sp);
        // Count only debt-only customers in totals shown on Debts screen
        final totalDebt = _getTotalDebt(customers);

        // Debug: Force rebuild when customers change
        print(
          '🔄 Qarz sahifasi yangilandi. Mijozlar: ${customers.length}, Qarzdorlar: ${filteredDebts.length}',
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF5F9FF), // Och ko'k fon
          body: Column(
            children: [
              // Modern Blue Gradient Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E88E5), // Asosiy ko'k
                      const Color(0xFF64B5F6), // Ochiq ko'k
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Qarz Daftari',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qarzdor mijozlar va to\'lovlar',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Statistics button
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showStatistics(customers),
                                borderRadius: BorderRadius.circular(12),
                                child: const Icon(
                                  Icons.analytics_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Modern Blue Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernStatCard(
                                'Qarzdorlar',
                                '${filteredDebts.length}',
                                'mijoz',
                                Icons.people_outline_rounded,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernStatCard(
                                'Umumiy qarz',
                                '${totalDebt.toStringAsFixed(0)}',
                                "so'm",
                                Icons.account_balance_wallet_outlined,
                                totalDebt > 0
                                    ? const Color(0xFFFFEB3B)
                                    : const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Search bar with filters (debounced)
              if (customers.where((c) => c.totalDebt > 0).isNotEmpty)
                const SearchBarWithFilters(
                  hintText: 'Mijoz ismi yoki telefon...',
                  showAmount: true,
                  showStatus: false,
                ),

              // Main content
              Expanded(
                child: Builder(
                  builder: (context) {
                    print(
                      '🎯 UI render: filteredDebts=${filteredDebts.length}, customers=${customers.length}',
                    );

                    if (filteredDebts.isEmpty &&
                        customers.where((c) => c.totalDebt > 0).isNotEmpty) {
                      print('🎯 Ko\'rsatilmoqda: _buildNotFound()');
                      return _buildNotFound();
                    } else if (customers
                        .where((c) => c.totalDebt > 0)
                        .isEmpty) {
                      print('🎯 Ko\'rsatilmoqda: _buildEmpty()');
                      return _buildEmpty();
                    } else {
                      print(
                        '🎯 Ko\'rsatilmoqda: _buildList() with ${filteredDebts.length} items',
                      );
                      return _buildList(filteredDebts);
                    }
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: 'debt_fab',
              onPressed: () => _showAddDebtDialog(context),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'Yangi mijoz',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
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
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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

  // Legacy search removed; SearchBarWithFilters is used instead

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Hozircha qarz yozuvi yo'q",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Birinchi qarzni qo'shish uchun pastdagi tugmani bosing",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Hech narsa topilmadi",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Customer> filteredDebts) {
    // Restart animation on rebuild to ensure items slide into view
    _animationController.reset();
    _animationController.forward();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDebts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = filteredDebts[index];
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                ),
              ),
          child: _buildCustomerCard(customer),
        );
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final isHighDebt = customer.totalDebt > 1000000;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCustomerDetails(customer),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHighDebt
                          ? [const Color(0xFFF44336), const Color(0xFFE91E63)]
                          : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isHighDebt
                                    ? const Color(0xFFF44336)
                                    : const Color(0xFF2196F3))
                                .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Qarz: ${customer.totalDebt.toStringAsFixed(0)} so\'m',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (customer.phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.payment_outlined,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        onPressed: () => _showPaymentDialog(customer),
                        tooltip: 'To\'lov qilish',
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.list_alt_outlined,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                        onPressed: () => _showOrdersDialog(customer),
                        tooltip: 'Buyurtmalar',
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final debtController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_add,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Qarz Qo\'shish'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fermaga aloqasi yo\'q qarz qo\'shish',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Qarzdor ismi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Ism kiritish majburiy'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telefon raqami',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true)
                      return 'Telefon kiritish majburiy';
                    final digits = v!.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 7) return 'Telefon raqami juda qisqa';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Manzil (ixtiyoriy)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: debtController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qarz miqdori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.money,
                      color: Color(0xFF2196F3),
                    ),
                    suffixText: "so'm",
                  ),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d <= 0) return 'To\'g\'ri summa kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.note,
                      color: Color(0xFF2196F3),
                    ),
                    hintText: 'Qarz sababi haqida...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
                final success = await farmProvider.addManualDebt(
                  customerName: nameController.text.trim(),
                  customerPhone: phoneController.text.trim(),
                  customerAddress: addressController.text.trim(),
                  debtAmount: double.parse(debtController.text),
                  note: noteController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);

                  if (success) {
                    _showSnackBar(
                      '${nameController.text.trim()} ga ${debtController.text} so\'m qarz qo\'shildi',
                      const Color(0xFF4CAF50),
                    );

                    // Force UI refresh after adding debt
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                    setState(() {});
                  } else {
                    _showSnackBar(
                      farmProvider.error ?? 'Xatolik yuz berdi',
                      const Color(0xFFF44336),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Qarz Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Customer customer) {
    final unpaidOrders = customer.orders
        .where((order) => !order.isPaid)
        .toList();

    if (unpaidOrders.isEmpty) {
      _showSnackBar(
        'Bu mijozda to\'lanmagan buyurtmalar yo\'q',
        const Color(0xFFFFA726),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payment,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Buyurtmalarni to\'lash'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mijoz: ${customer.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Umumiy qarz: ${customer.totalDebt.toStringAsFixed(0)} so\'m',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'To\'lanmagan buyurtmalar:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: unpaidOrders.length,
                  itemBuilder: (context, index) {
                    final order = unpaidOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text('${order.trayCount} fletka'),
                        subtitle: Text(
                          'Narx: ${order.totalAmount.toStringAsFixed(0)} so\'m\n'
                          'Sana: ${order.deliveryDate.day}.${order.deliveryDate.month}.${order.deliveryDate.year}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            // Summa so'rash
                            final controller = TextEditingController(
                              text: order.totalAmount.toStringAsFixed(0),
                            );
                            final paid = await showDialog<double>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('To\'lov summasi'),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Summani kiriting',
                                    suffixText: "so'm",
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Bekor'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final v = double.tryParse(
                                        controller.text,
                                      );
                                      Navigator.pop(ctx, v);
                                    },
                                    child: const Text('Tasdiqlash'),
                                  ),
                                ],
                              ),
                            );
                            if (paid == null) return;

                            final farmProvider = Provider.of<FarmProvider>(
                              context,
                              listen: false,
                            );

                            bool success;
                            if (paid >= order.totalAmount) {
                              success = await farmProvider
                                  .markCustomerOrderAsPaid(
                                    customer.id,
                                    order.id,
                                  );
                            } else {
                              success = await farmProvider
                                  .payCustomerOrderAmount(
                                    customer.id,
                                    order.id,
                                    paid,
                                  );
                            }

                            if (success) {
                              if (mounted) Navigator.pop(context);
                              _showSnackBar(
                                'To\'lov qabul qilindi',
                                const Color(0xFF4CAF50),
                              );
                            } else {
                              _showSnackBar(
                                'Xatolik yuz berdi',
                                const Color(0xFFF44336),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'To\'lash',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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

  // Removed unused helper _markOrderAsPaid to avoid linter warning

  void _showOrdersDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${customer.name} buyurtmalari'),
        content: SizedBox(
          width: double.maxFinite,
          child: customer.orders.isEmpty
              ? const Text('Hali buyurtmalar yo\'q')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: customer.orders.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = customer.orders.reversed.toList()[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: order.isPaid
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        child: Icon(
                          order.isPaid ? Icons.check : Icons.schedule,
                          color: order.isPaid
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFA726),
                          size: 18,
                        ),
                      ),
                      title: Text('${order.trayCount} fletka'),
                      subtitle: Text(
                        'Narx: ${order.totalAmount.toStringAsFixed(0)} so\'m\n'
                        'Sana: ${order.deliveryDate.day}.${order.deliveryDate.month}.${order.deliveryDate.year}',
                      ),
                      trailing: Text(
                        order.isPaid ? 'To\'langan' : 'Kutilmoqda',
                        style: TextStyle(
                          color: order.isPaid
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFA726),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
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

  void _showCustomerDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
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
                        customer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer.phone.isNotEmpty)
                        Text(
                          customer.phone,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      if (customer.address.isNotEmpty)
                        Text(
                          customer.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    const Color(0xFF1976D2).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Umumiy qarz',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${customer.totalDebt.toStringAsFixed(0)} so\'m',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPaymentDialog(customer);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('To\'lov'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showOrdersDialog(customer);
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Buyurtmalar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF2196F3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics(List<Customer> customers) {
    // Consider ONLY debt-only customers ('QARZ:') for statistics
    final customersWithDebt = customers
        .where((c) => c.name.startsWith('QARZ:') && c.totalDebt > 0)
        .toList();

    if (customersWithDebt.isEmpty) {
      _showSnackBar(
        'Statistika ko\'rish uchun qarzdor mijozlar kerak',
        Colors.grey,
      );
      return;
    }

    final totalDebt = _getTotalDebt(customers);
    final maxDebtCustomer = customersWithDebt.reduce(
      (a, b) => a.totalDebt > b.totalDebt ? a : b,
    );
    final minDebtCustomer = customersWithDebt.reduce(
      (a, b) => a.totalDebt < b.totalDebt ? a : b,
    );
    final avgDebt = totalDebt / customersWithDebt.length;
    final totalOrders = customers.fold(
      0,
      (sum, customer) => sum + customer.orders.length,
    );
    final paidOrders = customers.fold(
      0,
      (sum, customer) => sum + customer.orders.where((o) => o.isPaid).length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Qarz Statistikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
              'Qarzdor mijozlar:',
              '${customersWithDebt.length} ta',
            ),
            _buildStatRow(
              'Umumiy qarz:',
              '${totalDebt.toStringAsFixed(0)} so\'m',
            ),
            _buildStatRow(
              'O\'rtacha qarz:',
              '${avgDebt.toStringAsFixed(0)} so\'m',
            ),
            _buildStatRow(
              'Eng katta qarz:',
              '${maxDebtCustomer.totalDebt.toStringAsFixed(0)} so\'m (${maxDebtCustomer.name})',
            ),
            _buildStatRow(
              'Eng kichik qarz:',
              '${minDebtCustomer.totalDebt.toStringAsFixed(0)} so\'m (${minDebtCustomer.name})',
            ),
            const Divider(height: 24),
            // Top 5 qarzdorlar ro'yxati (ism bilan birga ko'rsatamiz)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Top qarzdorlar:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            ...(() {
              final list = List<Customer>.from(customersWithDebt);
              list.sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
              return list
                  .take(5)
                  .map((c) => _buildStatRow(
                        c.name,
                        '${c.totalDebt.toStringAsFixed(0)} so\'m',
                      ))
                  .toList();
            })(),
            const Divider(height: 24),
            _buildStatRow('Jami buyurtmalar:', '$totalOrders ta'),
            _buildStatRow('To\'langan:', '$paidOrders ta'),
            _buildStatRow('To\'lanmagan:', '${totalOrders - paidOrders} ta'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
