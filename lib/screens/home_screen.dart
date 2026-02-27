import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/screens/statistics_screen.dart';
import 'package:finlife/screens/goals_screen.dart';
import 'package:finlife/screens/profile_screen.dart';
import 'package:finlife/screens/ai_advice_screen.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:finlife/providers/goal_provider.dart';
import 'package:finlife/widgets/transaction_modal.dart';
import 'package:finlife/utils/category_utils.dart';
import 'package:finlife/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _loadUserAndTransactions();
    });
    
    // Listen for user changes and load transactions when user becomes available
    ref.listenManual(userProvider, (prev, next) async {
      if (next.user != null && prev?.user == null) {
        ref.read(transactionProvider.notifier).loadTransactions(next.user!.id);
      } else {
        // Try to load transactions with saved user ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'user_1';
        ref.read(transactionProvider.notifier).loadTransactions(userId);
      }
    });
  }
  
  Future<void> _loadUserAndTransactions() async {
    final user = await StorageService().getUser();
    
    if (user != null) {
      // Update user provider with the loaded user
      ref.read(userProvider.notifier).state =
        UserState(user: user, isLoading: false);
      
      print('DEBUG: Loading transactions for user: ${user.id}');
      // Load transactions for the user
      ref.read(transactionProvider.notifier).loadTransactions(user.id);
    } else {
      print('DEBUG: No user found, cannot load transactions');
      // Try to load transactions with saved user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'user_1';
      print('DEBUG: Loading transactions for saved user ID: $userId');
      ref.read(transactionProvider.notifier).loadTransactions(userId);
    }
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
    } else {
      // Try to load transactions with saved user ID from SharedPreferences
      Future.microtask(() async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'user_1';
        print('DEBUG: Loading transactions for saved user ID in didChangeDependencies: $userId');
        ref.read(transactionProvider.notifier).loadTransactions(userId);
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
    // Now that expenses are stored as negative numbers, we can simply sum all amounts
    return transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
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
    return income + expenses; // Expenses are already negative, so we add them
  }

  double _calculateSavingsPercentage(List<Transaction> transactions, DateTime month) {
    final income = _calculateIncomeForMonth(transactions, month);
    final expenses = _calculateExpensesForMonth(transactions, month);
    if (income == 0) return 0;
    return ((income + expenses) / income * 100).clamp(0, 100); // Expenses are already negative
  }

  double _calculateAveragePerDay(List<Transaction> transactions, DateTime month) {
    final expenses = _calculateExpensesForMonth(transactions, month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return expenses / daysInMonth;
  }

  double _calculateSubscriptions(List<Transaction> transactions, DateTime month) {
    // Mock subscription data
    return 2840.0;
  }

  // Helper function to calculate highest overspending category
  Map<String, dynamic>? _calculateHighestOverspendingCategory(List<Transaction> transactions, DateTime month) {
    // Calculate expenses by category for current month
    final currentMonthExpensesByCategory = <String, double>{};
    final currentMonthStart = DateTime(month.year, month.month, 1);
    final nextMonthStart = DateTime(month.year, month.month + 1, 1);
    
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(nextMonthStart)) {
        final categoryId = transaction.categoryId;
        if (currentMonthExpensesByCategory.containsKey(categoryId)) {
          currentMonthExpensesByCategory[categoryId] =
              currentMonthExpensesByCategory[categoryId]! + transaction.amount;
        } else {
          currentMonthExpensesByCategory[categoryId] = transaction.amount;
        }
      }
    }
    
    // Calculate budget limits by category (using 1/3 of income as a simple rule)
    final income = _calculateIncomeForMonth(transactions, month);
    final budgetLimitPerCategory = income / 3; // Simple rule: no more than 1/3 of income per category
    
    // Find category with highest overspending
    String? highestOverspendingCategory;
    double highestOverspendingAmount = 0;
    
    currentMonthExpensesByCategory.forEach((categoryId, amount) {
      final overspending = amount.abs() - budgetLimitPerCategory;
      if (overspending > highestOverspendingAmount) {
        highestOverspendingAmount = overspending;
        highestOverspendingCategory = categoryId;
      }
    });
    
    if (highestOverspendingCategory != null) {
      return {
        'category': highestOverspendingCategory,
        'amount': highestOverspendingAmount,
      };
    }
    
    return null;
  }

  // Helper function to determine balance status
  String _getBalanceStatusMessage(double balance, double income) {
    if (balance > 0) {
      return 'Отличный месяц! Вы сохранили ${NumberFormat('#,###', 'ru').format(balance.abs())} ₽ 🎉';
    } else if (income > 0 && (balance.abs() / income) < 0.1) {
      return 'Вы почти не откладываете деньги 😟';
    } else {
      return '';
    }
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
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
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Handle FAB button tap
      _showAddTransactionDialog();
    } else {
      setState(() {
        _selectedIndex = index > 2 ? index - 1 : index;
      });
      
      // Navigate to respective screens
      if (index == 4) {
        Navigator.pushNamed(context, '/history');
      } else if (index == 1) {
        Navigator.pushNamed(context, '/statistics');
      } else if (index == 3) {
        Navigator.pushNamed(context, '/goals');
      }
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
                _buildGoalsProgressSection(),
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
            '${NumberFormat('#,###', 'ru').format(totalBalance)} ₽',
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
            '${balance > 0 ? '+' : ''}${NumberFormat('#,###', 'ru').format(balance)} ₽',
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
                      '${NumberFormat('#,###', 'ru').format(income)} ₽',
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
                      '${NumberFormat('#,###', 'ru').format(expenses)} ₽',
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
    // Get transactions from state
    final transactionState = ref.watch(transactionProvider);
    final transactions = transactionState.transactions;
    
    // Calculate advice data
    final highestOverspending = _calculateHighestOverspendingCategory(transactions, _currentMonth);
    final savingsPercentage = _calculateSavingsPercentage(transactions, _currentMonth);
    final monthBalance = _calculateBalanceForMonth(transactions, _currentMonth);
    final income = _calculateIncomeForMonth(transactions, _currentMonth);
    final balanceStatusMessage = _getBalanceStatusMessage(monthBalance, income);
    
    // Determine which message to show
    String adviceMessage = '';
    if (highestOverspending != null) {
      final categoryInfo = CategoryUtils.getCategoryInfo(highestOverspending['category']);
      adviceMessage = 'Вы тратите много на ${categoryInfo.name}. Сэкономьте до ${NumberFormat('#,###', 'ru').format(highestOverspending['amount'].abs())} ₽';
    } else if (balanceStatusMessage.isNotEmpty) {
      adviceMessage = balanceStatusMessage;
    } else {
      // Default message if no specific advice
      adviceMessage = 'Хорошо управляете финансами! Продолжайте в том же духе.';
    }
    
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
          Text(
            adviceMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIAdviceScreen(),
                ),
              );
            },
            child: const Text(
              'Подробнее →',
              style: TextStyle(
                color: Color(0xFF7B61FF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgressSection() {
    final goalState = ref.watch(goalProvider);
    final userState = ref.watch(userProvider);
    
    // Filter goals where currentAmount < targetAmount
    final activeGoals = goalState.goals.where((goal) => goal.currentAmount < goal.targetAmount).toList();
    
    // Hide section if no active goals
    if (activeGoals.isEmpty) {
      return Container();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activeGoals.length + 1, // +1 for the "Все цели" button
            itemBuilder: (context, index) {
              // Last item is the "Все цели" button
              if (index == activeGoals.length) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  child: Card(
                    color: const Color(0xFF7B61FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoalsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Все цели',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              final goal = activeGoals[index];
              final progress = (goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0).clamp(0.0, 1.0);
              final remaining = goal.targetAmount - goal.currentAmount;
              
              // Extract emoji and title
              String emoji = '🎯';
              String title = goal.title;
              if (goal.title.length >= 2 && goal.title.codeUnitAt(0) >= 0xD800) {
                // Handle emoji (assuming it's at the beginning)
                final parts = goal.title.split(' ');
                if (parts.isNotEmpty) {
                  emoji = parts[0];
                  title = parts.skip(1).join(' ');
                }
              } else if (goal.title.length >= 2 && goal.title.substring(0, 2) == '🎯') {
                emoji = '🎯';
                title = goal.title.substring(2).trim();
              } else if (goal.title.length >= 1 && 
                  (goal.title.codeUnitAt(0) >= 0x1F300 && goal.title.codeUnitAt(0) <= 0x1F9FF)) {
                emoji = goal.title.substring(0, 1);
                title = goal.title.substring(1).trim();
              } else {
                title = goal.title;
              }
              
              // Motivational text based on progress
              String motivationalText;
              if (progress >= 0.9) {
                motivationalText = 'Почти достигли!';
              } else if (progress >= 0.7) {
                motivationalText = 'Хороший прогресс!';
              } else if (progress >= 0.5) {
                motivationalText = 'Половина пути пройдена!';
              } else if (progress >= 0.3) {
                motivationalText = 'Продолжайте в том же духе!';
              } else {
                motivationalText = 'Начинаем путь к цели!';
              }
              
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.toDouble(),
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          motivationalText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormat('#,###', 'ru').format(remaining)} ₽ осталось накопить',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
            _buildStatCard('СР. В ДЕНЬ', '${NumberFormat('#,###', 'ru').format(avgPerDay)}₽', '+8% vs янв'),
            const SizedBox(width: 12),
            _buildStatCard('НАКОПЛЕНО', '${NumberFormat('#,###', 'ru').format(saved)}₽', '+24% vs янв'),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('ПОДПИСКИ', '${NumberFormat('#,###', 'ru').format(subscriptions)}₽', '= как всегда'),
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
          _getCategoryIcon(transaction.categoryId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CategoryUtils.getCategoryInfo(transaction.categoryId).name,
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
            '${NumberFormat('#,###', 'ru').format(transaction.amount.abs())} ₽',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: transaction.amount >= 0
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