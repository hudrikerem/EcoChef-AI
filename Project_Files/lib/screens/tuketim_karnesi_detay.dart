import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/product_store.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';

class TuketimKarnesiDetayEkrani extends StatefulWidget {
  final int toplamUrun;
  final int kurtarilanUrun;

  const TuketimKarnesiDetayEkrani({
    super.key,
    required this.toplamUrun,
    required this.kurtarilanUrun,
  });

  @override
  State<TuketimKarnesiDetayEkrani> createState() => _TuketimKarnesiDetayEkraniState();
}

class _TuketimKarnesiDetayEkraniState extends State<TuketimKarnesiDetayEkrani> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    final store = Provider.of<ProductStore>(context, listen: false);
    final totalDecided = store.rescuedCount + store.wastedCount;
    final rescued = store.rescuedCount;
    final percent = totalDecided > 0 ? (rescued / totalDecided) * 100 : 0.0;

    // Şartlar:
    // 1. Karar verilmiş ürün sayısı en az 2 olmalı (1 ürün varken patlamaz).
    // 2. Oran %80 ve üzeri olmalı.
    if (totalDecided >= 2 && percent >= 80) {
      _checkAndPlayConfetti(percent);
    }
  }

  Future<void> _checkAndPlayConfetti(double currentPercent) async {
    final prefs = await SharedPreferences.getInstance();
    final double? lastCelebratedPercent = prefs.getDouble('last_confetti_percent');

    if (lastCelebratedPercent == null || (currentPercent - lastCelebratedPercent).abs() > 0.01) {
      await prefs.setDouble('last_confetti_percent', currentPercent);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _confettiController.play();
        });
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _motiveEdiciMesajGetir(double yuzde, int totalDecided, int rescuedCount) {
    if (totalDecided == 0) {
      return "Henüz sonuçlanmış bir ürün kaydın yok. Ürünlerini tüketip veya kurtararak karneni oluşturmaya başla!";
    }
    
    if (totalDecided == 1) {
      if (rescuedCount == 1) {
        return "Tebrikler, ilk ürününü başarıyla kurtardın! İsrafı önleme yolculuğunda harika bir başlangıç. 🌱";
      } else {
        return "İlk ürün israf oldu ama sorun değil! Bir sonraki ürünlerde dikkat ederek oranını hemen yükseltebilirsin.";
      }
    }

    if (yuzde >= 80) {
      return "Dünya senin sayende daha yeşil! 🌍💚";
    } else if (yuzde >= 50) {
      return "İyi gidiyorsun! 👍";
    } else if (yuzde > 0) {
      return "Daha iyisini yapabilirsin! 🌱";
    } else {
      return "Tüketicilere ulaşan gıdanın yaklaşık %20'sinin israf olduğunu biliyor muydun?";
    }
  }

  Future<void> _deleteHistoryEntry(BuildContext context, String historyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu ürün geçmiş kaydını silmek istediğinden emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final store = context.read<ProductStore>();
        await store.deleteHistoryEntry(historyId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt başarıyla silindi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme işleminde hata: $e')),
          );
        }
      }
    }
  }

  void _showHistoryModal(BuildContext context, String title, ProductOutcome? outcome, Color themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<ProductStore>(
              builder: (context, store, _) {
                final entries = outcome == null
                    ? store.history
                    : store.history.where((h) => h.outcome == outcome).toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.history, color: themeColor),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      entries.isEmpty
                          ? const Expanded(
                              child: Center(
                                child: Text(
                                  'Henüz bu kategoride bir ürün kaydı yok.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : Expanded(
                              child: ListView.separated(
                                controller: scrollController,
                                itemCount: entries.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = entries[index];
                                  final formattedDate =
                                      "${item.decidedAt.day.toString().padLeft(2, '0')}.${item.decidedAt.month.toString().padLeft(2, '0')}.${item.decidedAt.year} ${item.decidedAt.hour.toString().padLeft(2, '0')}:${item.decidedAt.minute.toString().padLeft(2, '0')}";
                                  final itemColor = item.outcome == ProductOutcome.rescued
                                      ? AppTheme.statusFresh
                                      : AppTheme.statusExpired;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: itemColor.withValues(alpha: 0.15),
                                      child: Icon(
                                        item.outcome == ProductOutcome.rescued
                                            ? Icons.eco
                                            : Icons.delete_outline,
                                        color: itemColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text('${item.category} • $formattedDate'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => _deleteHistoryEntry(context, item.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final totalTracked = store.totalTracked;
    final rescuedCount = store.rescuedCount;
    final wastedCount = store.wastedCount;
    
    final totalDecided = rescuedCount + wastedCount;
    final kurtarmaYuzdesi = totalDecided > 0 ? (rescuedCount / totalDecided) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüketim Karnesi Detay'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showHistoryModal(
                        context,
                        'Tüm Ürün Geçmişi',
                        null, // null: kurtarılan + israf edilen hepsi birlikte
                        AppTheme.primaryGreen,
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Toplam Takip Edilen Ürün'),
                      subtitle: const Text('Detayları görmek için tıklayın'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalTracked',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showHistoryModal(
                        context,
                        'Kurtarılan Ürünler',
                        ProductOutcome.rescued,
                        AppTheme.statusFresh,
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.eco, color: AppTheme.statusFresh),
                      title: const Text('Kurtarılan Ürün'),
                      subtitle: const Text('Detayları görmek için tıklayın'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$rescuedCount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.statusFresh,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showHistoryModal(
                        context,
                        'İsraf Edilen Ürünler',
                        ProductOutcome.wasted,
                        AppTheme.statusExpired,
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline, color: AppTheme.statusExpired),
                      title: const Text('İsraf Edilen Ürün'),
                      subtitle: const Text('Detayları görmek için tıklayın'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$wastedCount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.statusExpired,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: totalDecided == 0
                        ? Container(color: Colors.grey.shade200)
                        : Row(
                            children: [
                              if (rescuedCount > 0)
                                Expanded(
                                  flex: rescuedCount,
                                  child: Container(color: AppTheme.statusFresh),
                                ),
                              if (wastedCount > 0)
                                Expanded(
                                  flex: wastedCount,
                                  child: Container(color: AppTheme.statusExpired),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _motiveEdiciMesajGetir(kurtarmaYuzdesi, totalDecided, rescuedCount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}