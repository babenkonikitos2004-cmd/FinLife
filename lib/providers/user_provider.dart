import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/models/user.dart' as model;
import 'package:finlife/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  final model.User? user;
  final bool isLoading;
  UserState({this.user, this.isLoading = false});
  UserState copyWith({model.User? user, bool? isLoading}) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<UserState> {
  final Ref ref;

  UserNotifier(this.ref) : super(UserState()) {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      print('DEBUG STARTUP: Loading saved userId: $userId');
      if (userId != null) {
        final database = ref.read(databaseProvider);
        final dbUser = await database.getUser(userId);
        state = state.copyWith(user: model.User(
          id: dbUser.id,
          name: dbUser.name,
          email: dbUser.email,
          monthlyIncome: dbUser.monthlyIncome,
          createdAt: dbUser.createdAt,
          gender: dbUser.gender,
          age: dbUser.age,
          financialGoal: dbUser.financialGoal,
        ));
        print('DEBUG STARTUP: User loaded: ${dbUser.id}');

        // Load transactions for this user
        ref.read(databaseProvider).getTransactionsByUser(userId).then((transactions) {
          print('DEBUG STARTUP: Found ${transactions.length} transactions');
        });
      }
    } catch (e) {
      print('DEBUG STARTUP: Error loading user: $e');
    }
  }

  Future<void> loadUser(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final user = await database.getUser(userId);
      state = state.copyWith(user: model.User(
        id: user.id,
        name: user.name,
        email: user.email,
        monthlyIncome: user.monthlyIncome,
        createdAt: user.createdAt,
        gender: user.gender,
        age: user.age,
        financialGoal: user.financialGoal,
      ), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createUser(model.User user) async {
    final database = ref.read(databaseProvider);
    final dbUser = db.User(
      id: user.id,
      name: user.name,
      email: user.email,
      monthlyIncome: user.monthlyIncome,
      createdAt: user.createdAt,
      gender: user.gender,
      age: user.age,
      financialGoal: user.financialGoal,
    );
    await database.insertUser(dbUser);
    state = state.copyWith(user: user);

    // Save user_id to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    print('DEBUG: Saved user_id to prefs: ${user.id}');
  }

  Future<void> updateUser(model.User user) async {
    final database = ref.read(databaseProvider);
    final dbUser = db.User(
      id: user.id,
      name: user.name,
      email: user.email,
      monthlyIncome: user.monthlyIncome,
      createdAt: user.createdAt,
      gender: user.gender,
      age: user.age,
      financialGoal: user.financialGoal,
    );
    await database.updateUser(dbUser);
    state = state.copyWith(user: user);

    // Save user_id to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
  }
}