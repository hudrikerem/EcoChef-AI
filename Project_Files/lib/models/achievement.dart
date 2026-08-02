import 'package:flutter/material.dart';

enum AchievementMetric {
  rescued,

  recipes,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementMetric metric;
  final int threshold;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.metric,
    required this.threshold,
  });
}

const List<Achievement> allAchievements = [
  Achievement(
    id: 'rescued_1',
    title: 'İlk Kurtarış',
    description: 'İlk ürününü israf olmaktan kurtardın',
    icon: Icons.eco,
    metric: AchievementMetric.rescued,
    threshold: 1,
  ),
  Achievement(
    id: 'rescued_5',
    title: 'İsraf Avcısı',
    description: '5 ürünü israf olmaktan kurtardın',
    icon: Icons.emoji_events,
    metric: AchievementMetric.rescued,
    threshold: 5,
  ),
  Achievement(
    id: 'rescued_10',
    title: 'Bilinçli Tüketici',
    description: '10 ürünü israf olmaktan kurtardın',
    icon: Icons.military_tech,
    metric: AchievementMetric.rescued,
    threshold: 10,
  ),
  Achievement(
    id: 'rescued_25',
    title: 'Mutfak Kahramanı',
    description: '25 ürünü israf olmaktan kurtardın',
    icon: Icons.workspace_premium,
    metric: AchievementMetric.rescued,
    threshold: 25,
  ),
  Achievement(
    id: 'rescued_50',
    title: 'Sıfır Atık Ustası',
    description: '50 ürünü israf olmaktan kurtardın',
    icon: Icons.stars,
    metric: AchievementMetric.rescued,
    threshold: 50,
  ),
  Achievement(
    id: 'recipes_1',
    title: 'İlk Tarif',
    description: 'İlk tarifini yaptın',
    icon: Icons.restaurant_menu,
    metric: AchievementMetric.recipes,
    threshold: 1,
  ),
  Achievement(
    id: 'recipes_5',
    title: 'Şef Adayı',
    description: '5 tarif yaptın',
    icon: Icons.soup_kitchen,
    metric: AchievementMetric.recipes,
    threshold: 5,
  ),
  Achievement(
    id: 'recipes_10',
    title: 'Mutfak Ustası',
    description: '10 tarif yaptın',
    icon: Icons.ramen_dining,
    metric: AchievementMetric.recipes,
    threshold: 10,
  ),
  Achievement(
    id: 'recipes_25',
    title: 'EcoChef',
    description: '25 tarif yaptın',
    icon: Icons.local_fire_department,
    metric: AchievementMetric.recipes,
    threshold: 25,
  ),
];

class AchievementUnlock {
  final Achievement achievement;
  final DateTime achievedAt;

  const AchievementUnlock({required this.achievement, required this.achievedAt});
}
