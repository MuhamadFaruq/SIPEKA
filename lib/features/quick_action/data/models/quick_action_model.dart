import 'package:flutter/material.dart';
import '../../domain/entities/quick_action_entity.dart';

class QuickActionModel extends QuickActionEntity {
  QuickActionModel({
    required super.id,
    required super.label,
    required super.category,
    required super.amount,
    required super.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'category': category,
      'amount': amount,
      'iconCode': icon.codePoint, 
    };
  }

  factory QuickActionModel.fromMap(Map<String, dynamic> map) {
    return QuickActionModel(
      id: map['id'] as String,
      label: map['label'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      icon: IconData(map['iconCode'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  factory QuickActionModel.fromEntity(QuickActionEntity entity) {
    return QuickActionModel(
      id: entity.id,
      label: entity.label,
      category: entity.category,
      amount: entity.amount,
      icon: entity.icon,
    );
  }
}
