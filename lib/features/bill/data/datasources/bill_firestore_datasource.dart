import 'package:flutter/foundation.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import '../models/bill_model.dart';

abstract class BillDataSource {
  Future<List<BillModel>> getBills();
  Future<bool> insertBill(BillModel bill);
  Future<bool> updateBill(BillModel bill);
  Future<bool> deleteBill(String id);
  Future<void> clearBills();
}

class BillFirestoreDataSource implements BillDataSource {
  final FirestoreService _firestoreService;

  BillFirestoreDataSource([FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService.instance;

  @override
  Future<List<BillModel>> getBills() async {
    final snapshot = await _firestoreService.userCollection('bills').get();
    debugPrint("FIRESTORE: getBills => ${snapshot.docs.length} docs");
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BillModel(
        id: doc.id,
        title: data['title'] ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: data['type'] ?? 'Expense',
        category: data['category'] ?? '',
        wallet: data['wallet'] ?? '',
        frequency: data['frequency'] ?? 'monthly',
        startDate: data['start_date'] != null
            ? DateTime.tryParse(data['start_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        lastExecutedDate: data['last_executed_date'] != null
            ? DateTime.tryParse(data['last_executed_date'].toString())
            : null,
        nextExecutionDate: data['next_execution_date'] != null
            ? DateTime.tryParse(data['next_execution_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isActive: data['is_active'] == true || data['is_active'] == 1,
        remindMe: data['remind_me'] == true || data['remind_me'] == 1,
      );
    }).toList();
  }

  @override
  Future<bool> insertBill(BillModel bill) async {
    try {
      await _firestoreService.userCollection('bills').doc(bill.id).set({
        'title': bill.title,
        'amount': bill.amount,
        'type': bill.type,
        'category': bill.category,
        'wallet': bill.wallet,
        'frequency': bill.frequency,
        'start_date': bill.startDate.toIso8601String(),
        'last_executed_date': bill.lastExecutedDate?.toIso8601String(),
        'next_execution_date': bill.nextExecutionDate.toIso8601String(),
        'is_active': bill.isActive,
        'remind_me': bill.remindMe,
      });
      debugPrint("FIRESTORE: insertBill OK, id=${bill.id}");
      return true;
    } catch (e) {
      debugPrint("FIRESTORE: insertBill ERROR: $e");
      return false;
    }
  }

  @override
  Future<bool> updateBill(BillModel bill) async {
    try {
      await _firestoreService.userCollection('bills').doc(bill.id).update({
        'title': bill.title,
        'amount': bill.amount,
        'type': bill.type,
        'category': bill.category,
        'wallet': bill.wallet,
        'frequency': bill.frequency,
        'start_date': bill.startDate.toIso8601String(),
        'last_executed_date': bill.lastExecutedDate?.toIso8601String(),
        'next_execution_date': bill.nextExecutionDate.toIso8601String(),
        'is_active': bill.isActive,
        'remind_me': bill.remindMe,
      });
      debugPrint("FIRESTORE: updateBill OK, id=${bill.id}");
      return true;
    } catch (e) {
      debugPrint("FIRESTORE: updateBill ERROR: $e");
      return false;
    }
  }

  @override
  Future<bool> deleteBill(String id) async {
    try {
      await _firestoreService.userCollection('bills').doc(id).delete();
      debugPrint("FIRESTORE: deleteBill OK, id=$id");
      return true;
    } catch (e) {
      debugPrint("FIRESTORE: deleteBill ERROR: $e");
      return false;
    }
  }

  @override
  Future<void> clearBills() async {
    final snapshot = await _firestoreService.userCollection('bills').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint("FIRESTORE: clearBills OK");
  }
}
