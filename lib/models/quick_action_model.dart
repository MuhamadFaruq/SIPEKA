import 'package:flutter/material.dart';

class QuickAction {
  final String id;
  final String label;
  final String category;
  final double amount;
  final IconData icon;

  QuickAction({required this.id, required this.label, required this.category, required this.amount, required this.icon});

  // Tambahkan ini untuk konversi ke Map (agar bisa jadi JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'category': category,
      'amount': amount,
      'iconCode': icon.codePoint, // Simpan kode iconnya saja
    };
  }

  // Tambahkan ini untuk konversi dari Map
  factory QuickAction.fromMap(Map<String, dynamic> map) {
    return QuickAction(
      id: map['id'],
      label: map['label'],
      category: map['category'],
      amount: map['amount'],
      icon: IconData(map['iconCode'], fontFamily: 'MaterialIcons'),
    );
  }
}