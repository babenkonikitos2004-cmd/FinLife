import 'package:finlife/models/transaction.dart' as model;
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringTransactionService {
  final StorageService _storageService = StorageService();
  final WidgetRef ref;

  RecurringTransactionService(this.ref);

  /// Check for recurring transactions and add them for the current month if needed
  Future<void> checkAndAddRecurringTransactions(String userId) async {
    try {
      // Get last check date
      final lastCheck = await _storageService.getLastRecurringCheck();
      final now = DateTime.now();
      
      // If we already checked this month, skip
      if (lastCheck != null && 
          lastCheck.year == now.year && 
          lastCheck.month == now.month) {
        return;
      }
      
      // Get all recurring transactions
      final transactions = ref.read(transactionProvider).transactions;
      final recurringTransactions = transactions.where((t) => t.isRecurring).toList();
      
      // Add recurring transactions for current month if not already added
      for (final transaction in recurringTransactions) {
        final exists = transactions.any((t) => 
          t.title == transaction.title && 
          t.amount == transaction.amount && 
          t.categoryId == transaction.categoryId &&
          t.date.year == now.year &&
          t.date.month == now.month
        );
        
        if (!exists) {
          // Create new transaction for current month
          final newTransaction = model.Transaction(
            id: '${transaction.id}_${now.year}_${now.month}',
            title: transaction.title,
            amount: transaction.amount,
            date: DateTime(now.year, now.month, transaction.date.day),
            type: transaction.type,
            categoryId: transaction.categoryId,
            isRecurring: true,
          );
          
          await ref.read(transactionProvider.notifier).addTransaction(newTransaction);
        }
      }
      
      // Save last check date
      await _storageService.saveLastRecurringCheck(now);
    } catch (e) {
      print('Error checking recurring transactions: $e');
    }
  }
}