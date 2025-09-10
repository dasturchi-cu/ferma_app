import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _biometricAuth = false;
  bool _autoBackup = true;
  String _reminderTime = '08:00';
  String _currency = 'UZS';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from SharedPreferences or Hive
    setState(() {
      // Mock data for now
      _darkMode = false;
      _notifications = true;
      _biometricAuth = false;
      _autoBackup = true;
      _reminderTime = '08:00';
      _currency = 'UZS';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Umumiy'),
            _buildGeneralSettings(),

            const SizedBox(height: 24),

            _buildSectionTitle('Xavfsizlik'),
            _buildSecuritySettings(),

            const SizedBox(height: 24),

            _buildSectionTitle('Bildirishnomalar'),
            _buildNotificationSettings(),

            const SizedBox(height: 24),

            _buildSectionTitle('Ma\'lumotlar'),
            _buildDataSettings(),

            const SizedBox(height: 24),

            _buildSectionTitle('Haqida'),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode, color: AppTheme.primaryColor),
            title: const Text('Tungi rejim'),
            subtitle: const Text('Ilovani qorong\'i temada ishlatish'),
            trailing: Switch(
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
                // TODO: Implement theme switching
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.primaryColor),
            title: const Text('Til'),
            subtitle: const Text('O\'zbekcha'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement language selection
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.attach_money,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Valyuta'),
            subtitle: Text(_currency),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showCurrencyDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.fingerprint,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Biometrik autentifikatsiya'),
            subtitle: const Text('Barmoq izi yoki Face ID bilan kirish'),
            trailing: Switch(
              value: _biometricAuth,
              onChanged: (value) async {
                setState(() {
                  _biometricAuth = value;
                });
                // TODO: Implement biometric auth
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock, color: AppTheme.primaryColor),
            title: const Text('PIN kod'),
            subtitle: const Text('4 xonali PIN kod o\'rnatish'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showPinCodeDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.notifications,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Bildirishnomalar'),
            subtitle: const Text('Barcha bildirishnomalarni yoqish/o\'chirish'),
            trailing: Switch(
              value: _notifications,
              onChanged: (value) {
                setState(() {
                  _notifications = value;
                });
                // TODO: Implement notification toggle
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.access_time,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Eslatma vaqti'),
            subtitle: Text('Har kuni $_reminderTime'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showTimePickerDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup, color: AppTheme.primaryColor),
            title: const Text('Avtomatik backup'),
            subtitle: const Text('Har kuni Google Drive ga backup'),
            trailing: Switch(
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
                // TODO: Implement auto backup
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.cloud_upload,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Qo\'lda backup'),
            subtitle: const Text('Hozir Google Drive ga yuklash'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showSnackBar('Backup funksiyasi keyincha qo\'shiladi');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.cloud_download,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Backup dan tiklash'),
            subtitle: const Text('Google Drive dan ma\'lumotlarni tiklash'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showSnackBar('Tiklash funksiyasi keyincha qo\'shiladi');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.file_download,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Ma\'lumotlarni eksport qilish'),
            subtitle: const Text('Excel, PDF yoki CSV formatda'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showExportDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryColor),
            title: const Text('Ilova haqida'),
            subtitle: const Text('Versiya 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help, color: AppTheme.primaryColor),
            title: const Text('Yordam'),
            subtitle: const Text('Foydalanish bo\'yicha ko\'rsatmalar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show help screen
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.feedback, color: AppTheme.primaryColor),
            title: const Text('Fikr bildirish'),
            subtitle: const Text('Ilova haqida fikr yoki taklif'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Open feedback form
            },
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valyuta tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('O\'zbek so\'mi (UZS)'),
              trailing: _currency == 'UZS'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _currency = 'UZS';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('AQSH dollari (USD)'),
              trailing: _currency == 'USD'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _currency = 'USD';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePickerDialog() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2024-01-01 $_reminderTime:00'),
      ),
    );

    if (time != null) {
      setState(() {
        _reminderTime =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showPinCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN kod o\'rnatish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('4 xonali PIN kod kiriting:'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'PIN kod',
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
            onPressed: () {
              // TODO: Implement PIN code setting
              Navigator.pop(context);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksport formatini tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel (.xlsx)'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Excel eksport funksiyasi keyincha qo\'shiladi');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('PDF eksport funksiyasi keyincha qo\'shiladi');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_view),
              title: const Text('CSV'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('CSV eksport funksiyasi keyincha qo\'shiladi');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Ferma App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.agriculture,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'Professional tovuq fermasi boshqaruv ilovasi. '
          'Tovuqlar, tuxum, sotuvlar va mijozlarni boshqarish uchun mo\'ljallangan.',
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryColor),
    );
  }
}
