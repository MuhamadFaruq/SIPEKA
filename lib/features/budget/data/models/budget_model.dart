import 'package:flutter/material.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  BudgetModel({
    required super.id,
    required super.category,
    required super.iconCode,
    required super.limit,
    super.usedAmount = 0.0,
  });

  // --- DATABASE MAPPING ---
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['limit_amount'] as num).toDouble(),
      iconCode: map['icon_code'] as int? ?? Icons.category.codePoint,
      usedAmount: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'limit_amount': limit,
      'icon_code': iconCode,
    };
  }

  // --- JSON/CLOUD MAPPING ---
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      iconCode: json['iconCode'] as int? ?? Icons.category.codePoint,
      limit: (json['limit'] as num).toDouble(),
      usedAmount: (json['usedAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'iconCode': iconCode,
      'limit': limit,
      'usedAmount': usedAmount,
    };
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      category: entity.category,
      iconCode: entity.iconCode,
      limit: entity.limit,
      usedAmount: entity.usedAmount,
    );
  }
}
