import 'package:flutter/foundation.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import '../models/wallet_model.dart';

abstract class WalletDataSource {
  Future<List<WalletModel>> getWallets();
  Future<void> insertWallet(WalletModel wallet);
  Future<void> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String id);
  Future<void> clearWallets();
}

class WalletFirestoreDataSource implements WalletDataSource {
  final FirestoreService _firestoreService;

  WalletFirestoreDataSource([FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService.instance;

  @override
  Future<List<WalletModel>> getWallets() async {
    final snapshot = await _firestoreService.userCollection('wallets').get();
    debugPrint("FIRESTORE: getWallets => ${snapshot.docs.length} docs");
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WalletModel(
        id: doc.id,
        name: data['name'] ?? '',
        initialBalance: (data['initial_balance'] as num?)?.toDouble() ?? 0.0,
        iconCode: data['icon_code'] ?? 0,
        colorHex: data['color_hex'] ?? '#007AFF',
        inviteCode: data['invite_code'],
        ownerId: data['owner_id'],
        isShared: data['is_shared'] == true || data['is_shared'] == 1,
      );
    }).toList();
  }

  @override
  Future<void> insertWallet(WalletModel wallet) async {
    _firestoreService.invalidateWalletsCache();
    await _firestoreService.userCollection('wallets').doc(wallet.id).set({
      'name': wallet.name,
      'initial_balance': wallet.initialBalance,
      'icon_code': wallet.iconCode,
      'color_hex': wallet.colorHex,
      'invite_code': wallet.inviteCode,
      'owner_id': wallet.ownerId,
      'is_shared': wallet.isShared,
    });
    debugPrint("FIRESTORE: insertWallet OK, id=${wallet.id}");
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    _firestoreService.invalidateWalletsCache();
    await _firestoreService.userCollection('wallets').doc(wallet.id).update({
      'name': wallet.name,
      'initial_balance': wallet.initialBalance,
      'icon_code': wallet.iconCode,
      'color_hex': wallet.colorHex,
      'invite_code': wallet.inviteCode,
      'owner_id': wallet.ownerId,
      'is_shared': wallet.isShared,
    });
    debugPrint("FIRESTORE: updateWallet OK, id=${wallet.id}");
  }

  @override
  Future<void> deleteWallet(String id) async {
    _firestoreService.invalidateWalletsCache();
    await _firestoreService.userCollection('wallets').doc(id).delete();
    debugPrint("FIRESTORE: deleteWallet OK, id=$id");
  }

  @override
  Future<void> clearWallets() async {
    _firestoreService.invalidateWalletsCache();
    final snapshot = await _firestoreService.userCollection('wallets').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint("FIRESTORE: clearWallets OK");
  }
}
