import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/models/gamification.dart';
import 'package:finlife/providers/database_provider.dart';

class GamificationState {
  final db.GamificationData? gamification;
  final bool isLoading;

  GamificationState({this.gamification, this.isLoading = false});

  GamificationState copyWith({db.GamificationData? gamification, bool? isLoading}) {
    return GamificationState(
      gamification: gamification ?? this.gamification,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier(ref);
});

class GamificationNotifier extends StateNotifier<GamificationState> {
  final Ref ref;

  GamificationNotifier(this.ref) : super(GamificationState());

  Future<void> loadGamification(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final gamification = await database.getGamification(userId);
      state = state.copyWith(gamification: gamification, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addGamification(db.GamificationData gamification) async {
    final database = ref.read(databaseProvider);
    await database.insertGamification(gamification);
    state = state.copyWith(gamification: gamification);
  }

  Future<void> updateGamification(db.GamificationData gamification) async {
    final database = ref.read(databaseProvider);
    await database.updateGamification(gamification);
    state = state.copyWith(gamification: gamification);
  }
}