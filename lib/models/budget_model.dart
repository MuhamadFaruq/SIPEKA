import 'package:flutter/material.dart';

/// Model Anggaran — Sumber Kebenaran Tunggal (Single Source of Truth)
class Budget {
  final String id;
  final String category;
  final int iconCode;
  double limit;
  double usedAmount;

  Budget({
    required this.id,
    required this.category,
    required this.iconCode,
    required this.limit,
    this.usedAmount = 0.0,
  });

  /// Persentase penggunaan anggaran (0.0 sampai 1.0)
  double get percentage => (usedAmount / limit).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'iconCode': iconCode,
      'limit': limit,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      iconCode: json['iconCode'] as int? ?? Icons.category.codePoint,
      limit: (json['limit'] as num).toDouble(),
    );
  }

  Budget copyWith({
    String? id,
    String? category,
    int? iconCode,
    double? limit,
    double? usedAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      iconCode: iconCode ?? this.iconCode,
      limit: limit ?? this.limit,
      usedAmount: usedAmount ?? this.usedAmount,
    );
  }
}