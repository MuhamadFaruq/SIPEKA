class BudgetEntity {
  final String id;
  final String category;
  final int iconCode;
  final double limit;
  double usedAmount;

  BudgetEntity({
    required this.id,
    required this.category,
    required this.iconCode,
    required this.limit,
    this.usedAmount = 0.0,
  });

  double get percentage {
    if (limit == 0) return 0.0;
    return (usedAmount / limit).clamp(0.0, 1.0);
  }
}

typedef Budget = BudgetEntity;

