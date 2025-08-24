import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/farm_provider.dart';
import '../../models/customer.dart';
import '../../widgets/stat_card.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text(widget.customer.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _callCustomer(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer header info
          _buildCustomerHeader(),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Ma\'lumotlar'),
              Tab(text: 'Buyurtmalar'),
              Tab(text: 'Statistika'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildInfoTab(), _buildOrdersTab(), _buildStatsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_order_fab_${widget.customer.id}',
        onPressed: _showAddOrderDialog,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.primaryLight.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              widget.customer.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customer.phone,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                if (widget.customer.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.customer.address,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.customer.totalDebt > 0
                  ? AppTheme.warning.withOpacity(0.2)
                  : AppTheme.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.customer.totalDebt > 0 ? 'Qarzdor' : 'To\'langan',
              style: TextStyle(
                color: widget.customer.totalDebt > 0
                    ? AppTheme.warning
                    : AppTheme.success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aloqa ma\'lumotlari',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, 'Ism', widget.customer.name),
                  _buildInfoRow(Icons.phone, 'Telefon', widget.customer.phone),
                  if (widget.customer.address.isNotEmpty)
                    _buildInfoRow(
                      Icons.location_on,
                      'Manzil',
                      widget.customer.address,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moliyaviy ma\'lumotlar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.money_off,
                    'Joriy qarz',
                    '${widget.customer.totalDebt} som',
                  ),
                  _buildInfoRow(
                    Icons.egg,
                    'Qarzdagi tuxum',
                    '0 fletka',
                  ), // TODO: Add eggsOwed field
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buyurtmalar tarixi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          if (widget.customer.orders.isEmpty)
            const Center(
              child: Text(
                'Hali buyurtmalar yo\'q',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.customer.orders.length,
              itemBuilder: (context, index) {
                final order = widget.customer.orders[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: order.isPaid
                          ? AppTheme.success
                          : AppTheme.warning,
                      child: Icon(
                        order.isPaid ? Icons.check : Icons.schedule,
                        color: Colors.white,
                      ),
                    ),
                    title: Text('${order.trayCount} fletka'),
                    subtitle: Text(
                      '${order.totalAmount} som - ${_formatDate(order.deliveryDate)}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: order.isPaid
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.isPaid ? 'To\'langan' : 'Qarz',
                        style: TextStyle(
                          color: order.isPaid
                              ? AppTheme.success
                              : AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () => _showOrderDetail(order),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mijoz statistikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                title: 'Jami Buyurtmalar',
                value: '${widget.customer.orders.length}',
                icon: Icons.shopping_cart,
                color: AppTheme.info,
              ),
              StatCard(
                title: 'Jami Qarz',
                value: '${widget.customer.totalDebt} som',
                icon: Icons.money_off,
                color: widget.customer.totalDebt > 0
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
              StatCard(
                title: 'To\'langan Buyurtmalar',
                value:
                    '${widget.customer.orders.where((o) => o.isPaid).length}',
                icon: Icons.check_circle,
                color: AppTheme.success,
              ),
              StatCard(
                title: 'Qarzdagi Buyurtmalar',
                value:
                    '${widget.customer.orders.where((o) => !o.isPaid).length}',
                icon: Icons.schedule,
                color: AppTheme.warning,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oxirgi faoliyat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (widget.customer.orders.isNotEmpty) ...[
                    () {
                      final lastOrder = widget.customer.orders.last;
                      return Column(
                        children: [
                          _buildInfoRow(
                            Icons.date_range,
                            'Oxirgi buyurtma',
                            _formatDate(lastOrder.deliveryDate),
                          ),
                          _buildInfoRow(
                            Icons.attach_money,
                            'Oxirgi summa',
                            '${lastOrder.totalAmount} som',
                          ),
                        ],
                      );
                    }(),
                  ] else
                    const Text(
                      'Hali faoliyat yo\'q',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.customer.name);
    final phoneController = TextEditingController(text: widget.customer.phone);
    final addressController = TextEditingController(
      text: widget.customer.address,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mijoz ma\'lumotlarini tahrirlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ism',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Manzil',
                border: OutlineInputBorder(),
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
              final farmProvider =
                  Provider.of<FarmProvider>(context, listen: false);
              final success = await farmProvider.updateCustomerInfo(
                widget.customer.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
              );

              Navigator.pop(context);
              if (success) {
                _showSnackBar('Mijoz ma\'lumotlari yangilandi');
              } else {
                _showSnackBar(
                    farmProvider.error ?? 'Mijozni yangilashda xatolik');
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showAddOrderDialog() {
    final eggsController = TextEditingController();
    final priceController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi buyurtma qo\'shish'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: eggsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tuxum soni (fletka)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fletka narxi (som)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Yetkazib berish: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final eggs = int.tryParse(eggsController.text);
              final price = double.tryParse(priceController.text);
              if (eggs != null && eggs > 0 && price != null && price > 0) {
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addCustomerOrder(
                  widget.customer.id,
                  eggs,
                  price,
                  selectedDate,
                );
                Navigator.pop(context);
                if (success) {
                  _showSnackBar('Buyurtma qo\'shildi');
                } else {
                  _showSnackBar(
                      farmProvider.error ?? 'Buyurtma qo\'shishda xatolik');
                }
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(CustomerOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buyurtma tafsilotlari'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.egg, 'Tuxum soni', '${order.trayCount} fletka'),
            _buildInfoRow(
              Icons.attach_money,
              'Fletka narxi',
              '${order.pricePerTray} som',
            ),
            _buildInfoRow(
              Icons.calculate,
              'Jami summa',
              '${order.totalAmount} som',
            ),
            _buildInfoRow(
              Icons.date_range,
              'Sana',
              _formatDate(order.deliveryDate),
            ),
            _buildInfoRow(
              Icons.payment,
              'Holat',
              order.isPaid ? 'To\'langan' : 'Qarz',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
          if (!order.isPaid)
            ElevatedButton(
              onPressed: () async {
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider
                    .markCustomerOrderAsPaid(widget.customer.id, order.id);
                Navigator.pop(context);
                if (success) {
                  _showSnackBar('Buyurtma to\'langan deb belgilandi');
                } else {
                  _showSnackBar(
                      farmProvider.error ?? 'Amalda xatolik yuz berdi');
                }
              },
              child: const Text('To\'landi'),
            ),
        ],
      ),
    );
  }

  void _callCustomer() {
    // TODO: Implement phone call functionality
    _showSnackBar('Telefon qo\'ng\'irog\'i funksiyasi keyincha qo\'shiladi');
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryGreen),
    );
  }
}
