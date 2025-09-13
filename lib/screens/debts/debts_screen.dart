import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../providers/farm_provider.dart';
import '../../models/customer.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _getFilteredDebts(List<Customer> customers) {
    // Get all customers with debt (both regular and debt-only)
    final regularCustomersWithDebt = customers.where((customer) => !customer.name.startsWith('QARZ:') && customer.totalDebt > 0).toList();
    final debtOnlyCustomers = customers.where((customer) => customer.name.startsWith('QARZ:') && customer.totalDebt > 0).toList();
    
    // Clean debt customer names (remove QARZ: prefix for display)
    final cleanedDebtCustomers = debtOnlyCustomers.map((customer) {
      return Customer(
        id: customer.id,
        name: customer.name.replaceFirst('QARZ: ', ''),
        phone: customer.phone,
        address: customer.address,
        orders: customer.orders,
      );
    }).toList();
    
    final allCustomersWithDebt = [...regularCustomersWithDebt, ...cleanedDebtCustomers];
    
    if (_searchQuery.isEmpty) return allCustomersWithDebt;
    return allCustomersWithDebt
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  double _getTotalDebt(List<Customer> customers) {
    return customers.fold(0.0, (sum, customer) => sum + customer.totalDebt);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final customers = farm?.customers ?? [];
        final filteredDebts = _getFilteredDebts(customers);
        final totalDebt = _getTotalDebt(customers);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Qarz Daftari',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
        backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () => _showStatistics(customers),
                tooltip: 'Statistika',
              ),
            ],
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
          body: Column(
            children: [
              // Header statistika
              _buildHeaderStats(filteredDebts, totalDebt),

              // Qidiruv paneli
              if (customers.where((c) => c.totalDebt > 0).isNotEmpty) _buildSearchBar(),

              // Asosiy kontent
              Expanded(
                child: filteredDebts.isEmpty && customers.where((c) => c.totalDebt > 0).isNotEmpty
                    ? _buildNotFound()
                    : customers.where((c) => c.totalDebt > 0).isEmpty
                    ? _buildEmpty()
                    : _buildList(filteredDebts),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDebtDialog(context),
        backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Yangi mijoz',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            elevation: 4,
          ),
        );
      },
    );
  }

  Widget _buildHeaderStats(List<Customer> filteredDebts, double totalDebt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people_outline,
                label: 'Qarzdor mijozlar',
                value: '${filteredDebts.length}',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Umumiy qarz',
                value: '${totalDebt.toStringAsFixed(0)} so\'m',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Mijoz ismini qidirish...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Hozircha qarz yozuvi yo'q",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
    final unpaidOrders = customer.orders.where((order) => !order.isPaid).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCustomerDetails(customer),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHighDebt
                          ? [Colors.red[400]!, Colors.red[600]!]
                          : [
                              AppConstants.primaryColor.withOpacity(0.7),
                              AppConstants.primaryColor,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Ma'lumotlar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Qarz: ${customer.totalDebt.toStringAsFixed(0)} so\'m',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (customer.phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Tugmalar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.payment_outlined,
                        color: Colors.green[600],
                      ),
                      onPressed: () => _showPaymentDialog(customer),
                      tooltip: 'To\'lov qilish',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green[50],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.list_alt, color: Colors.blue[600]),
                      onPressed: () => _showOrdersDialog(customer),
                      tooltip: 'Buyurtmalar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        padding: const EdgeInsets.all(8),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.money_off, color: Colors.red, size: 24),
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
                  decoration: const InputDecoration(
                    labelText: 'Qarzgor ismi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Ism kiritish majburiy' : null,
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
                    if (v?.trim().isEmpty ?? true) return 'Telefon kiritish majburiy';
                    final digits = v!.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 7) return 'Telefon raqami juda qisqa';
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: debtController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qarz miqdori',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
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
                  decoration: const InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Qarz sababi haqida...',
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
              if (formKey.currentState!.validate()) {
                final farmProvider = Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addManualDebt(
                  customerName: nameController.text.trim(),
                  customerPhone: phoneController.text.trim(),
                  customerAddress: addressController.text.trim(),
                  debtAmount: double.parse(debtController.text),
                  note: noteController.text.trim(),
                );

                Navigator.pop(context);

                if (success) {
                  _showSnackBar(
                    '${nameController.text.trim()} ga ${debtController.text} so\'m qarz qo\'shildi',
                    Colors.green,
                  );
                } else {
                  _showSnackBar(
                    farmProvider.error ?? 'Xatolik yuz berdi',
                    Colors.red,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Qarz Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Customer customer) {
    final unpaidOrders = customer.orders.where((order) => !order.isPaid).toList();
    
    if (unpaidOrders.isEmpty) {
      _showSnackBar('Bu mijozda to\'lanmagan buyurtmalar yo\'q', Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payment, color: Colors.green, size: 24),
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Umumiy qarz: ${customer.totalDebt.toStringAsFixed(0)} so\'m',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('To\'lanmagan buyurtmalar:', 
                style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: unpaidOrders.length,
                  itemBuilder: (context, index) {
                    final order = unpaidOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        title: Text('${order.trayCount} fletka'),
                        subtitle: Text(
                          'Narx: ${order.totalAmount.toStringAsFixed(0)} so\'m\n'
                          'Sana: ${order.deliveryDate.day}.${order.deliveryDate.month}.${order.deliveryDate.year}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final success = await _markOrderAsPaid(customer.id, order.id);
                            if (success) {
                              Navigator.pop(context);
                              _showSnackBar('Buyurtma to\'landi!', Colors.green);
                            } else {
                              _showSnackBar('Xatolik yuz berdi', Colors.red);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('To\'lash', style: TextStyle(fontSize: 12)),
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

  Future<bool> _markOrderAsPaid(String customerId, String orderId) async {
    try {
      final farmProvider = Provider.of<FarmProvider>(context, listen: false);
      return await farmProvider.markCustomerOrderAsPaid(customerId, orderId);
    } catch (e) {
      return false;
    }
  }

  void _showOrdersDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        child: Icon(
                          order.isPaid ? Icons.check : Icons.schedule,
                          color: order.isPaid ? Colors.green : Colors.orange,
                          size: 16,
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
                          color: order.isPaid ? Colors.green : Colors.orange,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppConstants.primaryColor,
                    size: 24,
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
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Umumiy qarz',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customer.totalDebt.toStringAsFixed(0)} so\'m',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    final customersWithDebt = customers.where((c) => c.totalDebt > 0).toList();
    
    if (customersWithDebt.isEmpty) {
      _showSnackBar('Statistika ko\'rish uchun qarzdor mijozlar kerak', Colors.grey);
      return;
    }

    final totalDebt = _getTotalDebt(customers);
    final maxDebtCustomer = customersWithDebt.reduce((a, b) => a.totalDebt > b.totalDebt ? a : b);
    final minDebtCustomer = customersWithDebt.reduce((a, b) => a.totalDebt < b.totalDebt ? a : b);
    final avgDebt = totalDebt / customersWithDebt.length;
    final totalOrders = customers.fold(0, (sum, customer) => sum + customer.orders.length);
    final paidOrders = customers.fold(0, (sum, customer) => sum + customer.orders.where((o) => o.isPaid).length);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 12),
            Text('Qarz Statistikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Qarzdor mijozlar:', '${customersWithDebt.length} ta'),
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
            const Divider(),
            _buildStatRow('Jami buyurtmalar:', '$totalOrders ta'),
            _buildStatRow('To\'langan:', '$paidOrders ta'),
            _buildStatRow('To\'lanmagan:', '${totalOrders - paidOrders} ta'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
