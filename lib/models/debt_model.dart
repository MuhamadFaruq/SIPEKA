/// Model Hutang/Piutang — Sumber Kebenaran Tunggal (Single Source of Truth)
/// Field 'name' merujuk pada nama orang yang berhutang/berpiutang.
class Debt {
  final String id;
  final String name; // Nama pihak yang terlibat
  final double amount;
  final DateTime date;
  final String type; // 'Borrowed' (Saya hutang) atau 'Lent' (Orang lain hutang ke saya)
  bool isPaid;
  DateTime? paidDate;
  final String? notes;

  Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    this.isPaid = false,
    this.paidDate,
    this.notes,
  });

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

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      isPaid: json['isPaid'] as bool? ?? false,
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      notes: json['notes'] as String?,
    );
  }

  Debt copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? date,
    String? type,
    bool? isPaid,
    DateTime? paidDate,
    String? notes,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
    );
  }
}