import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/models/category.dart' as model;
import 'package:finlife/providers/database_provider.dart';

class CategoryState {
  final List<model.Category> categories;
  final bool isLoading;

  CategoryState({this.categories = const [], this.isLoading = false});

  CategoryState copyWith({List<model.Category>? categories, bool? isLoading}) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref);
});

class CategoryNotifier extends StateNotifier<CategoryState> {
  final Ref ref;

  CategoryNotifier(this.ref) : super(CategoryState());

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final categories = await database.getCategories();
      
      // Convert database categories to model categories
      final modelCategories = categories.map((category) => model.Category(
        id: category.id,
        name: category.name,
        type: category.isIncome ? model.CategoryType.income : model.CategoryType.expense,
        icon: category.icon,
        color: 0xFF000000, // Default color, can be customized
      )).toList();
      
      state = state.copyWith(categories: modelCategories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}