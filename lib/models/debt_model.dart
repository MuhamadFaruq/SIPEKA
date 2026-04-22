class Debt {
  String id;
  String name;
  double amount;
  DateTime date;
  String type; // 'Borrowed' (Hutang saya) atau 'Lent' (Piutang saya)
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
}