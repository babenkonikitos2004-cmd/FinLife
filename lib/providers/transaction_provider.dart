import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart' as db;
import 'package:finlife/models/transaction.dart' as model;
import 'package:finlife/providers/database_provider.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Conversion functions between database and model Transaction types
model.TransactionType _stringToTransactionType(String type) {
  switch (type) {
    case 'income':
      return model.TransactionType.income;
    case 'expense':
    default:
      return model.TransactionType.expense;
  }
}

String _transactionTypeToString(model.TransactionType type) {
  switch (type) {
    case model.TransactionType.income:
      return 'income';
    case model.TransactionType.expense:
    default:
      return 'expense';
  }
}

model.Transaction _dbToModelTransaction(db.Transaction transaction) {
  return model.Transaction(
    id: transaction.id,
    title: transaction.description, // Using description as title
    amount: transaction.amount,
    date: transaction.date,
    type: _stringToTransactionType(transaction.type),
    categoryId: transaction.categoryId,
    isRecurring: transaction.isRecurring ?? false,
  );
}

db.Transaction _modelToDbTransaction(model.Transaction transaction, String userId) {
  return db.Transaction(
    id: transaction.id,
    userId: userId,
    categoryId: transaction.categoryId,
    description: transaction.title,
    amount: transaction.amount,
    type: _transactionTypeToString(transaction.type),
    date: transaction.date,
    isRecurring: transaction.isRecurring,
    createdAt: DateTime.now(),
  );
}

class TransactionState {
  final List<model.Transaction> transactions;
  final bool isLoading;

  TransactionState({this.transactions = const [], this.isLoading = false});

  TransactionState copyWith({List<model.Transaction>? transactions, bool? isLoading}) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});

class TransactionNotifier extends StateNotifier<TransactionState> {
  final Ref ref;

  TransactionNotifier(this.ref) : super(TransactionState());

  Future<void> loadTransactions(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final database = ref.read(databaseProvider);
      final transactions = await database.getTransactionsByUser(userId);
      state = state.copyWith(transactions: transactions.map(_dbToModelTransaction).toList(), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    try {
      final database = ref.read(databaseProvider);
      final userState = ref.read(userProvider);
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('user_id');
      final userId = userState.user?.id ?? savedUserId ?? 'user_1';
      print('DEBUG: User ID in addTransaction: $userId');

      final dbTransaction = _modelToDbTransaction(transaction, userId);
      await database.insertTransaction(dbTransaction);
      print('DEBUG: Transaction inserted into database');

      // Just add to state directly, no reload
      final updated = [...state.transactions, transaction];
      state = state.copyWith(transactions: updated);
      print('DEBUG: State updated with new transaction');
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    try {
      final database = ref.read(databaseProvider);
      // Get current user ID
      final userState = ref.read(userProvider);
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('user_id');
      final userId = userState.user?.id ?? savedUserId ?? 'user_1';
      print('DEBUG: User ID in updateTransaction: $userId');
      
      final dbTransaction = _modelToDbTransaction(transaction, userId);
      await database.updateTransaction(dbTransaction);
      print('DEBUG: Transaction updated in database');
      
      // Update state directly instead of reloading all transactions
      final updatedTransaction = _dbToModelTransaction(dbTransaction);
      final updatedTransactions = [...state.transactions];
      final index = updatedTransactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        updatedTransactions[index] = updatedTransaction;
        state = state.copyWith(transactions: updatedTransactions);
      }
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    final database = ref.read(databaseProvider);
    await database.deleteTransaction(id);
    
    // Обновляем список транзакций
    final transactions = [...state.transactions]..removeWhere((t) => t.id == id);
    state = state.copyWith(transactions: transactions);
  }
}