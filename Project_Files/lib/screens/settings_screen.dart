import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = false;
  int reminderDaysBefore = 3;
  final _authService = AuthService();
  bool _linking = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      reminderDaysBefore = prefs.getInt('reminderDaysBefore') ?? 3;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() {
      notificationsEnabled = value;
    });

    if (value) {
      await NotificationService().requestPermission();
    } else {
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> _updateReminderDays(BuildContext context) async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) {
        int selected = reminderDaysBefore;
        return AlertDialog(
          title: const Text('Kaç gün önce hatırlatılsın?'),
          content: DropdownButtonFormField<int>(
            initialValue: selected,
            items: [1, 2, 3, 4, 5, 7].map((d) => DropdownMenuItem(value: d, child: Text('$d gün önce'))).toList(),
            onChanged: (val) {
              if (val != null) selected = val;
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Kaydet')),
          ],
        );
      }
    );

    if (days != null && days != reminderDaysBefore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminderDaysBefore', days);
      setState(() {
        reminderDaysBefore = days;
      });
    }
  }

  Future<void> _handleLinkGoogle() async {
    setState(() => _linking = true);
    try {
      await _authService.linkGuestWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google hesabına başarıyla bağlandı.')),
      );
      setState(() {});
    } on GoogleAccountConflictException catch (e) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bu Google hesabı başka bir yerde kullanılıyor'),
          content: const Text(
            'Seçtiğin Google hesabı zaten başka bir hesaba bağlı. Bu hesaba geçersen, şu anki '
            'misafir oturumundaki verilerine bir daha erişemezsin.\n\n'
            'Yine de bu Google hesabına geçmek istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yine de Geç', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await _authService.switchToExistingGoogleAccount(e.credential);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hesap değiştirilirken bir sorun oluştu, tekrar dene.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlanırken bir sorun oluştu, tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
  }

  Future<void> _handleGuestReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Misafir verileri silinecek'),
        content: const Text(
          'Bir hesaba bağlı olmadığın için buradan "çıkış" yapamazsın; '
          'yapabileceğin şey bu cihazdaki misafir oturumunu sonlandırıp '
          'baştan başlamak. Bunu yaparsan ürün ve geçmiş verilerine bir '
          'daha erişemezsin. Devam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verileri Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authService.isGuest;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          if (isGuest)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                color: AppTheme.lightGreen.withValues(alpha: 0.15),
                child: ListTile(
                  leading: const Icon(Icons.link, color: AppTheme.primaryGreen),
                  title: const Text('Misafir olarak kullanıyorsun'),
                  subtitle: const Text('Verilerini kaybetmemek için bir Google hesabına bağla'),
                  trailing: _linking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton(
                          onPressed: _handleLinkGoogle,
                          child: const Text('Bağla'),
                        ),
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('SKT Bildirimleri'),
            subtitle: const Text('Ürünlerin son kullanma tarihi yaklaşınca bildirim al'),
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          ListTile(
            title: const Text('Kaç gün önceden hatırlatılsın?'),
            subtitle: Text('$reminderDaysBefore gün önce'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _updateReminderDays(context),
          ),
          const Divider(),
          const ListTile(
            title: Text('Uygulama Hakkında'),
            subtitle: Text('EcoChef AI v1.0.0'),
          ),
          const Divider(),
          if (isGuest)
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Misafir Verilerini Sil', style: TextStyle(color: Colors.red)),
              onTap: _handleGuestReset,
            )
          else
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: _handleSignOut,
            ),
        ],
      ),
    );
  }
}