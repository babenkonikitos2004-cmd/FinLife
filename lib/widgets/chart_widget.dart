import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';

class ChartWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final ChartType type;

  const ChartWidget({
    super.key,
    required this.transactions,
    this.type = ChartType.bar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
      child: type == ChartType.bar
          ? _buildBarChart()
          : _buildPieChart(),
    );
  }

  Widget _buildBarChart() {
    // Group transactions by month
    final Map<String, double> monthlyData = {};
    
    for (var transaction in transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month}';
      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = monthlyData[monthKey]! + transaction.amount;
      } else {
        monthlyData[monthKey] = transaction.amount;
      }
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> months = monthlyData.keys.toList();
    
    for (int i = 0; i < months.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlyData[months[i]] ?? 0,
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (monthlyData.values.fold(0.0, (a, b) => a > b ? a : b) * 1.2).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (
              BarChartGroupData group,
              int groupIndex,
              BarChartRodData rod,
              int rodIndex,
            ) {
              return BarTooltipItem(
                '${months[groupIndex]}\n',
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
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < months.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      months[index].split('-')[1],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
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
                    '${value.toInt()}',
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
    );
  }

  Widget _buildPieChart() {
    // Group transactions by category ID
    final Map<String, double> categoryData = {};
    
    for (var transaction in transactions) {
      if (categoryData.containsKey(transaction.categoryId)) {
        categoryData[transaction.categoryId] =
            categoryData[transaction.categoryId]! + transaction.amount;
      } else {
        categoryData[transaction.categoryId] = transaction.amount;
      }
    }

    final List<PieChartSectionData> sections = [];
    final List<String> categoryIds = categoryData.keys.toList();
    final double total = categoryData.values.fold(0, (a, b) => a + b);
    
    for (int i = 0; i < categoryIds.length; i++) {
      final percentage = (categoryData[categoryIds[i]]! / total) * 100;
      sections.add(
        PieChartSectionData(
          color: _getColorForIndex(i),
          value: categoryData[categoryIds[i]],
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

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
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

enum ChartType {
  bar,
  pie,
}