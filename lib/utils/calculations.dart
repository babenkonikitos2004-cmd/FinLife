import '../database/database.dart' as db;
import '../models/transaction.dart';

class Calculations {
  static double calculateTotalAmount(List<Transaction> transactions) {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }
  
  static double calculateIncome(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }
  
  static double calculateExpenses(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }
  
  static Map<String, double> calculateExpensesByCategory(
      List<Transaction> transactions) {
    final Map<String, double> expensesByCategory = {};
    
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final categoryId = transaction.categoryId;
        if (expensesByCategory.containsKey(categoryId)) {
          expensesByCategory[categoryId] =
              expensesByCategory[categoryId]! + transaction.amount;
        } else {
          expensesByCategory[categoryId] = transaction.amount;
        }
      }
    }
    
    // Convert negative amounts to positive for display purposes
    final Map<String, double> positiveExpensesByCategory = {};
    expensesByCategory.forEach((key, value) {
      positiveExpensesByCategory[key] = value.abs();
    });
    
    return positiveExpensesByCategory;
  }
  
  static double calculateBudgetProgress(
      db.Budget budget, List<Transaction> transactions) {
    final budgetTransactions = transactions.where((transaction) =>
        transaction.categoryId == budget.categoryId &&
        transaction.type == TransactionType.expense &&
        transaction.date.isAfter(budget.startDate) &&
        transaction.date.isBefore(budget.endDate));
    
    final spent = budgetTransactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
    
    return spent.abs() / budget.amount; // Use absolute value since expenses are negative
  }
  
  static double calculateSavingsRate(
      List<Transaction> transactions, DateTime periodStart, DateTime periodEnd) {
    final periodTransactions = transactions.where((transaction) =>
        transaction.date.isAfter(periodStart) &&
        transaction.date.isBefore(periodEnd));
    
    final income = calculateIncome(periodTransactions.toList());
    final expenses = calculateExpenses(periodTransactions.toList());
    
    if (income == 0) return 0;
    
    return (income + expenses) / income; // Expenses are already negative
  }
}