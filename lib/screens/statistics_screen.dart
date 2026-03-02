import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/utils/calculations.dart';
import 'package:finlife/utils/formatters.dart';
import 'package:finlife/constants/app_colors.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  static const _categoryNames = {
    'food': 'Еда',
    'transport': 'Транспорт',
    'health': 'Здоровье',
    'entertainment': 'Развлечения',
    'clothing': 'Одежда',
    'salary': 'Зарплата',
    'investments': 'Инвестиции',
    'gifts': 'Подарки',
    'cafe': 'Кафе',
    'freelance': 'Фриланс',
    'other': 'Другое',
  };

  static const _categoryEmojis = {
    'food': '🍔',
    'transport': '🚗',
    'health': '💊',
    'entertainment': '🎬',
    'clothing': '👗',
    'salary': '💰',
    'investments': '📈',
    'gifts': '🎁',
    'cafe': '☕',
    'freelance': '💻',
    'other': '📦',
  };

  static const _categoryColors = [
    Color(0xFF7B61FF),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFF009688),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF9C27B0),
  ];

  String _getCategoryName(String id) => _categoryNames[id] ?? id;
  String _getCategoryEmoji(String id) => _categoryEmojis[id] ?? '📦';

  Color _getCategoryColor(int index) => _categoryColors[index % _categoryColors.length];

  List<Transaction> _getTransactionsForMonth(List<Transaction> transactions) {
    return transactions.where((t) =>
        t.date.year == _selectedMonth.year &&
        t.date.month == _selectedMonth.month).toList();
  }

  String _getShortMonthName(int month) {
    const months = ['Янв','Фев','Мар','Апр','Май','Июн','Июл','Авг','Сен','Окт','Ноя','Дек'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    if (transactionState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allTransactions = transactionState.transactions;
    final monthTransactions = _getTransactionsForMonth(allTransactions);
    final expenseTransactions = monthTransactions.where((t) => t.type == TransactionType.expense).toList();

    final totalIncome = Calculations.calculateIncome(monthTransactions);
    final totalExpenses = Calculations.calculateExpenses(monthTransactions).abs();
    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (balance / totalIncome) : 0.0;

    // Expenses by category using categoryId directly
    final expensesByCategory = <String, double>{};
    for (var t in expenseTransactions) {
      expensesByCategory[t.categoryId] = (expensesByCategory[t.categoryId] ?? 0) + t.amount.abs();
    }
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildMonthSelector(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(totalIncome, totalExpenses, balance),
            const SizedBox(height: 16),
            _buildSavingsRateCard(savingsRate, balance, totalIncome),
            const SizedBox(height: 16),
            _buildPieChartSection(sortedCategories, totalExpenses),
            const SizedBox(height: 16),
            _buildBarChartSection(allTransactions),
            const SizedBox(height: 16),
            _buildTopSpendingList(sortedCategories, totalExpenses),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: () => setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            }),
          ),
          Text(
            '${_getShortMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () => setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expenses, double balance) {
    return Row(
      children: [
        _buildSummaryCard('Доходы', income, const Color(0xFF4CAF50), Icons.arrow_upward),
        const SizedBox(width: 8),
        _buildSummaryCard('Расходы', expenses, const Color(0xFFF44336), Icons.arrow_downward),
        const SizedBox(width: 8),
        _buildSummaryCard('Баланс', balance, balance >= 0 ? const Color(0xFF7B61FF) : const Color(0xFFF44336), Icons.account_balance_wallet),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.formatCurrency(amount.abs()),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRateCard(double savingsRate, double balance, double income) {
    final pct = (savingsRate * 100).clamp(-100.0, 100.0);
    Color color;
    String message;
    if (pct >= 20) {
      color = const Color(0xFF4CAF50);
      message = 'Отлично! Вы молодец 🎉';
    } else if (pct >= 10) {
      color = Colors.orange;
      message = 'Неплохо, можно лучше 💪';
    } else if (pct >= 0) {
      color = Colors.red;
      message = 'Стоит сократить расходы 📉';
    } else {
      color = Colors.red;
      message = 'Расходы превышают доходы ⚠️';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Норма сбережений',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Сохранено: ${Formatters.formatCurrency(balance.abs())} ₽',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(List<MapEntry<String, double>> sortedCategories, double totalExpenses) {
    if (sortedCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Нет расходов за этот месяц')),
      );
    }

    final sections = <PieChartSectionData>[];
    final top5 = sortedCategories.take(5).toList();

    for (int i = 0; i < top5.length; i++) {
      final entry = top5[i];
      final pct = totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0.0;
      sections.add(PieChartSectionData(
        color: _getCategoryColor(i),
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Расходы по категориям',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 45,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < top5.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: _getCategoryColor(i), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(_getCategoryEmoji(top5[i].key), style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(_getCategoryName(top5[i].key),
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          '${(totalExpenses > 0 ? top5[i].value / totalExpenses * 100 : 0).toStringAsFixed(0)}% · ${Formatters.formatCurrency(top5[i].value)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final barGroups = <BarChartGroupData>[];
    double maxValue = 0;

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTxns = allTransactions.where((t) =>
          t.date.year == month.year && t.date.month == month.month).toList();
      final income = Calculations.calculateIncome(monthTxns);
      final expenses = Calculations.calculateExpenses(monthTxns).abs();
      if (income > maxValue) maxValue = income;
      if (expenses > maxValue) maxValue = expenses;
      barGroups.add(BarChartGroupData(
        x: 5 - i,
        barRods: [
          BarChartRodData(toY: income, color: const Color(0xFF4CAF50), width: 10,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
          BarChartRodData(toY: expenses, color: const Color(0xFFF44336), width: 10,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
        ],
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Доходы vs Расходы (6 мес.)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2 == 0 ? 1000 : maxValue * 1.2,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final month = DateTime(now.year, now.month - (5 - value.toInt()), 1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_getShortMonthName(month.month),
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      );
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      final formatted = value >= 1000
                          ? '${(value / 1000).toStringAsFixed(0)}К'
                          : value.toStringAsFixed(0);
                      return Text(formatted, style: const TextStyle(fontSize: 9, color: Colors.grey));
                    },
                  )),
                ),
              )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot('Доходы', const Color(0xFF4CAF50)),
                const SizedBox(width: 20),
                _buildLegendDot('Расходы', const Color(0xFFF44336)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTopSpendingList(List<MapEntry<String, double>> sortedCategories, double totalExpenses) {
    if (sortedCategories.isEmpty) return const SizedBox();
    final top5 = sortedCategories.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Топ расходов', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < top5.length; i++) ...[
                  Row(
                    children: [
                      Text(_getCategoryEmoji(top5[i].key), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_getCategoryName(top5[i].key),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(Formatters.formatCurrency(top5[i].value),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalExpenses > 0 ? top5[i].value / totalExpenses : 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(i)),
                                minHeight: 6,
                              ),
                            ),
                            Text(
                              '${(totalExpenses > 0 ? top5[i].value / totalExpenses * 100 : 0).toStringAsFixed(0)}% от расходов',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < top5.length - 1) const Divider(height: 20),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}