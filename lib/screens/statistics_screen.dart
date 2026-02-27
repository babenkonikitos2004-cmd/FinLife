import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/category_provider.dart';
import 'package:finlife/utils/calculations.dart';
import 'package:finlife/utils/formatters.dart';
import 'package:finlife/utils/category_utils.dart';
import 'package:finlife/constants/app_colors.dart';

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

  List<Transaction> _getTransactionsForMonth(List<Transaction> transactions) {
    return transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month;
    }).toList();
  }

  List<Transaction> _getTransactionsForLastMonths(
      List<Transaction> transactions, int months) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    
    return transactions.where((transaction) {
      return transaction.date.isAfter(startDate) ||
          transaction.date.isAtSameMomentAs(startDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final categoryState = ref.watch(categoryProvider);

    if (transactionState.isLoading || categoryState.isLoading) {
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
    final balance = totalIncome + totalExpenses; // Expenses are negative
    
    // Calculate savings percentage
    final savingsPercentage = totalIncome > 0 ? ((totalIncome + totalExpenses) / totalIncome) : 0.0;
    
    final expensesByCategory = Calculations.calculateExpensesByCategory(transactions);
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Categories = sortedCategories.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP SUMMARY CARDS
            _buildSummaryCards(totalIncome, totalExpenses.abs(), balance),
            
            const SizedBox(height: 16),
            
            // SAVINGS RATE card
            _buildSavingsRateCard(savingsPercentage),
            
            const SizedBox(height: 16),
            
            // PIE CHART "Расходы по категориям"
            _buildPieChartSection(expenseTransactions, categoryState.categories),
            
            const SizedBox(height: 16),
            
            // BAR CHART "Доходы vs Расходы" last 6 months
            _buildMonthlyBarChartSection(transactionState.transactions),
            
            const SizedBox(height: 16),
            
            // TOP SPENDING LIST
            _buildTopSpendingList(top5Categories, categoryState.categories, expensesByCategory),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expenses, double balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Доходы',
                    style: TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(income)}',
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
                color: AppColors.expense.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Расходы',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(expenses)}',
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
                color: (balance >= 0 
                    ? AppColors.income 
                    : AppColors.expense).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Баланс',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(balance)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? AppColors.income : AppColors.expense,
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

  Widget _buildSavingsRateCard(double savingsPercentage) {
    // Determine color based on savings percentage
    Color circleColor;
    if (savingsPercentage >= 0.2) {
      circleColor = AppColors.income; // green
    } else if (savingsPercentage >= 0.1) {
      circleColor = Colors.orange; // yellow
    } else {
      circleColor = AppColors.expense; // red
    }
    
    final percentageText = '${(savingsPercentage * 100).toStringAsFixed(1)}%';
    
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
          children: [
            const Text(
              'Вы сохраняете',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: savingsPercentage > 1 ? 1 : savingsPercentage,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(circleColor),
                  ),
                ),
                Text(
                  percentageText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'дохода',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: circleColor,
              ),
            ),
          ],
        ),
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
      
      // Find category
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
          color: Color(category.color),
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
                'Расходы по категориям',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 200,
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
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < sortedCategories.length && i < 5; i++)
                    _buildLegendItem(sortedCategories[i], categories, total, i),
                  if (sortedCategories.length > 5)
                    _buildLegendItemOther(sortedCategories, total),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(MapEntry<String, double> entry, List<Category> categories, double total, int index) {
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
    
    final categoryName = CategoryUtils.getCategoryInfo(category.name).name;
    final percentage = (entry.value / total) * 100;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(category.color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$categoryName ${percentage.toStringAsFixed(1)}% (${Formatters.formatCurrency(entry.value)})',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLegendItemOther(List<MapEntry<String, double>> sortedCategories, double total) {
    double otherValue = 0;
    for (int i = 5; i < sortedCategories.length; i++) {
      otherValue += sortedCategories[i].value;
    }
    final otherPercentage = (otherValue / total) * 100;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Другое ${otherPercentage.toStringAsFixed(1)}% (${Formatters.formatCurrency(otherValue)})',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChartSection(List<Transaction> allTransactions) {
    // Get last 6 months
    final List<BarChartGroupData> barGroups = [];
    final now = DateTime.now();
    
    double maxValue = 0;
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTransactions = allTransactions.where((t) {
        return t.date.year == month.year && t.date.month == month.month;
      }).toList();
      
      final income = Calculations.calculateIncome(monthTransactions);
      final expenses = Calculations.calculateExpenses(monthTransactions).abs();
      
      // Update max value for chart scaling
      if (income > maxValue) maxValue = income;
      if (expenses > maxValue) maxValue = expenses;
      
      barGroups.add(
        BarChartGroupData(
          x: 5 - i, // 0 to 5 for last 6 months
          barRods: [
            BarChartRodData(
              toY: income,
              color: AppColors.income,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: expenses,
              color: AppColors.expense,
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
    
    // Add some padding to max value for better visualization
    maxValue = maxValue * 1.2;
    
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
                'Доходы vs Расходы',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue,
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
                              text: '${Formatters.formatShortCurrency(rod.toY)}',
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
                              _getShortMonthName(month.month),
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
                              '${Formatters.formatShortCurrency(value)}',
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
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: AppColors.income,
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
                        color: AppColors.expense,
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
  
  Widget _buildTopSpendingList(
    List<MapEntry<String, double>> topCategories,
    List<Category> allCategories,
    Map<String, double> expensesByCategory,
  ) {
    if (topCategories.isEmpty) {
      return const SizedBox();
    }

    // Calculate total expenses for percentage calculation
    final totalExpenses = expensesByCategory.values.fold(0.0, (sum, value) => sum + value);
    
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
                    _buildSpendingItem(
                      topCategories[i],
                      allCategories,
                      totalExpenses,
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

  Widget _buildSpendingItem(
    MapEntry<String, double> categoryEntry,
    List<Category> allCategories,
    double totalExpenses,
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
    
    final categoryName = CategoryUtils.getCategoryInfo(category.name).name;
    final percentage = totalExpenses > 0 ? (categoryEntry.value / totalExpenses) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(category.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text('${Formatters.formatCurrency(categoryEntry.value)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(category.color)),
                    backgroundColor: Colors.grey[300]!,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
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
  
  String _getShortMonthName(int month) {
    const months = [
      'Янв',
      'Фев',
      'Мар',
      'Апр',
      'Май',
      'Июн',
      'Июл',
      'Авг',
      'Сен',
      'Окт',
      'Ноя',
      'Дек',
    ];
    return months[month - 1];
  }
}