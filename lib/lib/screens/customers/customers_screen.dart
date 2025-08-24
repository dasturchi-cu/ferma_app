import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';
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
          final customers = farm?.customers ?? [];

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.accentColor,
                      AppConstants.accentColor.withOpacity(0.8),
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
                          Icon(
                            AppConstants.customerIcon,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: AppConstants.mediumPadding),
                          Text(
                            'Mijozlar boshqaruvi',
                            style: AppConstants.titleStyle.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.mediumPadding),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeaderStat(
                              'Umumiy mijozlar',
                              '${customers.length} ta',
                              Icons.people,
                            ),
                          ),
                          const SizedBox(width: AppConstants.mediumPadding),
                          Expanded(
                            child: _buildHeaderStat(
                              'Umumiy qarzdorlik',
                              '${customers.fold(0.0, (sum, customer) => sum + customer.totalDebt).toStringAsFixed(0)} so\'m',
                              Icons.money_off,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: customers.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.all(AppConstants.mediumPadding),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_customer_fab',
        onPressed: () => _showAddCustomerDialog(context),
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Mijoz qo\'shish'),
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
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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
                      Text(
                        customer.phone,
                        style: AppConstants.captionStyle,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCustomerDialog(context, customer);
                        break;
                      case 'order':
                        _showAddOrderDialog(context, customer);
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
                      value: 'order',
                      child: ListTile(
                        leading: Icon(Icons.add_shopping_cart),
                        title: Text('Buyurtma Qo\'shish'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('O\'chirish',
                            style: TextStyle(color: Colors.red)),
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
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
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
                    onPressed: () => _showAddOrderDialog(context, customer),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Buyurtma'),
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
      String title, String value, IconData icon, Color color) {
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
                  style: AppConstants.captionStyle.copyWith(
                    fontSize: 10,
                  ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppConstants.customerIcon,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Hali mijozlar qo\'shilmagan',
            style: AppConstants.subtitleStyle.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Birinchi mijozni qo\'shish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addCustomer(
                  nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${nameController.text.trim()} mijoz qo\'shildi'),
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
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.updateCustomerInfo(
                  customer.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );

                Navigator.pop(context);

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
    final priceController =
        TextEditingController(text: AppConstants.defaultEggPrice.toString());
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
                final price =
                    double.parse(priceController.text.replaceAll(',', '.'));
                final note = noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim();

                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
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
                      content:
                          Text(farmProvider.error ?? 'Xatolik yuz berdi'),
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
                            ? AppConstants.successColor.withOpacity(0.1)
                            : AppConstants.warningColor.withOpacity(0.1),
                        child: Icon(
                          order.isPaid ? Icons.check : Icons.schedule,
                          color: order.isPaid
                              ? AppConstants.successColor
                              : AppConstants.warningColor,
                        ),
                      ),
                      title: Text('${order.trayCount} fletka'),
                      subtitle: Text(
                        '${order.deliveryDate.day}.${order.deliveryDate.month}.${order.deliveryDate.year}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${order.totalAmount.toStringAsFixed(0)} so\'m',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order.isPaid ? 'To\'landi' : 'To\'lanmagan',
                            style: TextStyle(
                              color: order.isPaid
                                  ? AppConstants.successColor
                                  : AppConstants.errorColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: order.isPaid
                          ? null
                          : () {
                              Navigator.pop(context);
                              _showMarkAsPaidDialog(context, customer, order);
                            },
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

  void _showMarkAsPaidDialog(
      BuildContext context, Customer customer, CustomerOrder order) {
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
              final farmProvider =
                  Provider.of<FarmProvider>(context, listen: false);
              final success = await farmProvider.markCustomerOrderAsPaid(
                  customer.id, order.id);

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
                backgroundColor: AppConstants.successColor),
            child:
                const Text('Tasdiqlash', style: TextStyle(color: Colors.white)),
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
              final farmProvider =
                  Provider.of<FarmProvider>(context, listen: false);
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
                backgroundColor: AppConstants.errorColor),
            child:
                const Text('O\'chirish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
