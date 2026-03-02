// lib/widgets/transaction_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/models/category.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:intl/intl.dart';

/// Форматтер суммы: "1000000" → "1 000 000"
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '').replaceAll(',', '.');

    // Разрешаем только цифры и одну точку
    if (text.isEmpty) return newValue.copyWith(text: '');
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) return oldValue;

    // Разделяем целую и дробную части
    final parts = text.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Форматируем целую часть с пробелами
    final formatted = _formatIntPart(intPart) + fracPart;

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatIntPart(String s) {
    if (s.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

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

  // Подсказка о размере суммы
  String _amountHint = '';

  final List<Category> _expenseCategories = [
    Category(id: 'food', name: 'Еда', type: CategoryType.expense, icon: '🍕', color: 0xFF4CAF50),
    Category(id: 'transport', name: 'Транспорт', type: CategoryType.expense, icon: '🚗', color: 0xFF2196F3),
    Category(id: 'entertainment', name: 'Развлечения', type: CategoryType.expense, icon: '🎮', color: 0xFFFFEB3B),
    Category(id: 'health', name: 'Здоровье', type: CategoryType.expense, icon: '💊', color: 0xFFF44336),
    Category(id: 'clothing', name: 'Одежда', type: CategoryType.expense, icon: '👕', color: 0xFF9C27B0),
    Category(id: 'cafe', name: 'Кафе', type: CategoryType.expense, icon: '☕', color: 0xFF795548),
    Category(id: 'other_expense', name: 'Другое', type: CategoryType.expense, icon: '📦', color: 0xFF9E9E9E),
  ];

  final List<Category> _incomeCategories = [
    Category(id: 'salary', name: 'Зарплата', type: CategoryType.income, icon: '💼', color: 0xFF4CAF50),
    Category(id: 'freelance', name: 'Фриланс', type: CategoryType.income, icon: '💻', color: 0xFF2196F3),
    Category(id: 'investments', name: 'Инвестиции', type: CategoryType.income, icon: '📈', color: 0xFFFF9800),
    Category(id: 'gift', name: 'Подарок', type: CategoryType.income, icon: '🎁', color: 0xFF9C27B0),
    Category(id: 'other_income', name: 'Другое', type: CategoryType.income, icon: '📦', color: 0xFF9E9E9E),
  ];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.preselectedType ?? TransactionType.expense;
    _amountController.addListener(_updateAmountHint);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmountHint);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateAmountHint() {
    final raw = _amountController.text.replaceAll(' ', '');
    final amount = double.tryParse(raw) ?? 0;
    String hint = '';
    if (amount >= 1000000000) {
      hint = '${(amount / 1000000000).toStringAsFixed(1)} млрд';
    } else if (amount >= 1000000) {
      hint = '${(amount / 1000000).toStringAsFixed(1)} млн';
    } else if (amount >= 1000) {
      hint = '${(amount / 1000).toStringAsFixed(0)} тыс';
    }
    if (hint != _amountHint) setState(() => _amountHint = hint);
  }

  void _saveTransaction() {
    final raw = _amountController.text.replaceAll(' ', '').replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0;

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

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _noteController.text.isEmpty ? 'Транзакция' : _noteController.text,
      amount: _transactionType == TransactionType.expense ? -amount : amount,
      date: _selectedDate,
      type: _transactionType,
      categoryId: _selectedCategoryId!,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      isRecurring: _isRecurring,
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Транзакция добавлена!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16, left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Хедер
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Добавить транзакцию',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Переключатель доход/расход
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildTypeButton('Доход', TransactionType.income, const Color(0xFF4CAF50)),
                _buildTypeButton('Расход', TransactionType.expense, const Color(0xFFF44336)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Поле суммы с форматированием
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_AmountInputFormatter()],
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold, color: Colors.grey),
                    border: InputBorder.none,
                    suffix: Text(' ₽',
                        style: TextStyle(
                            fontSize: 24, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              if (_amountHint.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_amountHint,
                        style: const TextStyle(
                            color: Color(0xFF7B61FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Категории
          const Text('Категория',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_transactionType == TransactionType.income
                    ? _incomeCategories
                    : _expenseCategories)
                .map((cat) {
              final isSelected = _selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(cat.name,
                          style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Примечание
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Примечание (необязательно)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Постоянная транзакция + дата в одну строку
          Row(
            children: [
              const Text('Постоянная', style: TextStyle(fontSize: 14)),
              Switch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeColor: const Color(0xFF7B61FF),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(DateFormat('dd.MM.yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Кнопка сохранить
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Сохранить',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
      String label, TransactionType type, Color activeColor) {
    final isActive = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _transactionType = type;
          _selectedCategoryId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey[600])),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}