import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/formatters.dart';
import '../utils/calculations.dart';
import '../widgets/banner_widget.dart';

class AIRecommendationsScreen extends ConsumerStatefulWidget {
  const AIRecommendationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIRecommendationsScreen> createState() => _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends ConsumerState<AIRecommendationsScreen> {
  List<Recommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _generateRecommendations();
  }

  void _generateRecommendations() {
    final transactionState = ref.read(transactionProvider);
    final budgetState = ref.read(budgetProvider);
    
    final recommendations = <Recommendation>[];
    
    // Анализ расходов по категориям
    final expensesByCategory = Calculations.calculateExpensesByCategory(transactionState.transactions);
    
    // Рекомендации по категориям с высокими расходами
    expensesByCategory.forEach((categoryId, amount) {
      // TODO: Получить имя категории по ID
      final categoryName = 'Категория $categoryId';
      
      if (amount > 10000) { // Если расходы по категории превышают 10000 ₽
        recommendations.add(
          Recommendation(
            id: 'high_spending_$categoryId',
            title: 'Высокие расходы на $categoryName',
            description: 'Вы потратили ${Formatters.formatCurrency(amount)} на $categoryName за последний месяц. '
                'Попробуйте сократить расходы в этой категории на 10%.',
            priority: RecommendationPriority.high,
            category: RecommendationCategory.spending,
          ),
        );
      }
    });
    
    // Рекомендации по бюджетам
    for (final budget in budgetState.budgets) {
      final progress = Calculations.calculateBudgetProgress(budget, transactionState.transactions);
      
      if (progress > 0.9) {
        recommendations.add(
          Recommendation(
            id: 'budget_exceeded_${budget.id}',
            title: 'Бюджет превышен',
            description: 'Вы почти исчерпали бюджет на категорию с ID "${budget.categoryId}". '
                'Вы уже потратили ${Formatters.formatPercentage(progress)} от запланированной суммы.',
            priority: RecommendationPriority.high,
            category: RecommendationCategory.budget,
          ),
        );
      } else if (progress > 0.7) {
        recommendations.add(
          Recommendation(
            id: 'budget_warning_${budget.id}',
            title: 'Бюджет подходит к концу',
            description: 'Вы уже потратили ${Formatters.formatPercentage(progress)} от бюджета на категорию с ID "${budget.categoryId}". '
                'Следите за расходами в этой категории.',
            priority: RecommendationPriority.medium,
            category: RecommendationCategory.budget,
          ),
        );
      }
    }
    
    // Рекомендации по сбережениям
    final income = Calculations.calculateIncome(transactionState.transactions);
    final expenses = Calculations.calculateExpenses(transactionState.transactions);
    final savingsRate = income > 0 ? (income - expenses) / income : 0;
    
    if (savingsRate < 0.1) { // Если уровень сбережений меньше 10%
      recommendations.add(
        Recommendation(
          id: 'low_savings',
          title: 'Низкий уровень сбережений',
          description: 'Ваш уровень сбережений составляет ${Formatters.formatPercentage(savingsRate.toDouble())}. '
              'Попробуйте увеличить его до 15% для финансовой стабильности.',
          priority: RecommendationPriority.medium,
          category: RecommendationCategory.savings,
        ),
      );
    }
    
    setState(() {
      _recommendations = recommendations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации ИИ'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _generateRecommendations();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Персональные рекомендации',
                  style: AppStyles.headline3,
                ),
                const SizedBox(height: AppStyles.spacingMedium),
                // Banner widget
                const BannerWidget(
                  height: 150,
                  margin: EdgeInsets.only(bottom: AppStyles.spacingMedium),
                ),
                if (_recommendations.isEmpty) ...[
                  const Center(
                    child: Text('Рекомендации не найдены'),
                  ),
                ] else ...[
                  for (final recommendation in _recommendations)
                    _buildRecommendationCard(recommendation),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    IconData icon;
    Color color;
    
    switch (recommendation.category) {
      case RecommendationCategory.spending:
        icon = Icons.shopping_cart;
        color = AppColors.expense;
        break;
      case RecommendationCategory.budget:
        icon = Icons.account_balance_wallet;
        color = AppColors.primary;
        break;
      case RecommendationCategory.savings:
        icon = Icons.savings;
        color = AppColors.income;
        break;
      default:
        icon = Icons.lightbulb;
        color = AppColors.primary;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingSmall),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppStyles.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recommendation.title,
                          style: AppStyles.headline4,
                        ),
                      ),
                      if (recommendation.priority == RecommendationPriority.high)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacingSmall,
                            vertical: AppStyles.spacingXSmall,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                          ),
                          child: const Text(
                            'Важно',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacingSmall),
                  Text(
                    recommendation.description,
                    style: AppStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum RecommendationPriority { low, medium, high }
enum RecommendationCategory { spending, budget, savings }

class Recommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final RecommendationCategory category;

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
  });
}