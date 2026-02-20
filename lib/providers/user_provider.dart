import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/models/user.dart' as model;
import 'package:finlife/providers/database_provider.dart';

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

  UserNotifier(this.ref) : super(UserState());

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
    // Convert model.User to database User
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
  }
}