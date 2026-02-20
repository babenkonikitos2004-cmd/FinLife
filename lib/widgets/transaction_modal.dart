import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:intl/intl.dart';

class TransactionModal extends ConsumerStatefulWidget {
  final TransactionType? preselectedType;
  
  const TransactionModal({super.key, this.preselectedType});

  @override
  ConsumerState<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends ConsumerState<TransactionModal> {
  late TransactionType _transactionType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isRecurring = false;
  
  // Expense categories
  final List<Category> _expenseCategories = [
    Category(
      id: 'food',
      name: 'Еда',
      type: CategoryType.expense,
      icon: '🍕',
      color: 0xFF4CAF50,
    ),
    Category(
      id: 'transport',
      name: 'Транспорт',
      type: CategoryType.expense,
      icon: '🚗',
      color: 0xFF2196F3,
    ),
    Category(
      id: 'entertainment',
      name: 'Развлечения',
      type: CategoryType.expense,
      icon: '🎮',
      color: 0xFFFFEB3B,
    ),
    Category(
      id: 'health',
      name: 'Здоровье',
      type: CategoryType.expense,
      icon: '💊',
      color: 0xFFF44336,
    ),
    Category(
      id: 'clothing',
      name: 'Одежда',
      type: CategoryType.expense,
      icon: '👕',
      color: 0xFF9C27B0,
    ),
    Category(
      id: 'cafe',
      name: 'Кафе',
      type: CategoryType.expense,
      icon: '☕',
      color: 0xFF795548,
    ),
    Category(
      id: 'other_expense',
      name: 'Другое',
      type: CategoryType.expense,
      icon: '📦',
      color: 0xFF9E9E9E,
    ),
  ];
  
  // Income categories
  final List<Category> _incomeCategories = [
    Category(
      id: 'salary',
      name: 'Зарплата',
      type: CategoryType.income,
      icon: '💼',
      color: 0xFF4CAF50,
    ),
    Category(
      id: 'freelance',
      name: 'Фриланс',
      type: CategoryType.income,
      icon: '💻',
      color: 0xFF2196F3,
    ),
    Category(
      id: 'investments',
      name: 'Инвестиции',
      type: CategoryType.income,
      icon: '📈',
      color: 0xFFFF9800,
    ),
    Category(
      id: 'gift',
      name: 'Подарок',
      type: CategoryType.income,
      icon: '🎁',
      color: 0xFF9C27B0,
    ),
    Category(
      id: 'other_income',
      name: 'Другое',
      type: CategoryType.income,
      icon: '📦',
      color: 0xFF9E9E9E,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.preselectedType ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  Future<void> _selectDate() async {
    // Dismiss keyboard before showing date picker to avoid IME conflicts
    FocusScope.of(context).unfocus();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    // Validate amount > 0
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0;
    
    print('Amount: $amount');
    print('Category: $_selectedCategoryId');
    print('Saving transaction...');
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сумма должна быть больше 0')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию')),
      );
      return;
    }

    final userState = ref.read(userProvider);
    if (userState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не найден')),
      );
      return;
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _noteController.text.isEmpty ? 'Транзакция' : _noteController.text,
      amount: amount,
      date: _selectedDate,
      type: _transactionType,
      categoryId: _selectedCategoryId!,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      isRecurring: _isRecurring,
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    
    // Close modal with Navigator.pop(context)
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Транзакция добавлена!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Добавить транзакцию',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Transaction type toggle (pill shape, smooth color switch)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = TransactionType.income;
                        _selectedCategoryId = null; // Reset category selection when type changes
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _transactionType == TransactionType.income 
                            ? const Color(0xFF4CAF50) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'Доход',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = TransactionType.expense;
                        _selectedCategoryId = null; // Reset category selection when type changes
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _transactionType == TransactionType.expense 
                            ? const Color(0xFFF44336) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'Расход',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Amount field (proper TextFormField with decimal input)
          const Text(
            'Сумма',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) {
              // Format the input to show proper decimal formatting
            },
          ),
          const SizedBox(height: 20),
          
          // Category selector (using Wrap widget with clean rounded chips)
          const Text(
            'Категория',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_transactionType == TransactionType.income 
                      ? _incomeCategories 
                      : _expenseCategories)
                  .map((category) {
                final isSelected = _selectedCategoryId == category.id;
                return GestureDetector(
                  onTap: () => _selectCategory(category.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF7B61FF) // Purple background when selected
                          : Colors.grey[300], // Grey when unselected
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          
          // Note field with Russian placeholder
          const Text(
            'Примечание (необязательно)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Введите описание',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Recurring transaction toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Постоянная транзакция',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                activeColor: const Color(0xFF7B61FF),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Date picker
          const Text(
            'Дата',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate)} 📅',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}