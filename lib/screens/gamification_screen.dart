import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/providers/gamification_provider.dart';
import 'package:finlife/screens/achievements_screen.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Геймификация'),
      ),
      body: gamificationState.isLoading
          ? Center(child: CircularProgressIndicator())
          : gamificationState.gamification == null
              ? Center(child: Text('Нет данных о геймификации'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ваша серия: ${gamificationState.gamification!.streak} дней',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Достижения:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AchievementsScreen(),
                                ),
                              );
                            },
                            child: Text('Посмотреть все'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(gamificationState.gamification!.achievements),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AchievementsScreen(),
                            ),
                          );
                        },
                        child: Text('Посмотреть все достижения'),
                      ),
                    ],
                  ),
                ),
    );
  }
}