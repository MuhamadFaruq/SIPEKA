import 'package:flutter/foundation.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';

abstract class TransactionDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<bool> insertTransaction(TransactionModel transaction);
  Future<bool> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class TransactionFirestoreDataSource implements TransactionDataSource {
  final FirestoreService _firestoreService;

  TransactionFirestoreDataSource([FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService.instance;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final snapshot = await _firestoreService
        .userCollection('transactions')
        .orderBy('date', descending: true)
        .get();
    
    debugPrint("FIRESTORE: getTransactions => ${snapshot.docs.length} docs");
    return snapshot.docs.map((doc) {
      return TransactionModel.fromMap({'id': doc.id, ...doc.data()});
    }).toList();
  }

  @override
  Future<bool> insertTransaction(TransactionModel transaction) async {
    try {
      await _firestoreService
          .userCollection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap()..remove('id'));
      debugPrint("FIRESTORE: insertTransaction OK, id=${transaction.id}");
      return true;
    } catch (e) {
      debugPrint("FIRESTORE: insertTransaction ERROR: $e");
      return false;
    }
  }

  @override
  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestoreService
          .userCollection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap()..remove('id'));
      debugPrint("FIRESTORE: updateTransaction OK, id=${transaction.id}");
      return true;
    } catch (e) {
      debugPrint("FIRESTORE: updateTransaction ERROR: $e");
      return false;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _firestoreService.userCollection('transactions').doc(id).delete();
    debugPrint("FIRESTORE: deleteTransaction OK, id=$id");
  }
}
