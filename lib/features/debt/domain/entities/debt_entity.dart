class DebtEntity {
  final String id;
  final String name; 
  final double amount;
  final DateTime date;
  final String type; // 'Borrowed' atau 'Lent'
  bool isPaid;
  DateTime? paidDate;
  final String? notes;

  DebtEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    this.isPaid = false,
    this.paidDate,
    this.notes,
  });
}

typedef Debt = DebtEntity;
