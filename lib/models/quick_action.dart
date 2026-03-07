class QuickAction {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double amount;
  final String icon; // Icon identifier
  final int order; // Display order

  QuickAction({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.icon,
    this.order = 0,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'icon': icon,
      'order': order,
    };
  }

  // Create from Map
  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      amount: (json['amount'] as num).toDouble(),
      icon: json['icon'] as String,
      order: json['order'] as int? ?? 0,
    );
  }

  // Create a copy with updated fields
  QuickAction copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    double? amount,
    String? icon,
    int? order,
  }) {
    return QuickAction(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      icon: icon ?? this.icon,
      order: order ?? this.order,
    );
  }
}

