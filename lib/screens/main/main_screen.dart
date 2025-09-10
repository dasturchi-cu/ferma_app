import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_provider.dart';
import '../../utils/constants.dart';
import '../analytics/analytics_screen.dart';
import '../customers/customers_screen.dart';
import '../debts/debts_screen.dart';
import '../eggs/eggs_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ModernDashboard(),
    CustomersScreen(),
    EggsScreen(),
    AnalyticsScreen(),
    DebtsScreen()
  ];

  @override
  void initState() {
    super.initState();
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
    final farmName = Provider.of<AuthProvider>(context).farm?.name ?? 'Ferma';

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                selected: _currentIndex == 0,
                onTap: () {
                  setState(() => _currentIndex = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Mijozlar'),
                selected: _currentIndex == 1,
                onTap: () {
                  setState(() => _currentIndex = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.egg),
                title: const Text('Tuxum'),
                selected: _currentIndex == 2,
                onTap: () {
                  setState(() => _currentIndex = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Hisobot'),
                selected: _currentIndex == 3,
                onTap: () {
                  setState(() => _currentIndex = 3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Qarz daftari'),
                selected: _currentIndex == 4,
                onTap: () {
                  setState(() => _currentIndex = 4);
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Sozlamalar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Chiqish',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          farmName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Sozlamalar',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sozlamalar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Ferma nomini o\'zgartirish'),
              onTap: () {
                Navigator.pop(context);
                _showEditFarmNameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Ilova haqida'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Rostdan ham tizimdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Chiqish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditFarmNameDialog(BuildContext context) {
    final controller = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    controller.text = authProvider.farm?.name ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ferma nomini o\'zgartirish'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ferma nomi',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await authProvider.updateFarmName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ferma App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiya: 1.0.0'),
            SizedBox(height: 8),
            Text('Tovuq fermasi boshqaruvi uchun mo\'ljallangan ilova'),
            SizedBox(height: 8),
            Text('© 2024 Ferma App'),
          ],
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

// Removed DashboardTab and stats UI to keep app focused on two primary sections