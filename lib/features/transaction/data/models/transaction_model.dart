import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.type,
    required super.category,
    required super.wallet,
    super.source = 'Manual',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.dbValue,
      'category': category,
      'wallet': wallet,
      'source': source,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      type: TransactionType.fromString(map['type']),
      category: map['category'] ?? '',
      wallet: map['wallet'] ?? '',
      source: map['source'] ?? 'Manual',
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      type: entity.type,
      category: entity.category,
      wallet: entity.wallet,
      source: entity.source,
    );
  }
}
