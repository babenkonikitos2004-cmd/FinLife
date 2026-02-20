import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/providers/database_provider.dart';

class BudgetState {
  final List<db.Budget> budgets;
  final bool isLoading;

  BudgetState({this.budgets = const [], this.isLoading = false});

  BudgetState copyWith({List<db.Budget>? budgets, bool? isLoading}) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(ref);
});

class BudgetNotifier extends StateNotifier<BudgetState> {
  final Ref ref;

  BudgetNotifier(this.ref) : super(BudgetState());

  Future<void> loadBudgets(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final budgets = await database.getBudgetsByUser(userId);
      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addBudget(db.Budget budget) async {
    final database = ref.read(databaseProvider);
    await database.insertBudget(budget);
    
    // Обновляем список бюджетов
    final budgets = [...state.budgets, budget];
    state = state.copyWith(budgets: budgets);
  }

  Future<void> updateBudget(db.Budget budget) async {
    final database = ref.read(databaseProvider);
    await database.updateBudget(budget);
    
    // Обновляем список бюджетов
    final budgets = [...state.budgets];
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      budgets[index] = budget;
      state = state.copyWith(budgets: budgets);
    }
  }

  Future<void> deleteBudget(String id) async {
    final database = ref.read(databaseProvider);
    await database.deleteBudget(id);
    
    // Обновляем список бюджетов
    final budgets = [...state.budgets]..removeWhere((b) => b.id == id);
    state = state.copyWith(budgets: budgets);
  }
}