import 'package:flutter/material.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';
import 'package:finlife/widgets/transaction_list.dart';
import 'package:finlife/widgets/banner_widget.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late List<Transaction> transactions;
  late List<Category> categories;
  TransactionType selectedType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadCategories();
  }

  void _loadTransactions() {
    // Mock data for demonstration
    transactions = [
      Transaction(
        id: '1',
        title: 'Покупка продуктов',
        amount: 1200.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        categoryId: '1',
      ),
      Transaction(
        id: '2',
        title: 'Зарплата',
        amount: 50000.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.income,
        categoryId: '2',
      ),
      Transaction(
        id: '3',
        title: 'Кофе',
        amount: 150.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.expense,
        categoryId: '3',
      ),
    ];
  }

  void _loadCategories() {
    // Mock data for demonstration
    categories = [
      Category(
        id: '1',
        name: 'Продукты',
        icon: 'food',
        type: CategoryType.expense,
        color: 0xFFE57373,
      ),
      Category(
        id: '2',
        name: 'Транспорт',
        icon: 'transport',
        type: CategoryType.expense,
        color: 0xFF81C784,
      ),
      Category(
        id: '3',
        name: 'Развлечения',
        icon: 'entertainment',
        type: CategoryType.expense,
        color: 0xFF64B5F6,
      ),
      Category(
        id: '4',
        name: 'Зарплата',
        icon: 'salary',
        type: CategoryType.income,
        color: 0xFFFFD54F,
      ),
    ];
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    Category? selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить транзакцию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton< TransactionType>(
                  value: selectedType,
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type == TransactionType.income ? 'Доход' : 'Расход',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButton<Category>(
                  hint: const Text('Выберите категорию'),
                  value: selectedCategory,
                  items: categories
                      .where((cat) => cat.type == selectedType)
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty &&
                    selectedCategory != null) {
                  // Add transaction logic here
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Транзакция добавлена'),
                    ),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeTransactions = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final totalIncome = incomeTransactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
    final totalExpenses = expenseTransactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
    final balance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text(
                  'Баланс',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${balance.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Доходы',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${totalIncome.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Расходы',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${totalExpenses.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Banner widget
          const BannerWidget(
            height: 150,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          // Transaction type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: selectedType == TransactionType.income ||
                      selectedType == TransactionType.expense,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = TransactionType.income;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Доходы'),
                  selected: selectedType == TransactionType.income,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = selectedType == TransactionType.income
                          ? TransactionType.expense
                          : TransactionType.income;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Расходы'),
                  selected: selectedType == TransactionType.expense,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = selectedType == TransactionType.expense
                          ? TransactionType.income
                          : TransactionType.expense;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Transaction list
          Expanded(
            child: TransactionList(
              transactions: selectedType == TransactionType.income
                  ? incomeTransactions
                  : selectedType == TransactionType.expense
                      ? expenseTransactions
                      : transactions,
              onTap: (transaction) {
                // Handle transaction tap
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}