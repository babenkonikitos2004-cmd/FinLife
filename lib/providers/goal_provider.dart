import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/providers/database_provider.dart';

class GoalState {
  final List<db.FinancialGoal> goals;
  final bool isLoading;

  GoalState({this.goals = const [], this.isLoading = false});

  GoalState copyWith({List<db.FinancialGoal>? goals, bool? isLoading}) {
    return GoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  return GoalNotifier(ref);
});

class GoalNotifier extends StateNotifier<GoalState> {
  final Ref ref;

  GoalNotifier(this.ref) : super(GoalState());

  Future<void> loadGoals(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final goals = await database.getFinancialGoalsByUser(userId);
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addGoal(db.FinancialGoal goal) async {
    final database = ref.read(databaseProvider);
    await database.insertFinancialGoal(goal);
    
    // Обновляем список целей
    final goals = [...state.goals, goal];
    state = state.copyWith(goals: goals);
  }

  Future<void> updateGoal(db.FinancialGoal goal) async {
    final database = ref.read(databaseProvider);
    await database.updateFinancialGoal(goal);
    
    // Обновляем список целей
    final goals = [...state.goals];
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      state = state.copyWith(goals: goals);
    }
  }

  Future<void> deleteGoal(String id) async {
    final database = ref.read(databaseProvider);
    await database.deleteFinancialGoal(id);
    
    // Обновляем список целей
    final goals = [...state.goals]..removeWhere((g) => g.id == id);
    state = state.copyWith(goals: goals);
  }
}