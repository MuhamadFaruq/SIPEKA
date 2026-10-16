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
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: (map['type'] ?? 'payable').toString(),
      isPaid: map['is_paid'] == 1 || map['is_paid'] == true || map['isPaid'] == true,
      paidDate: map['paid_date'] != null
          ? DateTime.tryParse(map['paid_date'].toString())
          : (map['paidDate'] != null ? DateTime.tryParse(map['paidDate'].toString()) : null),
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
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: (json['type'] ?? 'payable').toString(),
      isPaid: json['isPaid'] == true || json['is_paid'] == 1 || json['is_paid'] == true,
      paidDate: json['paidDate'] != null
          ? DateTime.tryParse(json['paidDate'].toString())
          : (json['paid_date'] != null ? DateTime.tryParse(json['paid_date'].toString()) : null),
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
