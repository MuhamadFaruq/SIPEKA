class Budget {
  final String id;
  final String categoryId;
  final String categoryName;
  final double amount;
  final int month; // 1-12
  final int year;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.month,
    required this.year,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  // Create from Map
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  // Create a copy with updated fields
  Budget copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    double? amount,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  // Check if budget is for current month
  bool isCurrentMonth() {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }
}

