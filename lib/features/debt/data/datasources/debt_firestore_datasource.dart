import 'package:flutter/foundation.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import '../models/debt_model.dart';

abstract class DebtDataSource {
  Future<List<DebtModel>> getDebts();
  Future<void> insertDebt(DebtModel debt);
  Future<void> updateDebt(String id, String name, double amount, String notes);
  Future<void> deleteDebt(String id);
  Future<void> markAsPaid(String id, DateTime paidDate);
  Future<void> clearDebts();
}

class DebtFirestoreDataSource implements DebtDataSource {
  final FirestoreService _firestoreService;

  DebtFirestoreDataSource([FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService.instance;

  @override
  Future<List<DebtModel>> getDebts() async {
    final snapshot = await _firestoreService
        .userCollection('debts')
        .orderBy('date', descending: true)
        .get();
    debugPrint("FIRESTORE: getDebts => ${snapshot.docs.length} docs");
    return snapshot.docs.map((doc) {
      return DebtModel.fromJson({'id': doc.id, ...doc.data()});
    }).toList();
  }

  @override
  Future<void> insertDebt(DebtModel debt) async {
    await _firestoreService
        .userCollection('debts')
        .doc(debt.id)
        .set(debt.toJson());
    debugPrint("FIRESTORE: insertDebt OK, id=${debt.id}");
  }

  @override
  Future<void> updateDebt(String id, String name, double amount, String notes) async {
    await _firestoreService.userCollection('debts').doc(id).update({
      'name': name,
      'amount': amount,
      'notes': notes,
    });
    debugPrint("FIRESTORE: updateDebt OK, id=$id");
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _firestoreService.userCollection('debts').doc(id).delete();
    debugPrint("FIRESTORE: deleteDebt OK, id=$id");
  }

  @override
  Future<void> markAsPaid(String id, DateTime paidDate) async {
    await _firestoreService.userCollection('debts').doc(id).update({
      'isPaid': true,
      'paidDate': paidDate.toIso8601String(),
    });
    debugPrint("FIRESTORE: markAsPaid OK, id=$id");
  }

  @override
  Future<void> clearDebts() async {
    final snapshot = await _firestoreService.userCollection('debts').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint("FIRESTORE: clearDebts OK");
  }
}
