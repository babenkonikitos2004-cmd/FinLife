import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/screens/statistics_screen.dart';
import 'package:finlife/screens/goals_screen.dart';
import 'package:finlife/screens/profile_screen.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:finlife/widgets/transaction_modal.dart';
import 'package:finlife/utils/category_utils.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  DateTime _currentMonth = DateTime(2026, 2); // February 2026 as per design

  @override
  void initState() {
    super.initState();
    // Load user and transactions when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(userProvider);
      print('DEBUG: HomeScreen userState - user is null: ${userState.user == null}');
      if (userState.user != null) {
        print('DEBUG: Loading transactions for user: ${userState.user!.id}');
        // Use Future.microtask to avoid modifying provider during build
        Future.microtask(() {
          ref.read(transactionProvider.notifier).loadTransactions(userState.user!.id);
        });
      } else {
        print('DEBUG: No user found, cannot load transactions');
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also load transactions when dependencies change
    final userState = ref.watch(userProvider);
    if (userState.user != null && !userState.isLoading) {
      // Use Future.microtask to avoid modifying provider during build
      Future.microtask(() {
        ref.read(transactionProvider.notifier).loadTransactions(userState.user!.id);
      });
    }
  }

  void _changeMonth(int months) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + months,
      );
    });
  }

  double _calculateTotalBalance(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, transaction) {
      return sum + (transaction.type == TransactionType.income
          ? transaction.amount
          : -transaction.amount);
    });
  }

  double _calculateIncomeForMonth(List<Transaction> transactions, DateTime month) {
    return transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double _calculateExpensesForMonth(List<Transaction> transactions, DateTime month) {
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double _calculateBalanceForMonth(List<Transaction> transactions, DateTime month) {
    final income = _calculateIncomeForMonth(transactions, month);
    final expenses = _calculateExpensesForMonth(transactions, month);
    return income - expenses;
  }

  double _calculateSavingsPercentage(List<Transaction> transactions, DateTime month) {
    final income = _calculateIncomeForMonth(transactions, month);
    final expenses = _calculateExpensesForMonth(transactions, month);
    if (income == 0) return 0;
    return ((income - expenses) / income * 100).clamp(0, 100);
  }

  double _calculateAveragePerDay(List<Transaction> transactions, DateTime month) {
    final balance = _calculateBalanceForMonth(transactions, month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return balance / daysInMonth;
  }

  double _calculateSubscriptions(List<Transaction> transactions, DateTime month) {
    // Mock subscription data
    return 2840.0;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Handle FAB button tap
      _showAddTransactionDialog();
    } else if (index == 4) {
      // Navigate to History screen
      Navigator.pushNamed(context, '/history');
    } else {
      setState(() {
        _selectedIndex = index > 2 ? index - 1 : index;
      });
    }
  }

  void _showAddTransactionDialog([TransactionType? preselectedType]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return TransactionModal(preselectedType: preselectedType);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    
    // Use real data if available, otherwise use empty list (start with 0 balance)
    final transactions = transactionState.transactions;
    
    final totalBalance = _calculateTotalBalance(transactions);
    final monthBalance = _calculateBalanceForMonth(transactions, _currentMonth);
    final income = _calculateIncomeForMonth(transactions, _currentMonth);
    final expenses = _calculateExpensesForMonth(transactions, _currentMonth);
    final savingsPercentage = _calculateSavingsPercentage(transactions, _currentMonth);
    final averagePerDay = _calculateAveragePerDay(transactions, _currentMonth);
    final subscriptions = _calculateSubscriptions(transactions, _currentMonth);
    final monthName = DateFormat('MMMM yyyy', 'ru').format(_currentMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildTopBar(totalBalance),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthNavigator(monthName),
                const SizedBox(height: 20),
                _buildBalanceCard(monthBalance, income, expenses, savingsPercentage),
                const SizedBox(height: 20),
                _buildAIAdviceCard(),
                const SizedBox(height: 20),
                _buildQuickActionsRow(),
                const SizedBox(height: 20),
                _buildStatsRow(averagePerDay, monthBalance, subscriptions),
                const SizedBox(height: 20),
                _buildRecentTransactions(transactions),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  AppBar _buildTopBar(double totalBalance) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Все счета',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${NumberFormat('#,##0.00', 'ru_RU').format(totalBalance)} ₽',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.grid_on, color: Colors.black87),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.black87),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StatisticsScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.black87),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthNavigator(String monthName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          monthName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expenses, double savingsPercentage) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'БАЛАНС ЗА ПЕРИОД',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance > 0 ? '+' : ''}${NumberFormat('#,##0', 'ru_RU').format(balance)} ₽',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? const Color(0xFF4CAF50) : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Доход минус расходы за месяц',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat('#,##0', 'ru_RU').format(income)} ₽',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat('#,##0', 'ru_RU').format(expenses)} ₽',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: savingsPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7B61FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Сохранено ${savingsPercentage.round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7B61FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAdviceCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A237E),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '+ ИИ-совет',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Вы потратили на 12% больше на продукты в этом месяце. Рекомендуем проверить чеки и найти скидки.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Подробнее →',
            style: TextStyle(
              color: Color(0xFF7B61FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(Icons.account_balance, 'Доход', 0),
            _buildQuickActionItem(Icons.receipt, 'Чек', 1),
            _buildQuickActionItem(Icons.swap_horiz, 'Перевод', 2),
            _buildQuickActionItem(Icons.flag, 'Цели', 3),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, int index) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFF7B61FF)),
            onPressed: () {
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoalsScreen(),
                  ),
                );
              } else if (index == 0) {
                // Доход quick action
                _showAddTransactionDialog(TransactionType.income);
              } else {
                _showAddTransactionDialog();
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double avgPerDay, double saved, double subscriptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard('СР. В ДЕНЬ', '${NumberFormat('#,##0', 'ru_RU').format(avgPerDay)}₽', '+8% vs янв'),
            const SizedBox(width: 12),
            _buildStatCard('НАКОПЛЕНО', '${NumberFormat('#,##0', 'ru_RU').format(saved)}₽', '+24% vs янв'),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('ПОДПИСКИ', '${NumberFormat('#,##0', 'ru_RU').format(subscriptions)}₽', '= как всегда'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle) {
    return Container(
      width: title == 'ПОДПИСКИ' ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: subtitle.contains('+') 
                  ? const Color(0xFF4CAF50) 
                  : subtitle.contains('=') 
                      ? Colors.grey 
                      : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    // Sort transactions by date (newest first) and take the last 5
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = sortedTransactions.take(5).toList();

    if (recentTransactions.isEmpty) {
      return Container();
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in recentTransactions) {
      final dateKey = DateFormat('d MMMM yyyy', 'ru').format(transaction.date);
      if (groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey]!.add(transaction);
      } else {
        groupedTransactions[dateKey] = [transaction];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Недавние',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
              child: const Text(
                'Все транзакции →',
                style: TextStyle(
                  color: Color(0xFF7B61FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Display grouped transactions
        ...groupedTransactions.entries.map(
          (entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...entry.value.map((transaction) => _buildTransactionItem(transaction)).toList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final categoryInfo = CategoryUtils.getCategoryInfo(transaction.categoryId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryInfo.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                categoryInfo.emoji,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryInfo.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  transaction.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ₽',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: transaction.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      elevation: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home, 'Главная'),
          _buildNavItem(1, Icons.bar_chart, 'Статистика'),
          // Empty space for FAB
          const SizedBox(width: 60),
          _buildNavItem(3, Icons.flag, 'Цели'),
          _buildNavItem(4, Icons.history, 'История'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFF7B61FF) : Colors.grey,
            ),
          ),
        ],
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF7B61FF),
      onPressed: _showAddTransactionDialog,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}