import 'package:flutter/material.dart';

class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final String category;
  final double amount;

  QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    required this.amount,
  });
}