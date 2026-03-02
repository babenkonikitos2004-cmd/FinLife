import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  GoalNotifier(this.ref) : super(GoalState()) {
    _loadSavedGoals();
  }

  Future<void> _loadSavedGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'user_1';
      print('DEBUG GOALS: Loading goals for userId: $userId');
      await loadGoals(userId);
    } catch (e) {
      print('DEBUG GOALS: Error loading goals: $e');
    }
  }

  Future<void> loadGoals(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final goals = await database.getFinancialGoalsByUser(userId);
      print('DEBUG GOALS: Loaded ${goals.length} goals');
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      print('DEBUG GOALS: Error in loadGoals: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addGoal(db.FinancialGoal goal) async {
    try {
      final database = ref.read(databaseProvider);
      await database.insertFinancialGoal(goal);
      final goals = [...state.goals, goal];
      state = state.copyWith(goals: goals);
      print('DEBUG GOALS: Goal added: ${goal.title}');
    } catch (e) {
      print('DEBUG GOALS: Error adding goal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal(db.FinancialGoal goal) async {
    try {
      final database = ref.read(databaseProvider);
      await database.updateFinancialGoal(goal);
      final goals = [...state.goals];
      final index = goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        goals[index] = goal;
        state = state.copyWith(goals: goals);
      }
    } catch (e) {
      print('DEBUG GOALS: Error updating goal: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final database = ref.read(databaseProvider);
      await database.deleteFinancialGoal(id);
      final goals = [...state.goals]..removeWhere((g) => g.id == id);
      state = state.copyWith(goals: goals);
    } catch (e) {
      print('DEBUG GOALS: Error deleting goal: $e');
      rethrow;
    }
  }
}