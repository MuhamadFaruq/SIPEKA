import 'package:flutter/material.dart';

class QuickActionEntity {
  final String id;
  final String label;
  final String category;
  final double amount;
  final IconData icon;

  QuickActionEntity({
    required this.id,
    required this.label,
    required this.category,
    required this.amount,
    required this.icon,
  });
}

typedef QuickAction = QuickActionEntity;
