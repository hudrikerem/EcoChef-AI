import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/avatar.dart';
import '../services/auth_service.dart';
import '../state/product_store.dart';
import '../theme/app_theme.dart';
import 'achievements_screen.dart';
import 'avatar_picker_sheet.dart';
import 'tuketim_karnesi_detay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showAvatarPopup(BuildContext context) {
    const double avatarSize = 220;
    const double boxSize = avatarSize + 28;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Center(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const _ProfileAvatarImage(radius: avatarSize / 2),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: dialogContext,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => const AvatarPickerSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('İsmi Düzenle'),
            content: TextField(
              controller: controller,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty) return;

                        setDialogState(() => isLoading = true);

                        try {
                          final authService = AuthService();
                          final store = context.read<ProductStore>();

                          if (authService.isGuest) {
                            await store.setGuestDisplayName(newName);
                          } else {
                            await authService.updateDisplayName(newName);
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata oluştu: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final authService = AuthService();
    final user = authService.currentUser;
    final isGuest = authService.isGuest;

    final displayName = isGuest
        ? (store.guestDisplayName?.isNotEmpty == true
            ? store.guestDisplayName!
            : 'Misafir Kullanıcı')
        : (user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : 'Kullanıcı');

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _showAvatarPopup(context),
              child: const _ProfileAvatarImage(radius: 40),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 32),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showEditNameDialog(context, displayName),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RescueWasteBar(
            rescued: store.rescuedCount,
            wasted: store.wastedCount,
          ),
          const SizedBox(height: 16),

          _AchievementsPreview(),
        ],
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  final double radius;

  const _ProfileAvatarImage({required this.radius});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final authService = AuthService();
    final user = authService.currentUser;
    final isGuest = authService.isGuest;

    ImageProvider? provider;
    if (store.avatarImageBase64 != null) {
      provider = MemoryImage(base64Decode(store.avatarImageBase64!));
    } else if (store.avatarPresetId != null) {
      final preset = presetAvatars.firstWhere(
        (a) => a.id == store.avatarPresetId,
        orElse: () => presetAvatars.first,
      );
      provider = AssetImage(preset.assetPath);
    } else if (!isGuest && user?.photoURL != null) {
      provider = NetworkImage(user!.photoURL!);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: provider,
      child: provider == null
          ? Icon(isGuest ? Icons.person_outline : Icons.person, size: radius)
          : null,
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final unlocked = store.unlockedAchievements;
    final total = unlocked.length + store.lockedAchievements.length;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  const Text('Başarımlar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text('${unlocked.length}/$total',
                      style: const TextStyle(color: Colors.grey)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              if (unlocked.isEmpty)
                const Text(
                  'Ürün kurtardıkça ve tarif yaptıkça rozet kazanacaksın! Henüz hiç başarım kazanmadın.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: unlocked.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final achievement = unlocked[index];
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.15),
                        child: Icon(achievement.icon,
                            color: AppTheme.primaryGreen, size: 22),
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
}

/// Tıklanabilir Tüketim Karnesi Kartı
class _RescueWasteBar extends StatelessWidget {
  final int rescued;
  final int wasted;

  const _RescueWasteBar({required this.rescued, required this.wasted});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final total = rescued + wasted;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TuketimKarnesiDetayEkrani(
                toplamUrun: store.totalTracked,
                kurtarilanUrun: store.rescuedCount,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: AppTheme.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tüketim Karnem',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: total == 0
                      ? Container(color: Colors.grey.shade200)
                      : Row(
                          children: [
                            if (rescued > 0)
                              Expanded(
                                flex: rescued,
                                child: Container(color: AppTheme.statusFresh),
                              ),
                            if (wasted > 0)
                              Expanded(
                                flex: wasted,
                                child: Container(color: AppTheme.statusExpired),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatMiniTile(
                      label: 'Kurtarılan',
                      value: '$rescued ürün',
                      icon: Icons.eco_outlined,
                      color: AppTheme.statusFresh,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatMiniTile(
                      label: 'İsraf Edilen',
                      value: '$wasted ürün',
                      icon: Icons.delete_outline,
                      color: AppTheme.statusExpired,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMiniTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}