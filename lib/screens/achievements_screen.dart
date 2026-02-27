import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/providers/gamification_provider.dart';
import 'package:finlife/constants/app_colors.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, we'll use mock data since the existing gamification system
    // stores achievements as a string rather than individual items
    final achievements = [
      {
        'emoji': '🏆',
        'title': 'Первая транзакция',
        'description': 'Добавь первую транзакцию',
        'unlocked': true,
      },
      {
        'emoji': '🔥',
        'title': '7 дней подряд',
        'description': 'Веди учёт 7 дней',
        'unlocked': false,
      },
      {
        'emoji': '💰',
        'title': 'Накопи 10 000₽',
        'description': 'Накопи первые 10 000₽',
        'unlocked': true,
      },
      {
        'emoji': '🎯',
        'title': 'Первая цель',
        'description': 'Создай финансовую цель',
        'unlocked': true,
      },
      {
        'emoji': '📊',
        'title': 'Аналитик',
        'description': 'Посмотри статистику 5 раз',
        'unlocked': false,
      },
      {
        'emoji': '✂️',
        'title': 'Экономия',
        'description': 'Потрать меньше чем заработал',
        'unlocked': false,
      },
    ];
    
    // Filter to show only unlocked achievements
    final unlockedAchievements = achievements.where((a) => a['unlocked'] as bool).toList();
    final unlockedCount = unlockedAchievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unlockedCount из ${achievements.length} достижений',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: unlockedCount / achievements.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Achievements grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: unlockedAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = unlockedAchievements[index];
                  return AchievementCard(
                    emoji: achievement['emoji'] as String,
                    title: achievement['title'] as String,
                    description: achievement['description'] as String,
                    unlocked: achievement['unlocked'] as bool,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  const AchievementCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? AppColors.primary.withOpacity(0.3) : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 12),
            // Lock icon for locked achievements
            if (!unlocked)
              const Icon(
                Icons.lock,
                color: Colors.grey,
                size: 20,
              ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: unlocked ? Colors.black : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: unlocked ? Colors.grey[700] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}