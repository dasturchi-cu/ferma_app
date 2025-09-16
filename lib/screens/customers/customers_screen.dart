import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../models/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijozlar'),
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.farm;
        final customers = farmProvider.getRegularCustomers(); // Only regular customers

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
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
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
                    padding: const EdgeInsets.all(AppConstants.largePadding),
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
                                Icons.groups_rounded,
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
                                    'Mijozlar boshqaruvi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mijozlar va ularning buyurtmalari',
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
                                'Mijozlar soni',
                                '${customers.length}',
                                'ta',
                                Icons.person_outline_rounded,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernStatCard(
                                'Umumiy qarz',
                                '${customers.fold<double>(0.0, (sum, customer) => sum + customer.totalDebt).toStringAsFixed(0)}',
                                "so'm",
                                Icons.account_balance_wallet_outlined,
                                customers.any((c) => c.totalDebt > 0) 
                                    ? Colors.orange[300]!
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

              // Content
              Expanded(
                child: customers.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(
                          AppConstants.mediumPadding,
                        ),
                        itemCount: customers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppConstants.mediumPadding),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _buildCustomerCard(customer);
                        },
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
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'add_customer_fab',
          onPressed: () => _showAddCustomerDialog(context),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text(
            'Mijoz qo\'shish',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
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

  Widget _buildCustomerCard(Customer customer) {
    final hasDebt = customer.totalDebt > 0;
    final upcomingOrders = customer.tomorrowOrders;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConstants.accentColor.withOpacity(0.1),
                  child: Icon(
                    AppConstants.customerIcon,
                    color: AppConstants.accentColor,
                  ),
                ),
                const SizedBox(width: AppConstants.mediumPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: AppConstants.subtitleStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(customer.phone, style: AppConstants.captionStyle),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCustomerDialog(context, customer);
                        break;
                      case 'egg_sale':
                        _showEggSaleDialog(context, customer);
                        break;
                      case 'delete':
                        _showDeleteCustomerDialog(context, customer);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Tahrirlash'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'egg_sale',
                      child: ListTile(
                        leading: Icon(Icons.egg),
                        title: Text('Tuxum Sotish'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'O\'chirish',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (customer.address.isNotEmpty) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.address,
                      style: AppConstants.captionStyle,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppConstants.mediumPadding),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildCustomerStat(
                    'Buyurtmalar',
                    '${customer.orders.length} ta',
                    Icons.shopping_cart,
                    AppConstants.infoColor,
                  ),
                ),
                Expanded(
                  child: _buildCustomerStat(
                    'Qarzdorlik',
                    '${customer.totalDebt.toStringAsFixed(0)} so\'m',
                    Icons.money_off,
                    hasDebt
                        ? AppConstants.errorColor
                        : AppConstants.successColor,
                  ),
                ),
              ],
            ),

            // Upcoming orders
            if (upcomingOrders.isNotEmpty) ...[
              const SizedBox(height: AppConstants.mediumPadding),
              Container(
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                  border: Border.all(
                    color: AppConstants.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: AppConstants.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ertangi yetkazib berish: ${upcomingOrders.length} ta buyurtma',
                      style: AppConstants.captionStyle.copyWith(
                        color: AppConstants.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: AppConstants.mediumPadding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEggSaleDialog(context, customer),
                    icon: const Icon(Icons.egg),
                    label: const Text('Tuxum Sotish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showCustomerOrdersDialog(context, customer),
                    icon: const Icon(Icons.list),
                    label: const Text('Tarix'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.infoColor,
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

  Widget _buildCustomerStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppConstants.captionStyle.copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  style: AppConstants.captionStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern Empty Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.1),
                    const Color(0xFF764ba2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: const Color(0xFF667eea).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 64,
                color: const Color(0xFF667eea).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hali mijozlar qo\'shilmagan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Birinchi mijozingizni qo\'shib,\nbuyurtmalarni boshqarishni boshlang',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showAddCustomerDialog(context),
                icon: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Birinchi mijozni qo\'shish',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi Mijoz Qo\'shish'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mijoz nomi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ism majburiy' : null,
              ),
              const SizedBox(height: AppConstants.mediumPadding),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Telefon raqami majburiy';
                  // Oddiy tekshiruv: kamida 7 ta raqam
                  final digits = t.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7)
                    return 'Telefon raqamini to\'g\'ri kiriting';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.mediumPadding),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
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
              if (formKey.currentState!.validate()) {
                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
                final success = await farmProvider.addCustomer(
                  nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );

                // Safe navigation check
                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${nameController.text.trim()} mijoz qo\'shildi',
                      ),
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

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final addressController = TextEditingController(text: customer.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mijoz Ma\'lumotlarini Tahrirlash'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mijoz nomi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ism majburiy' : null,
              ),
              const SizedBox(height: AppConstants.mediumPadding),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Telefon raqami majburiy';
                  final digits = t.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7)
                    return 'Telefon raqamini to\'g\'ri kiriting';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.mediumPadding),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
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
              if (formKey.currentState!.validate()) {
                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
                final success = await farmProvider.updateCustomerInfo(
                  customer.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );

                // Safe navigation check
                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mijoz ma\'lumotlari yangilandi'),
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
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showAddOrderDialog(BuildContext context, Customer customer) {
    final trayController = TextEditingController();
    final priceController = TextEditingController(
      text: AppConstants.defaultEggPrice.toString(),
    );
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${customer.name} uchun buyurtma'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: trayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fletka soni',
                    border: OutlineInputBorder(),
                    suffixText: 'fletka',
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    final n = int.tryParse(t);
                    if (n == null || n <= 0) {
                      return 'Fletka sonini to\'g\'ri kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.mediumPadding),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fletka narxi',
                    border: OutlineInputBorder(),
                    suffixText: 'so\'m',
                  ),
                  validator: (v) {
                    final t = (v ?? '').replaceAll(',', '.');
                    final d = double.tryParse(t);
                    if (d == null || d <= 0) return 'Narxni to\'g\'ri kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.mediumPadding),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: AppConstants.mediumPadding),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yetkazib berish sanasi: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
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
                if (formKey.currentState?.validate() != true) return;

                final trayCount = int.parse(trayController.text.trim());
                final price = double.parse(
                  priceController.text.replaceAll(',', '.'),
                );
                final note = noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim();

                final farmProvider = Provider.of<FarmProvider>(
                  context,
                  listen: false,
                );
                final success = await farmProvider.addCustomerOrder(
                  customer.id,
                  trayCount,
                  price,
                  selectedDate,
                  note: note,
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$trayCount fletka buyurtma qo\'shildi'),
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
              },
              child: const Text('Qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerOrdersDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: AppConstants.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Buyurtmalar tarixi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOrderStat(
                        'Jami',
                        '${customer.orders.length}',
                        Icons.shopping_cart,
                        AppConstants.infoColor,
                      ),
                    ),
                    Expanded(
                      child: _buildOrderStat(
                        'To\'langan',
                        '${customer.orders.where((o) => o.isPaid).length}',
                        Icons.check_circle,
                        AppConstants.successColor,
                      ),
                    ),
                    Expanded(
                      child: _buildOrderStat(
                        'Qarzdorlik',
                        '${customer.totalDebt.toStringAsFixed(0)} so\'m',
                        Icons.money_off,
                        AppConstants.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Orders list
              Expanded(
                child: customer.orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hali buyurtmalar yo\'q',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: customer.orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final order = customer.orders.reversed.toList()[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: order.isPaid
                                    ? [AppConstants.successColor.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                                    : [AppConstants.errorColor.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: order.isPaid
                                    ? AppConstants.successColor.withOpacity(0.3)
                                    : AppConstants.errorColor.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (order.isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: order.isPaid
                                                ? [AppConstants.successColor, Colors.green[600]!]
                                                : [AppConstants.errorColor, Colors.orange[600]!],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (order.isPaid ? Colors.green : Colors.orange).withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          order.isPaid ? Icons.check_circle : Icons.access_time,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.trayCount > 0 
                                                  ? '${order.trayCount} fletka tuxum'
                                                  : 'Qo\'lda qo\'shilgan qarz',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDateTime(order.deliveryDate),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${order.totalAmount.toStringAsFixed(0)} so\'m',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            order.isPaid ? 'To\'landi' : 'Qarzdorlik',
                                            style: TextStyle(
                                              color: order.isPaid
                                                  ? AppConstants.successColor
                                                  : AppConstants.errorColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  // Order details
                                  if (order.note?.isNotEmpty ?? false)
                                    const SizedBox(height: 12),
                                  if (order.note?.isNotEmpty ?? false)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.note!,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  
                                  // Actions
                                  if (!order.isPaid)
                                    const SizedBox(height: 12),
                                  if (!order.isPaid)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showMarkAsPaidDialog(context, customer, order);
                                        },
                                        icon: const Icon(Icons.payment, size: 16),
                                        label: const Text('To\'lash'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppConstants.successColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  void _showMarkAsPaidDialog(
    BuildContext context,
    Customer customer,
    CustomerOrder order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('To\'lovni tasdiqlash'),
        content: Text(
          '${customer.name} ning ${order.trayCount} fletka buyurtmasi uchun ${order.totalAmount.toStringAsFixed(0)} so\'m to\'lovni tasdiqlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final farmProvider = Provider.of<FarmProvider>(
                context,
                listen: false,
              );
              final success = await farmProvider.markCustomerOrderAsPaid(
                customer.id,
                order.id,
              );

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('To\'lov tasdiqlandi'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.successColor,
            ),
            child: const Text(
              'Tasdiqlash',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEggSaleDialog(BuildContext context, Customer customer) {
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final currentStock = farmProvider.farm?.egg?.currentStock ?? 0;
    final trayController = TextEditingController();
    final priceController = TextEditingController(text: '10000');
    final totalController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void calculateTotal() {
      final count = int.tryParse(trayController.text) ?? 0;
      final price = double.tryParse(priceController.text) ?? 0.0;
      final total = count * price;
      totalController.text = total > 0 ? total.toStringAsFixed(0) : '';
    }

    // Listen to changes in count and price fields
    trayController.addListener(calculateTotal);
    priceController.addListener(calculateTotal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} ga tuxum sotish'),
        content: Form(
          key: formKey,
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
              TextFormField(
                controller: trayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sotilgan fletka soni',
                  border: OutlineInputBorder(),
                  suffixText: 'fletka',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  final n = int.tryParse(t);
                  if (n == null || n <= 0) {
                    return 'Fletka sonini to\'g\'ri kiriting';
                  }
                  if (n > currentStock) {
                    return 'Yetarli zaxira yo\'q (Mavjud: $currentStock)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fletka narxi',
                  border: OutlineInputBorder(),
                  suffixText: "so'm",
                ),
                validator: (v) {
                  final t = (v ?? '').replaceAll(',', '.');
                  final d = double.tryParse(t);
                  if (d == null || d <= 0) return 'Narxni to\'g\'ri kiriting';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: totalController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Umumiy summa (mijozning qarzi)',
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
              const SizedBox(height: 8),
              Text(
                'Bu summa mijozning sizga qarzi bo\'lib qo\'shiladi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
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
              if (formKey.currentState!.validate()) {
                final count = int.parse(trayController.text);
                final price = double.parse(priceController.text);
                
                final success = await farmProvider.addCustomerEggSale(
                  customer.id,
                  count,
                  price,
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${customer.name} ga $count fletka tuxum sotildi. Qarz: ${(count * price).toStringAsFixed(0)} so\'m',
                      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
            ),
            child: const Text(
              'Sotish',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCustomerDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mijozni o\'chirish'),
        content: Text(
          '${customer.name} mijozini o\'chirmoqchimisiz? Bu amal qaytarib bo\'lmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final farmProvider = Provider.of<FarmProvider>(
                context,
                listen: false,
              );
              final success = await farmProvider.removeCustomer(customer.id);

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mijoz o\'chirildi'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text(
              'O\'chirish',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
