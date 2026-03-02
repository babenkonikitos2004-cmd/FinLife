import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/goal_provider.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/utils/formatters.dart';

class AIAdviceScreen extends ConsumerStatefulWidget {
  const AIAdviceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIAdviceScreen> createState() => _AIAdviceScreenState();
}

class _AIAdviceScreenState extends ConsumerState<AIAdviceScreen> {
  List<Map<String, String>> _aiAdvice = [];
  bool _isLoadingAi = false;
  String? _aiError;
  String? _lastSavedDate;

  @override
  void initState() {
    super.initState();
    _loadSavedAdvice();
  }

  Future<void> _loadSavedAdvice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('ai_advice_cache');
      final savedDate = prefs.getString('ai_advice_date');
      if (saved != null) {
        final list = (jsonDecode(saved) as List).map((a) => {
          'title': a['title'].toString(),
          'text': a['text'].toString(),
          'type': a['type'].toString(),
        }).toList();
        setState(() {
          _aiAdvice = list;
          _lastSavedDate = savedDate;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveAdvice(List<Map<String, String>> advice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_advice_cache', jsonEncode(advice));
    final now = DateTime.now();
    final dateStr = '${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await prefs.setString('ai_advice_date', dateStr);
    setState(() => _lastSavedDate = dateStr);
  }

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
    'other': 'Другое',
  };

  String _translateCategory(String id) => _categoryNames[id] ?? id;

  Future<void> _getAiAdvice({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categorySpending,
    required double savingsRate,
    required List<String> goals,
  }) async {
    setState(() {
      _isLoadingAi = true;
      _aiError = null;
      _aiAdvice = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('groq_api_key') ?? '';

      if (apiKey.isEmpty) {
        setState(() {
          _aiError = 'API ключ не указан.\nПерейдите в Профиль → ИИ-советник и добавьте ключ Groq.\n\nПолучить бесплатно: console.groq.com';
          _isLoadingAi = false;
        });
        return;
      }

      final categoryText = categorySpending.entries
          .map((e) => '${_translateCategory(e.key)}: ${e.value.abs().toStringAsFixed(0)}₽')
          .join(', ');

      final prompt = '''
Проанализируй финансы и дай ровно 3 совета на русском языке.

Данные за месяц:
- Доходы: ${totalIncome.toStringAsFixed(0)} ₽
- Расходы: ${totalExpenses.abs().toStringAsFixed(0)} ₽
- Сбережения: ${savingsRate.toStringAsFixed(1)}%
- По категориям: $categoryText
- Цели: ${goals.isEmpty ? 'не указаны' : goals.join(', ')}

Правила: каждый совет максимум 2 предложения, используй конкретные цифры.

Ответ ТОЛЬКО в JSON без markdown:
{"advice": [{"title": "...", "text": "...", "type": "warning"}, {"title": "...", "text": "...", "type": "tip"}, {"title": "...", "text": "...", "type": "positive"}]}
Типы только: warning, tip, positive''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'max_tokens': 600,
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content': 'Ты финансовый советник. Отвечай только на русском языке. Отвечай только валидным JSON без markdown и без пояснений.'
            },
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        final cleanJson = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final parsed = jsonDecode(cleanJson);
        final adviceList = parsed['advice'] as List;
        final newAdvice = adviceList.map((a) => {
          'title': a['title'].toString(),
          'text': a['text'].toString(),
          'type': a['type'].toString(),
        }).toList();
        await _saveAdvice(newAdvice);
        setState(() {
          _aiAdvice = newAdvice;
          _isLoadingAi = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _aiError = 'Неверный API ключ. Проверьте ключ в Профиле.';
          _isLoadingAi = false;
        });
      } else {
        setState(() {
          _aiError = 'Ошибка API: ${response.statusCode}. Попробуйте позже.';
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiError = 'Ошибка подключения. Проверьте интернет.';
        _isLoadingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final goalState = ref.watch(goalProvider);

    if (transactionState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final transactions = transactionState.transactions;
    final currentDate = DateTime.now();
    final currentMonthStart = DateTime(currentDate.year, currentDate.month, 1);
    final lastMonthStart = DateTime(currentDate.year, currentDate.month - 1, 1);
    final daysUntilEndOfMonth = DateTime(currentDate.year, currentDate.month + 1, 1)
        .difference(currentDate).inDays;

    final currentMonthExpenses = transactions
        .where((t) => t.type == TransactionType.expense &&
            t.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
            t.date.isBefore(DateTime(currentDate.year, currentDate.month + 1, 1)))
        .fold(0.0, (sum, t) => sum + t.amount);

    final currentMonthIncome = transactions
        .where((t) => t.type == TransactionType.income &&
            t.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
            t.date.isBefore(DateTime(currentDate.year, currentDate.month + 1, 1)))
        .fold(0.0, (sum, t) => sum + t.amount);

    final remainingBudget = currentMonthIncome + currentMonthExpenses;

    final currentMonthExpensesByCategory = <String, double>{};
    for (var t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(DateTime(currentDate.year, currentDate.month + 1, 1))) {
        currentMonthExpensesByCategory[t.categoryId] =
            (currentMonthExpensesByCategory[t.categoryId] ?? 0) + t.amount;
      }
    }

    final lastMonthExpensesByCategory = <String, double>{};
    for (var t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(DateTime(lastMonthStart.year, lastMonthStart.month + 1, 1))) {
        lastMonthExpensesByCategory[t.categoryId] =
            (lastMonthExpensesByCategory[t.categoryId] ?? 0) + t.amount;
      }
    }

    String? highestGrowthCategory;
    double highestGrowthPercentage = 0;
    double highestGrowthAmount = 0;
    currentMonthExpensesByCategory.forEach((categoryId, currentAmount) {
      final lastAmount = lastMonthExpensesByCategory[categoryId] ?? 0;
      if (lastAmount < 0 && currentAmount < 0) {
        final growth = (currentAmount.abs() - lastAmount.abs()) / lastAmount.abs();
        if (growth > highestGrowthPercentage) {
          highestGrowthPercentage = growth;
          highestGrowthCategory = categoryId;
          highestGrowthAmount = currentAmount.abs() - lastAmount.abs();
        }
      }
    });

    final highSpendingCategories = <String>[];
    final totalCurrentMonthExpenses = currentMonthExpenses.abs();
    currentMonthExpensesByCategory.forEach((categoryId, amount) {
      if (amount < 0 && totalCurrentMonthExpenses > 0) {
        if (amount.abs() / totalCurrentMonthExpenses > 0.3) {
          highSpendingCategories.add(categoryId);
        }
      }
    });

    final daysPassed = currentDate.day;
    final dailySpendingRate = currentMonthExpenses.abs() / daysPassed;
    final projectedMonthlySpending = dailySpendingRate *
        DateTime(currentDate.year, currentDate.month + 1, 0).day;

    final savingsRate = currentMonthIncome > 0
        ? ((currentMonthIncome - currentMonthExpenses.abs()) / currentMonthIncome * 100)
        : 0.0;

    final activeGoals = goalState.goals
        .where((goal) => goal.currentAmount < goal.targetAmount).toList();

    double dailySavingsNeeded = 0;
    String? targetGoalTitle;
    if (activeGoals.isNotEmpty) {
      activeGoals.sort((a, b) => a.targetDate.compareTo(b.targetDate));
      final nearestGoal = activeGoals.first;
      targetGoalTitle = nearestGoal.title;
      final remainingAmount = nearestGoal.targetAmount - nearestGoal.currentAmount;
      final daysToGoal = nearestGoal.targetDate.difference(currentDate).inDays;
      if (daysToGoal > 0) dailySavingsNeeded = remainingAmount / daysToGoal;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7B61FF), Color(0xFF4A90E2)],
                  ),
                ),
                child: const SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('ИИ-Советы',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Персональный финансовый анализ',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Groq кнопка
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFF4A90E2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Получить персональный совет от ИИ',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        const Text('Groq AI анализирует ваши расходы бесплатно',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingAi ? null : () => _getAiAdvice(
                              totalIncome: currentMonthIncome,
                              totalExpenses: currentMonthExpenses,
                              categorySpending: currentMonthExpensesByCategory,
                              savingsRate: savingsRate,
                              goals: activeGoals.map((g) => g.title).toList(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoadingAi
                                ? const SizedBox(height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    _aiAdvice.isEmpty ? '✨ Спросить ИИ' : '🔄 Обновить советы',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_aiError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('❌', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_aiError!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14))),
                        ],
                      ),
                    ),
                  ],

                  if (_aiAdvice.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('💬 Советы от ИИ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_lastSavedDate != null)
                          Text(_lastSavedDate!,
                              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Groq AI',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._aiAdvice.map((advice) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAiAdviceCard(advice),
                    )),
                  ],

                  const SizedBox(height: 24),
                  const Text('📊 Автоматический анализ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (highestGrowthCategory != null) ...[
                    _buildAdviceCard(
                      emoji: '🔴', title: 'Перерасход',
                      content: 'Вы потратили на ${Formatters.formatCurrency(highestGrowthAmount)} больше на ${_translateCategory(highestGrowthCategory!)} по сравнению с прошлым месяцем.',
                      amount: Formatters.formatCurrency(highestGrowthAmount), color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (highSpendingCategories.isNotEmpty) ...[
                    _buildAdviceCard(
                      emoji: '💡', title: 'Совет по экономии',
                      content: 'Слишком много тратите на ${highSpendingCategories.map(_translateCategory).join(', ')}. Попробуйте сократить на 15%.',
                      amount: 'Сэкономьте до ${Formatters.formatCurrency((currentMonthExpensesByCategory[highSpendingCategories.first] ?? 0).abs() * 0.15)}',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildAdviceCard(
                    emoji: '📈', title: 'Прогноз',
                    content: 'При текущем темпе вы потратите ${Formatters.formatCurrency(projectedMonthlySpending)} за месяц.',
                    amount: Formatters.formatCurrency(projectedMonthlySpending),
                    color: projectedMonthlySpending > currentMonthIncome ? Colors.red : Colors.blue,
                  ),

                  if (activeGoals.isNotEmpty && dailySavingsNeeded > 0) ...[
                    const SizedBox(height: 12),
                    _buildAdviceCard(
                      emoji: '🎯', title: 'До цели',
                      content: 'Чтобы достичь "$targetGoalTitle", откладывайте ${Formatters.formatCurrency(dailySavingsNeeded)} ежедневно.',
                      amount: '${Formatters.formatCurrency(dailySavingsNeeded)}/день',
                      color: Colors.purple,
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Финансовый обзор',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildOverviewRow(icon: '📅', title: 'Дней до конца месяца', value: '$daysUntilEndOfMonth', isPositive: true),
                        const Divider(height: 24),
                        _buildOverviewRow(icon: '💰', title: 'Остаток бюджета', value: Formatters.formatCurrency(remainingBudget), isPositive: remainingBudget >= 0),
                        const Divider(height: 24),
                        _buildOverviewRow(icon: '📊', title: 'Прогноз расходов', value: Formatters.formatCurrency(projectedMonthlySpending), isPositive: projectedMonthlySpending <= currentMonthIncome),
                        const Divider(height: 24),
                        _buildOverviewRow(icon: '💹', title: 'Сбережения', value: '${savingsRate.toStringAsFixed(1)}%', isPositive: savingsRate >= 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdviceCard(Map<String, String> advice) {
    Color color;
    String emoji;
    switch (advice['type']) {
      case 'warning': color = Colors.red; emoji = '⚠️'; break;
      case 'positive': color = Colors.green; emoji = '✅'; break;
      default: color = Colors.orange; emoji = '💡';
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(advice['text'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard({required String emoji, required String title, required String content, required String amount, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow({required String icon, required String title, required String value, required bool isPositive}) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black54))),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isPositive ? Colors.green : Colors.red)),
      ],
    );
  }
}