import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/quick_action_button.dart';
import '../chickens/chickens_screen.dart';
import '../eggs/eggs_screen.dart';
import '../customers/customers_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Farm ma'lumotlarini yuklash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final farmProvider = Provider.of<FarmProvider>(context, listen: false);

      if (authProvider.farm != null) {
        farmProvider.setFarm(authProvider.farm!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, child) {
          if (farmProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final farm = farmProvider.farm;
          if (farm == null) {
            return const Center(
              child: Text('Ferma ma\'lumotlari topilmadi'),
            );
          }

          final stats = farm.farmStats;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.mediumPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Xush kelibsiz xabari (yanada ixcham va chiroyli)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.largePadding,
                    vertical: AppConstants.mediumPadding,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppConstants.largeRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppConstants.chickenIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xush kelibsiz, ${farm.name}! 🐔',
                              style: AppConstants.titleStyle.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bugungi kunni yaxshi boshlang!',
                              style: AppConstants.bodyStyle.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ixcham ko'rinish uchun oraliqni kamaytiramiz
                const SizedBox(height: AppConstants.mediumPadding),

                // Asosiy statistikalar
                // Text(
                //   'Asosiy statistikalar',
                //   style: AppConstants.subtitleStyle,
                // ),
                const SizedBox(height: 8),

                // Statistikalar kartlari
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.mediumPadding,
                  mainAxisSpacing: AppConstants.mediumPadding,
                  // Ixcham rejim: kartalar biroz balandroq
                  childAspectRatio: 0.95,
                  children: [
                    StatCard(
                      title: 'Tovuqlar',
                      value: '${stats['totalChickens']}',
                      icon: AppConstants.chickenIcon,
                      color: AppConstants.primaryColor,
                      onTap: () {
                        setState(() => _currentIndex = 1);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChickensScreen(),
                          ),
                        ).then((_) => setState(() => _currentIndex = 0));
                      },
                    ),
                    StatCard(
                      title: 'Bugungi tuxumlar',
                      value: '${stats['todayEggs']} fletka',
                      icon: AppConstants.eggIcon,
                      color: AppConstants.secondaryColor,
                      onTap: () {
                        setState(() => _currentIndex = 2);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EggsScreen(),
                          ),
                        ).then((_) => setState(() => _currentIndex = 0));
                      },
                    ),
                    StatCard(
                      title: 'Joriy zaxira',
                      value: '${stats['currentStock']} fletka',
                      icon: AppConstants.stockIcon,
                      color: AppConstants.accentColor,
                      onTap: () {
                        setState(() => _currentIndex = 2);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EggsScreen(),
                          ),
                        ).then((_) => setState(() => _currentIndex = 0));
                      },
                    ),
                    StatCard(
                      title: 'Mijozlar',
                      value: '${stats['totalCustomers']}',
                      icon: AppConstants.customerIcon,
                      color: AppConstants.infoColor,
                      onTap: () {
                        setState(() => _currentIndex = 3);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomersScreen(),
                          ),
                        ).then((_) => setState(() => _currentIndex = 0));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Tezkor amallar
                // Text(
                //   'Tezkor amallar',
                //   style: AppConstants.subtitleStyle,
                // ),
                // const SizedBox(height: AppConstants.mediumPadding),

                // Tezkor amallar tugmalari
                // Column(
                //   children: [
                //     QuickActionButton(
                //       title: 'Tovuq qo\'shish',
                //       subtitle: 'Yangi tovuqlar qo\'shish',
                //       icon: AppConstants.chickenIcon,
                //       color: AppConstants.primaryColor,
                //       onTap: () {
                //         _showAddChickenDialog(context);
                //       },
                //     ),
                //     const SizedBox(height: AppConstants.smallPadding),
                //     QuickActionButton(
                //       title: 'Tuxum yig\'ish',
                //       subtitle: 'Bugungi tuxumlarni kiritish',
                //       icon: AppConstants.eggIcon,
                //       color: AppConstants.secondaryColor,
                //       onTap: () {
                //         _showAddEggProductionDialog(context);
                //       },
                //     ),
                //     const SizedBox(height: AppConstants.smallPadding),
                //     QuickActionButton(
                //       title: 'Mijoz qo\'shish',
                //       subtitle: 'Yangi mijoz qo\'shish',
                //       icon: AppConstants.customerIcon,
                //       color: AppConstants.accentColor,
                //       onTap: () {
                //         _showAddCustomerDialog(context);
                //       },
                //     ),
                //   ],
                // ),

                const SizedBox(height: AppConstants.largePadding),

                // Kelgusi yetkazib berishlar
                if (stats['upcomingDeliveries'] > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.mediumPadding),
                    decoration: BoxDecoration(
                      color: AppConstants.warningColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.mediumRadius),
                      border: Border.all(
                        color: AppConstants.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppConstants.deliveryIcon,
                          color: AppConstants.warningColor,
                        ),
                        const SizedBox(width: AppConstants.mediumPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ertangi yetkazib berishlar',
                                style: AppConstants.subtitleStyle.copyWith(
                                  color: AppConstants.warningColor,
                                ),
                              ),
                              Text(
                                '${stats['upcomingDeliveries']} ta buyurtma',
                                style: AppConstants.captionStyle,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            // Yetkazib berishlar sahifasiga o'tish
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppConstants.largePadding),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          Future<void> nav;
          switch (index) {
            case 0:
              // Dashboard
              return;
            case 1:
              nav = Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChickensScreen()),
              );
              break;
            case 2:
              nav = Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EggsScreen()),
              );
              break;
            case 3:
              nav = Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersScreen()),
              );
              break;
            default:
              return;
          }
          nav.then((_) => mounted ? setState(() => _currentIndex = 0) : null);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Tovuqlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.egg),
            label: 'Tuxumlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Mijozlar',
          ),
        ],
      ),
    );
  }

  // Dialog metodlari
  void _showAddChickenDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tovuq Qo\'shish'),
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
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
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

  void _showAddEggProductionDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tuxum Yig\'ish'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fletka soni',
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
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addEggProduction(count);

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count fletka tuxum yig\'ildi'),
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
            child: const Text('Yig\'ish'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mijoz Qo\'shish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Mijoz nomi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon raqami',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
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
              if (nameController.text.trim().isNotEmpty &&
                  phoneController.text.trim().isNotEmpty) {
                final farmProvider =
                    Provider.of<FarmProvider>(context, listen: false);
                final success = await farmProvider.addCustomer(
                  nameController.text.trim(),
                  phone: phoneController.text.trim(),
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${nameController.text.trim()} qo\'shildi'),
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
}
