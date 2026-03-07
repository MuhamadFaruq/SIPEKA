class Debt {
  final String id;
  final String name; // Nama orang (misal: Budi Santoso)
  final double amount;
  final DateTime date;
  final String type; // 'Lent' (Piutang/Orang hutang ke kita) atau 'Borrowed' (Hutang/Kita hutang ke orang)

  Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
  });
}