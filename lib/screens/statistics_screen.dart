import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/category_provider.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:finlife/utils/calculations.dart';
import 'package:finlife/utils/formatters.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  void _selectMonth(DateTime month) {
    setState(() {
      _selectedMonth = month;
    });
  }

  void _showMonthPicker() async {
    // Dismiss keyboard before showing date picker to avoid IME conflicts
    FocusScope.of(context).unfocus();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      _selectMonth(DateTime(picked.year, picked.month));
    }
  }

  List<Transaction> _getTransactionsForMonth(List<Transaction> transactions) {
    return transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month;
    }).toList();
  }

  List<Transaction> _getTransactionsForWeek(
      List<Transaction> transactions, int weekNumber) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstDayOfWeek = firstDayOfMonth.add(Duration(days: (weekNumber - 1) * 7));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));

    return transactions.where((transaction) {
      return transaction.date.isAfter(firstDayOfWeek.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(lastDayOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  int _getWeeksInMonth(DateTime date) {
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    // Calculate total weeks needed
    final totalDays = firstWeekday - 1 + daysInMonth;
    return (totalDays / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final categoryState = ref.watch(categoryProvider);
    final userState = ref.watch(userProvider);

    if (transactionState.isLoading || categoryState.isLoading || userState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final transactions = _getTransactionsForMonth(transactionState.transactions);
    final incomeTransactions = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final totalIncome = Calculations.calculateIncome(transactions);
    final totalExpenses = Calculations.calculateExpenses(transactions);
    final savings = totalIncome - totalExpenses;
    
    // Calculate savings percentage
    final savingsPercentage = totalIncome > 0 ? (savings / totalIncome) : 0.0;
    
    // Get user's monthly income
    final double monthlyIncome = userState.user?.monthlyIncome ?? 0.0;

    final expensesByCategory = Calculations.calculateExpensesByCategory(transactions);
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Categories = sortedCategories.take(3).toList();

    final weeksInMonth = _getWeeksInMonth(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            _buildMonthSelector(),
            
            const SizedBox(height: 16),
            
            // Savings progress card
            _buildSavingsProgressCard(savings, savingsPercentage, monthlyIncome),
            
            const SizedBox(height: 16),
            
            // Summary cards
            _buildSummaryCards(totalIncome, totalExpenses, savings),
            
            const SizedBox(height: 16),
            
            // Pie chart for expenses by category
            _buildPieChartSection(expenseTransactions, categoryState.categories),
            
            const SizedBox(height: 16),
            
            // Bar chart for last 6 months income vs expenses
            _buildMonthlyBarChartSection(transactionState.transactions),
            
            const SizedBox(height: 16),
            
            // Top 3 categories with progress bars
            _buildTopCategoriesSection(top3Categories, categoryState.categories, expensesByCategory),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedMonth.month} ${_selectedMonth.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: _showMonthPicker,
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsProgressCard(double savings, double savingsPercentage, double monthlyIncome) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Накоплено в этом месяце',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Formatters.formatCurrency(savings)} ₽',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: savingsPercentage > 0 ? savingsPercentage : 0,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                backgroundColor: Colors.grey[300]!,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.formatPercentage(savingsPercentage)} от дохода',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expenses, double savings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Доходы',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(income)} ₽',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Расходы',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(expenses)} ₽',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: savings >= 0 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Сбережения',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(savings)} ₽',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: savings >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(List<Transaction> expenseTransactions, List<Category> categories) {
    if (expenseTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Text('Нет данных о расходах'),
          ),
        ),
      );
    }

    final expensesByCategory = Calculations.calculateExpensesByCategory(expenseTransactions);
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final total = sortedCategories.fold(0.0, (sum, item) => sum + item.value);
    final List<PieChartSectionData> sections = [];

    for (int i = 0; i < sortedCategories.length && i < 5; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / total) * 100;
      
      // Find category name
      final category = categories.firstWhere(
        (cat) => cat.id == entry.key,
        orElse: () => Category(
          id: entry.key,
          name: 'Неизвестно',
          type: CategoryType.expense,
          icon: '',
          color: 0xFF000000,
        ),
      );
      
      sections.add(
        PieChartSectionData(
          color: _getColorForIndex(i),
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Add "Other" section if there are more than 5 categories
    if (sortedCategories.length > 5) {
      double otherValue = 0;
      for (int i = 5; i < sortedCategories.length; i++) {
        otherValue += sortedCategories[i].value;
      }
      final otherPercentage = (otherValue / total) * 100;
      
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: otherValue,
          title: '${otherPercentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Расходы по категориям',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < sortedCategories.length && i < 5; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: _getColorForIndex(i),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          categories.firstWhere(
                            (cat) => cat.id == sortedCategories[i].key,
                            orElse: () => Category(
                              id: sortedCategories[i].key,
                              name: 'Неизвестно',
                              type: CategoryType.expense,
                              icon: '',
                              color: 0xFF000000,
                            ),
                          ).name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChartSection(List<Transaction> allTransactions) {
    // Get last 6 months
    final List<BarChartGroupData> barGroups = [];
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTransactions = allTransactions.where((t) {
        return t.date.year == month.year && t.date.month == month.month;
      }).toList();
      
      final income = Calculations.calculateIncome(monthTransactions);
      final expenses = Calculations.calculateExpenses(monthTransactions);
      
      barGroups.add(
        BarChartGroupData(
          x: 5 - i, // 0 to 5 for last 6 months
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Доходы и расходы за последние 6 месяцев',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: barGroups.isNotEmpty
                      ? barGroups
                          .expand((group) => group.barRods)
                          .map((rod) => rod.toY)
                          .reduce((a, b) => a > b ? a : b) *
                          1.2
                      : 1000,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (
                        BarChartGroupData group,
                        int groupIndex,
                        BarChartRodData rod,
                        int rodIndex,
                      ) {
                        // Get month name
                        final monthIndex = 5 - groupIndex;
                        final month = DateTime(now.year, now.month - monthIndex, 1);
                        final monthName = _getMonthName(month.month);
                        
                        return BarTooltipItem(
                          '$monthName ${month.year}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toStringAsFixed(2)} ₽',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                      tooltipPadding: const EdgeInsets.all(4),
                      tooltipMargin: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Get month name for the value
                          final monthIndex = 5 - value.toInt();
                          final month = DateTime(now.year, now.month - monthIndex, 1);
                          final monthName = _getMonthName(month.month);
                          
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              monthName.substring(0, 3), // First 3 letters
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${Formatters.formatCurrency(value)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Доходы',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Расходы',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeeklyBarChartSection(List<Transaction> transactions, int weeksInMonth) {
    final List<BarChartGroupData> barGroups = [];
    
    for (int week = 1; week <= weeksInMonth; week++) {
      final weekTransactions = _getTransactionsForWeek(transactions, week);
      final income = Calculations.calculateIncome(weekTransactions);
      final expenses = Calculations.calculateExpenses(weekTransactions);
      
      barGroups.add(
        BarChartGroupData(
          x: week,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Доходы и расходы по неделям',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: barGroups.isNotEmpty
                      ? barGroups
                          .expand((group) => group.barRods)
                          .map((rod) => rod.toY)
                          .reduce((a, b) => a > b ? a : b) *
                          1.2
                      : 1000,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (
                        BarChartGroupData group,
                        int groupIndex,
                        BarChartRodData rod,
                        int rodIndex,
                      ) {
                        return BarTooltipItem(
                          'Неделя ${group.x}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toStringAsFixed(2)} ₽',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                      tooltipPadding: const EdgeInsets.all(4),
                      tooltipMargin: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              'Н${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${Formatters.formatCurrency(value)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Доходы',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Расходы',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesSection(
    List<MapEntry<String, double>> topCategories,
    List<Category> allCategories,
    Map<String, double> expensesByCategory,
  ) {
    if (topCategories.isEmpty) {
      return const SizedBox();
    }

    // Calculate max value for progress bars
    final maxValue = topCategories.isNotEmpty
        ? topCategories.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Топ расходов',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < topCategories.length; i++)
                    _buildCategoryProgressItem(
                      topCategories[i],
                      allCategories,
                      maxValue,
                      i,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgressItem(
    MapEntry<String, double> categoryEntry,
    List<Category> allCategories,
    double maxValue,
    int index,
  ) {
    final category = allCategories.firstWhere(
      (cat) => cat.id == categoryEntry.key,
      orElse: () => Category(
        id: categoryEntry.key,
        name: 'Неизвестно',
        type: CategoryType.expense,
        icon: '',
        color: 0xFF000000,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('${Formatters.formatCurrency(categoryEntry.value)} ₽'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: categoryEntry.value / maxValue,
              valueColor: AlwaysStoppedAnimation<Color>(_getColorForIndex(index)),
              backgroundColor: Colors.grey[300]!,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month - 1];
  }
  
  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}