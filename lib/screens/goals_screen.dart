import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import '../providers/goal_provider.dart';
import '../utils/formatters.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/user_provider.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _contributionController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedEmoji = '🎯';
  db.FinancialGoal? _currentGoal;

  @override
  void initState() {
    super.initState();
    // Load goals when user is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(userProvider);
      if (userState.user != null) {
        ref.read(goalProvider.notifier).loadGoals(userState.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои цели'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGoalDialog,
          ),
        ],
      ),
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : goalState.goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: goalState.goals.length,
                  itemBuilder: (context, index) {
                    return _GoalCard(
                      goal: goalState.goals[index],
                      onContribute: _showContributionDialog,
                      onUpdateGoal: _updateGoal,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Добавьте первую цель 🎯',
            style: AppStyles.headline3,
          ),
          const SizedBox(height: AppStyles.spacingMedium),
          ElevatedButton(
            onPressed: _showAddGoalDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Добавить цель'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    _titleController.clear();
    _targetAmountController.clear();
    _selectedDate = DateTime.now().add(const Duration(days: 30));
    _selectedEmoji = '🎯';
    _currentGoal = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить новую цель'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: AppStyles.inputDecoration('Название'),
                    ),
                    const SizedBox(height: AppStyles.spacingMedium),
                    TextField(
                      controller: _targetAmountController,
                      decoration: AppStyles.inputDecoration('Сумма цели'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacingMedium),
                    ListTile(
                      title: const Text('Дата достижения'),
                      subtitle: Text(_selectedDate != null
                          ? Formatters.formatDate(_selectedDate!)
                          : 'Выберите дату'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        // Dismiss keyboard before showing date picker to avoid IME conflicts
                        FocusScope.of(context).unfocus();
                        
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppStyles.spacingMedium),
                    ListTile(
                      title: const Text('Эмодзи'),
                      subtitle: Text(_selectedEmoji),
                      trailing: const Icon(Icons.emoji_emotions),
                      onTap: () {
                        // In a real app, you might want to show an emoji picker
                        // For now, we'll just use a simple dialog
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Выберите эмодзи'),
                              content: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Wrap(
                                      children: [
                                        '🎯',
                                        '🏠',
                                        '🚗',
                                        '💍',
                                        '🎓',
                                        '🏖️',
                                        '💻',
                                        '🎸',
                                        '📚',
                                        '🎮',
                                        '🎨',
                                        '🎵',
                                        '⚽',
                                        '✈️',
                                        '🏥',
                                      ]
                                          .map(
                                            (emoji) => Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedEmoji = emoji;
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                  emoji,
                                                  style: const TextStyle(
                                                    fontSize: 30,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveGoal();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContributionDialog(db.FinancialGoal goal) {
    _contributionController.clear();
    _currentGoal = goal;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Пополнить'),
          content: TextField(
            controller: _contributionController,
            decoration: AppStyles.inputDecoration('Сумма пополнения'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                _addContribution();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Пополнить'),
            ),
          ],
        );
      },
    );
  }

  void _saveGoal() {
    final userState = ref.read(userProvider);
    if (userState.user == null || _selectedDate == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final targetAmountText = _targetAmountController.text.trim();
    if (targetAmountText.isEmpty) return;

    final targetAmount = double.tryParse(targetAmountText.replaceAll(',', '.')) ?? 0.0;

    final newGoal = db.FinancialGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userState.user!.id,
      title: '$_selectedEmoji $title',
      description: '',
      targetAmount: targetAmount,
      currentAmount: 0.0,
      targetDate: _selectedDate!,
      createdAt: DateTime.now(),
    );

    ref.read(goalProvider.notifier).addGoal(newGoal);
  }

  void _addContribution() {
    if (_currentGoal == null) return;

    final contributionText = _contributionController.text.trim();
    if (contributionText.isEmpty) return;

    final contribution = double.tryParse(contributionText.replaceAll(',', '.')) ?? 0.0;
    if (contribution <= 0) return;

    final updatedGoal = db.FinancialGoal(
      id: _currentGoal!.id,
      userId: _currentGoal!.userId,
      title: _currentGoal!.title,
      description: _currentGoal!.description,
      targetAmount: _currentGoal!.targetAmount,
      currentAmount: _currentGoal!.currentAmount + contribution,
      targetDate: _currentGoal!.targetDate,
      createdAt: _currentGoal!.createdAt,
    );

    _updateGoal(updatedGoal);
  }

  void _updateGoal(db.FinancialGoal goal) {
    ref.read(goalProvider.notifier).updateGoal(goal);
  }
}

class _GoalCard extends StatelessWidget {
  final db.FinancialGoal goal;
  final Function(db.FinancialGoal) onContribute;
  final Function(db.FinancialGoal) onUpdateGoal;

  const _GoalCard({
    required this.goal,
    required this.onContribute,
    required this.onUpdateGoal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0).clamp(0.0, 1.0);
    
    // Extract emoji from title
    String emoji = '🎯';
    String title = goal.title;
    if (goal.title.length >= 2 && goal.title.codeUnitAt(0) >= 0xD800) {
      // Handle emoji (assuming it's at the beginning)
      final parts = goal.title.split(' ');
      if (parts.isNotEmpty) {
        emoji = parts[0];
        title = parts.skip(1).join(' ');
      }
    } else if (goal.title.length >= 2 && goal.title.substring(0, 2) == '🎯') {
      emoji = '🎯';
      title = goal.title.substring(2).trim();
    } else if (goal.title.length >= 1 && 
        (goal.title.codeUnitAt(0) >= 0x1F300 && goal.title.codeUnitAt(0) <= 0x1F9FF)) {
      emoji = goal.title.substring(0, 1);
      title = goal.title.substring(1).trim();
    } else {
      title = goal.title;
    }

    return Card(
      margin: const EdgeInsets.all(AppStyles.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppStyles.spacingSmall),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.headline4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              'Накоплено ${Formatters.formatCurrency(goal.currentAmount)} из ${Formatters.formatCurrency(goal.targetAmount)}',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              'До ${Formatters.formatDate(goal.targetDate)}',
              style: AppStyles.caption,
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onContribute(goal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                ),
                child: const Text('Пополнить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}