import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/transaction.dart' as model;
import 'package:finlife/models/category.dart';
import 'package:finlife/widgets/transaction_list.dart';
import 'package:finlife/widgets/banner_widget.dart';
import 'package:finlife/providers/transaction_provider.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  late List<model.Transaction> transactions;
  late List<Category> categories;
  model.TransactionType selectedType = model.TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadCategories();
  }

  void _loadTransactions() {
    // Mock data for demonstration
    transactions = [
      model.Transaction(
        id: '1',
        title: 'Покупка продуктов',
        amount: 1200.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: model.TransactionType.expense,
        categoryId: '1',
      ),
      model.Transaction(
        id: '2',
        title: 'Зарплата',
        amount: 50000.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: model.TransactionType.income,
        categoryId: '2',
      ),
      model.Transaction(
        id: '3',
        title: 'Кофе',
        amount: 150.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: model.TransactionType.expense,
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
    bool isRecurring = false;
    bool isCategoryInvalid = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить транзакцию'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<model.TransactionType>(
                      value: selectedType,
                      items: model.TransactionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == model.TransactionType.income ? 'Доход' : 'Расход',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value as model.TransactionType;
                          // Reset category when type changes
                          selectedCategory = null;
                          isCategoryInvalid = false;
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
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCategoryInvalid ? Colors.red : Colors.grey,
                          width: isCategoryInvalid ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: DropdownButton<Category>(
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
                            isCategoryInvalid = false;
                          });
                        },
                        dropdownColor: isCategoryInvalid ? Colors.red[50] : null,
                        isExpanded: true,
                        underline: Container(),
                      ),
                    ),
                    if (isCategoryInvalid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Выберите категорию',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: isRecurring,
                          onChanged: (value) {
                            setState(() {
                              isRecurring = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Постоянная транзакция 🔄'),
                              Text(
                                'Будет повторяться каждый месяц',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                  onPressed: () async {
                    // Validate category
                    if (selectedCategory == null) {
                      setState(() {
                        isCategoryInvalid = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Выберите категорию')),
                      );
                      return;
                    }
                    
                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Введите сумму')),
                      );
                      return;
                    }
                    
                    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Введите корректную сумму')),
                      );
                      return;
                    }

                    final transaction = model.Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.isEmpty ? selectedCategory?.name ?? 'Транзакция' : titleController.text,
                      amount: selectedType == model.TransactionType.expense ? -amount : amount,
                      type: selectedType,
                      categoryId: selectedCategory!.id,
                      date: DateTime.now(),
                      isRecurring: isRecurring,
                    );

                    try {
                      await ref.read(transactionProvider.notifier).addTransaction(transaction);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Транзакция добавлена!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeTransactions = transactions
        .where((t) => t.type == model.TransactionType.income)
        .toList();
    final expenseTransactions = transactions
        .where((t) => t.type == model.TransactionType.expense)
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
                  selected: selectedType == model.TransactionType.income ||
                      selectedType == model.TransactionType.expense,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = model.TransactionType.income;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Доходы'),
                  selected: selectedType == model.TransactionType.income,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = selectedType == model.TransactionType.income
                          ? model.TransactionType.expense
                          : model.TransactionType.income;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Расходы'),
                  selected: selectedType == model.TransactionType.expense,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = selectedType == model.TransactionType.expense
                          ? model.TransactionType.income
                          : model.TransactionType.expense;
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
              transactions: selectedType == model.TransactionType.income
                  ? incomeTransactions
                  : selectedType == model.TransactionType.expense
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