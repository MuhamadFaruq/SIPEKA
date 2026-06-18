import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  DebtModel({
    required super.id,
    required super.name,
    required super.amount,
    required super.date,
    required super.type,
    super.isPaid = false,
    super.paidDate,
    super.notes,
  });

  // --- DATABASE MAPPING ---
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      isPaid: map['is_paid'] == 1,
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'is_paid': isPaid ? 1 : 0,
      'paid_date': paidDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // --- JSON/CLOUD MAPPING ---
  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      isPaid: json['isPaid'] as bool? ?? false,
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory DebtModel.fromEntity(DebtEntity entity) {
    return DebtModel(
      id: entity.id,
      name: entity.name,
      amount: entity.amount,
      date: entity.date,
      type: entity.type,
      isPaid: entity.isPaid,
      paidDate: entity.paidDate,
      notes: entity.notes,
    );
  }
}
