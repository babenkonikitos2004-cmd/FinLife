import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:finlife/providers/category_provider.dart';
import 'package:finlife/utils/category_utils.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _filter = 'Все'; // Все / Доходы / Расходы

  @override
  void initState() {
    super.initState();
    // Load categories when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    // Apply search filter
    List<Transaction> filtered = List.from(transactions);
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
        t.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply type filter
    if (_filter == 'Доходы') {
      filtered = filtered.where((t) => t.type == TransactionType.income).toList();
    } else if (_filter == 'Расходы') {
      filtered = filtered.where((t) => t.type == TransactionType.expense).toList();
    }
    
    // Create a new list for sorting to avoid unmodifiable list error
    List<Transaction> sorted = List.from(filtered);
    
    // Sort by date (newest first)
    sorted.sort((a, b) => b.date.compareTo(a.date));
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final categoryState = ref.watch(categoryProvider);
    final userState = ref.watch(userProvider);

    // Load transactions when user is available
    if (userState.user != null && !transactionState.isLoading) {
      Future.microtask(() => 
        ref.read(transactionProvider.notifier).loadTransactions(userState.user!.id)
      );
    }

    final transactions = _filterTransactions(transactionState.transactions);
    final categories = categoryState.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История операций'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по названию',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: _filter == 'Все',
                    onSelected: (selected) {
                      setState(() {
                        _filter = selected ? 'Все' : 'Все';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Доходы'),
                    selected: _filter == 'Доходы',
                    onSelected: (selected) {
                      setState(() {
                        _filter = selected ? 'Доходы' : 'Все';
                      });
                    },
                    backgroundColor: Colors.green.withOpacity(0.1),
                    selectedColor: Colors.green.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Расходы'),
                    selected: _filter == 'Расходы',
                    onSelected: (selected) {
                      setState(() {
                        _filter = selected ? 'Расходы' : 'Все';
                      });
                    },
                    backgroundColor: Colors.red.withOpacity(0.1),
                    selectedColor: Colors.red.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Transactions list
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'Транзакций пока нет',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Group transactions by date
                          ..._groupTransactionsByDate(transactions).entries.map(
                                (entry) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...entry.value.map((transaction) {
                                      final category = categories.firstWhere(
                                        (c) => c.id == transaction.categoryId,
                                        orElse: () => Category(
                                          id: 'unknown',
                                          name: 'Неизвестная категория',
                                          type: transaction.type == TransactionType.income 
                                              ? CategoryType.income 
                                              : CategoryType.expense,
                                          icon: 'help',
                                          color: 0xFF000000,
                                        ),
                                      );
                                      
                                      return _buildTransactionItem(transaction, category);
                                    }).toList(),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final dateKey = DateFormat('d MMMM yyyy', 'ru').format(transaction.date);
      if (grouped.containsKey(dateKey)) {
        grouped[dateKey]!.add(transaction);
      } else {
        grouped[dateKey] = [transaction];
      }
    }
    
    return grouped;
  }

  // Helper function to get category icon with colored circle
  Widget _getCategoryIcon(String categoryId) {
    final categoryInfo = CategoryUtils.getCategoryInfo(categoryId);
    
    // Map category names to specific colors as requested
    final categoryColors = {
      'food': const Color(0xFFFF9800), // orange
      'Еда': const Color(0xFFFF9800), // orange
      'transport': const Color(0xFF2196F3), // blue
      'Транспорт': const Color(0xFF2196F3), // blue
      'health': const Color(0xFFF44336), // red
      'Здоровье': const Color(0xFFF44336), // red
      'entertainment': const Color(0xFF9C27B0), // purple
      'Развлечения': const Color(0xFF9C27B0), // purple
      'clothing': const Color(0xFFE91E63), // pink
      'Одежда': const Color(0xFFE91E63), // pink
      'salary': const Color(0xFF4CAF50), // green
      'Зарплата': const Color(0xFF4CAF50), // green
      'investments': const Color(0xFF009688), // teal
      'Инвестиции': const Color(0xFF009688), // teal
      'gifts': const Color(0xFFFFEB3B), // yellow
      'Подарки': const Color(0xFFFFEB3B), // yellow
      'cafe': const Color(0xFF795548), // brown
      'Кафе': const Color(0xFF795548), // brown
      'other': const Color(0xFF9E9E9E), // grey
      'Другое': const Color(0xFF9E9E9E), // grey
      'freelance': const Color(0xFF607D8B), // blue grey
      'Фриланс': const Color(0xFF607D8B), // blue grey
    };
    
    final color = categoryColors[categoryId] ?? categoryInfo.color;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          categoryInfo.emoji,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction, Category category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _getCategoryIcon(transaction.categoryId),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '${transaction.date.day}.${transaction.date.month}.${transaction.date.year}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ₽',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}