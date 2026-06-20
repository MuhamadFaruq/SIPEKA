import '../../domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.category,
    required super.wallet,
    required super.frequency,
    required super.startDate,
    super.lastExecutedDate,
    required super.nextExecutionDate,
    super.isActive = true,
    super.remindMe = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'wallet': wallet,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'last_executed_date': lastExecutedDate?.toIso8601String(),
      'next_execution_date': nextExecutionDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'remind_me': remindMe ? 1 : 0,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'Expense',
      category: map['category'] ?? '',
      wallet: map['wallet'] ?? '',
      frequency: map['frequency'] ?? 'monthly',
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : DateTime.now(),
      lastExecutedDate: map['last_executed_date'] != null ? DateTime.parse(map['last_executed_date']) : null,
      nextExecutionDate: map['next_execution_date'] != null ? DateTime.parse(map['next_execution_date']) : DateTime.now(),
      isActive: (map['is_active'] ?? 1) == 1,
      remindMe: (map['remind_me'] ?? 1) == 1,
    );
  }

  factory BillModel.fromEntity(BillEntity entity) {
    return BillModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      type: entity.type,
      category: entity.category,
      wallet: entity.wallet,
      frequency: entity.frequency,
      startDate: entity.startDate,
      lastExecutedDate: entity.lastExecutedDate,
      nextExecutionDate: entity.nextExecutionDate,
      isActive: entity.isActive,
      remindMe: entity.remindMe,
    );
  }
}
