import 'package:flutter/material.dart';
import 'package:finlife/models/transaction.dart';
import 'package:finlife/utils/category_utils.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(String)? onDelete;
  final Function(Transaction)? onTap;

  const TransactionList({
    super.key,
    required this.transactions,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'Нет транзакций',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(context, transaction);
      },
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final categoryInfo = CategoryUtils.getCategoryInfo(transaction.categoryId);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: categoryInfo.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              categoryInfo.emoji,
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
          ),
        ),
        title: Text(
          categoryInfo.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '${transaction.date.day}.${transaction.date.month}.${transaction.date.year}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ₽',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
        onTap: () => onTap?.call(transaction),
      ),
    );
  }
}