class Wishlist {
  final String id;
  final String name;
  final String icon; // Icon identifier
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate; // Optional target date
  final String? notes;

  Wishlist({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.targetDate,
    this.notes,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from Map
  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  // Create a copy with updated fields
  Wishlist copyWith({
    String? id,
    String? name,
    String? icon,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    String? notes,
  }) {
    return Wishlist(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
    );
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (savedAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  // Calculate remaining amount
  double get remainingAmount {
    return (targetAmount - savedAmount).clamp(0.0, double.infinity);
  }

  // Check if target is reached
  bool get isCompleted {
    return savedAmount >= targetAmount;
  }
}

