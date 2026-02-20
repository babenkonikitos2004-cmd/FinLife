import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../utils/formatters.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/user_provider.dart';
import '../database/database.dart' as db;

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    // Get user ID from user provider and load budgets
    final userState = ref.read(userProvider);
    if (userState.user != null) {
      ref.read(budgetProvider.notifier).loadBudgets(userState.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бюджет'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: budgetState.budgets.length,
              itemBuilder: (context, index) {
                final budget = budgetState.budgets[index];
                return _BudgetCard(budget: budget);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudgetDialog() {
    // TODO: Implement add budget dialog
  }
}

class _BudgetCard extends StatelessWidget {
  final db.Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppStyles.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Категория: ${budget.categoryId}',
                  style: AppStyles.headline4,
                ),
                Text(
                  Formatters.formatCurrency(budget.amount),
                  style: AppStyles.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            LinearProgressIndicator(
              value: 0.5, // TODO: Calculate actual progress
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Израсходовано: ${Formatters.formatCurrency(budget.amount * 0.5)}',
                  style: AppStyles.bodyMedium,
                ),
                Text(
                  '${Formatters.formatDate(budget.startDate)} - ${Formatters.formatDate(budget.endDate)}',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}