import 'package:flutter/foundation.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import '../models/budget_model.dart';

abstract class BudgetDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<void> insertBudget(BudgetModel budget);
  Future<void> updateBudget(String id, String category, double limit, int iconCode);
  Future<void> deleteBudget(String id);
  Future<void> clearBudgets();
}

class BudgetFirestoreDataSource implements BudgetDataSource {
  final FirestoreService _firestoreService;

  BudgetFirestoreDataSource([FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService.instance;

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final snapshot = await _firestoreService.userCollection('budgets').get();
    debugPrint("FIRESTORE: getBudgets => ${snapshot.docs.length} docs");
    return snapshot.docs.map((doc) {
      return BudgetModel.fromJson({'id': doc.id, ...doc.data()});
    }).toList();
  }

  @override
  Future<void> insertBudget(BudgetModel budget) async {
    await _firestoreService
        .userCollection('budgets')
        .doc(budget.id)
        .set(budget.toJson());
    debugPrint("FIRESTORE: insertBudget OK, id=${budget.id}");
  }

  @override
  Future<void> updateBudget(String id, String category, double limit, int iconCode) async {
    await _firestoreService.userCollection('budgets').doc(id).update({
      'category': category,
      'limit': limit,
      'iconCode': iconCode,
    });
    debugPrint("FIRESTORE: updateBudget OK, id=$id");
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _firestoreService.userCollection('budgets').doc(id).delete();
    debugPrint("FIRESTORE: deleteBudget OK, id=$id");
  }

  @override
  Future<void> clearBudgets() async {
    final snapshot = await _firestoreService.userCollection('budgets').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint("FIRESTORE: clearBudgets OK");
  }
}
