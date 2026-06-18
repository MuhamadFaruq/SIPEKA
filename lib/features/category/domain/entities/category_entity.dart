class CategoryEntity {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon; // Icon identifier (e.g., 'makan', 'bensin', 'gaji')
  final int color; // Color value as int

  CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });
}

typedef Category = CategoryEntity;
