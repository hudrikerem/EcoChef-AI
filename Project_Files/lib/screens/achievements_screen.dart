import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../state/product_store.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  int _currentValue(ProductStore store, AchievementMetric metric) {
    switch (metric) {
      case AchievementMetric.rescued:
        return store.rescuedCount;
      case AchievementMetric.recipes:
        return store.recipesMade;
    }
  }

  DateTime? _unlockedAt(ProductStore store, Achievement achievement) {
    for (final unlock in store.achievementHistory) {
      if (unlock.achievement.id == achievement.id) return unlock.achievedAt;
    }
    return null;
  }

  void _showAchievementDetails(
    BuildContext context,
    ProductStore store,
    Achievement achievement,
  ) {
    final currentValue = _currentValue(store, achievement.metric);
    final unlocked = currentValue >= achievement.threshold;
    final unlockedAt = unlocked ? _unlockedAt(store, achievement) : null;
    final color = unlocked ? AppTheme.primaryGreen : Colors.grey.shade500;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(achievement.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(achievement.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            if (unlocked) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      unlockedAt != null
                          ? 'Kazanıldı: ${_formatDate(unlockedAt)}'
                          : 'Kazanıldı',
                      style: const TextStyle(
                          color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'İlerleme: $currentValue / ${achievement.threshold}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (currentValue / achievement.threshold).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final history = store.achievementHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Başarımlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${store.unlockedAchievements.length}/${allAchievements.length} rozet kazanıldı',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bir rozete dokunarak nasıl kazanılacağını görebilirsin.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allAchievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final achievement = allAchievements[index];
              final unlocked =
                  store.unlockedAchievements.contains(achievement);
              return _AchievementBadge(
                achievement: achievement,
                unlocked: unlocked,
                onTap: () => _showAchievementDetails(context, store, achievement),
              );
            },
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Henüz kazanılmış bir başarım yok.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...history.map((unlock) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      child: Icon(unlock.achievement.icon,
                          color: Colors.white, size: 20),
                    ),
                    title: Text(unlock.achievement.title),
                    subtitle: Text(unlock.achievement.description),
                    trailing: Text(_formatDate(unlock.achievedAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () =>
                        _showAchievementDetails(context, store, unlock.achievement),
                  ),
                )),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final VoidCallback onTap;

  const _AchievementBadge({
    required this.achievement,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppTheme.primaryGreen : Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                unlocked ? color.withValues(alpha: 0.15) : Colors.grey.shade200,
            child: Icon(
              unlocked ? achievement.icon : Icons.lock_outline,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: unlocked ? Colors.black87 : Colors.grey,
              fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}