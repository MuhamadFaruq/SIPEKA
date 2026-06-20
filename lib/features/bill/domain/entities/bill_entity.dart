class BillEntity {
  final String id;
  final String title;
  final double amount;
  final String type; // 'Income' / 'Expense'
  final String category;
  final String wallet;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? lastExecutedDate;
  final DateTime nextExecutionDate;
  final bool isActive;
  final bool remindMe;

  const BillEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.wallet,
    required this.frequency,
    required this.startDate,
    this.lastExecutedDate,
    required this.nextExecutionDate,
    this.isActive = true,
    this.remindMe = true,
  });
}
