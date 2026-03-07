class Category {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon; // Icon identifier (e.g., 'makan', 'bensin', 'gaji')
  final int color; // Color value as int

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  // Create from Map
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String,
      color: json['color'] as int,
    );
  }

  // Create a copy with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    int? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}

