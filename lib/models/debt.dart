class Debt {
  final String id;
  final String personName;
  final double amount;
  final DateTime date;
  final String type; // 'piutang' (people owe me) or 'hutang' (I owe people)
  final String? notes;
  final bool isPaid;

  Debt({
    required this.id,
    required this.personName,
    required this.amount,
    required this.date,
    required this.type,
    this.notes,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'notes': notes,
      'isPaid': isPaid,
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      personName: json['personName'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      notes: json['notes'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  Debt copyWith({
    String? id,
    String? personName,
    double? amount,
    DateTime? date,
    String? type,
    String? notes,
    bool? isPaid,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

