import 'transaction_type.dart';

class TransactionEntity {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String wallet;
  final String source;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.wallet,
    this.source = 'Manual',
  });
}

typedef Transaction = TransactionEntity;
