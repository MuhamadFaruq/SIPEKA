import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/features/wallet/domain/entities/wallet_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';

class SharedWalletSyncService {
  static final SharedWalletSyncService instance = SharedWalletSyncService._init();
  SharedWalletSyncService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, StreamSubscription> _listeners = {};

  String? get _userId => _auth.currentUser?.uid;

  // Generates a random 6-character uppercase alphanumeric code
  String _generateInviteCode() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  // Uploads a wallet to Firestore, updates it locally as shared in SQLite
  Future<String?> shareWallet(WalletEntity wallet) async {
    final uid = _userId;
    if (uid == null) throw Exception("Harap login terlebih dahulu.");

    final code = _generateInviteCode();

    // 1. Simpan data dompet di Firestore '/shared_wallets'
    await _firestore.collection('shared_wallets').doc(wallet.id).set({
      'id': wallet.id,
      'name': wallet.name,
      'initial_balance': wallet.initialBalance,
      'icon_code': wallet.iconCode,
      'color_hex': wallet.colorHex,
      'invite_code': code,
      'owner_uid': uid,
      'member_uids': [uid],
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Perbarui baris dompet di SQLite lokal
    await DatabaseHelper.instance.updateWallet(wallet.id, {
      'is_shared': 1,
      'invite_code': code,
      'owner_id': uid,
    });

    return code;
  }

  // Joins a shared wallet in Firestore and maps it locally
  Future<bool> joinSharedWallet(String code) async {
    final uid = _userId;
    if (uid == null) throw Exception("Harap login terlebih dahulu.");

    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 6) throw Exception("Kode undangan harus 6 karakter.");

    // 1. Cari dompet bersama di Firestore berdasarkan invite_code
    final query = await _firestore
        .collection('shared_wallets')
        .where('invite_code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Kode undangan tidak ditemukan.");
    }

    final doc = query.docs.first;
    final data = doc.data();
    final String walletId = doc.id;
    final List<dynamic> memberUids = data['member_uids'] ?? [];

    // 2. Tambahkan UID user saat ini ke daftar member di Firestore
    if (!memberUids.contains(uid)) {
      memberUids.add(uid);
      await _firestore.collection('shared_wallets').doc(walletId).update({
        'member_uids': memberUids,
      });
    }

    // 3. Masukkan record dompet baru ke SQLite lokal
    await DatabaseHelper.instance.insertWallet({
      'id': walletId,
      'name': data['name'],
      'initial_balance': (data['initial_balance'] as num?)?.toDouble() ?? 0.0,
      'icon_code': data['icon_code'] ?? 0,
      'color_hex': data['color_hex'] ?? '#007AFF',
      'is_shared': 1,
      'invite_code': cleanCode,
      'owner_id': data['owner_uid'],
    });

    // 4. Unduh semua transaksi yang ada di dompet bersama ke SQLite lokal
    final txQuery = await _firestore
        .collection('shared_wallets')
        .doc(walletId)
        .collection('transactions')
        .get();

    for (var txDoc in txQuery.docs) {
      final txData = txDoc.data();
      await DatabaseHelper.instance.insertTransaction({
        'id': txDoc.id,
        'title': txData['title'] ?? '',
        'amount': (txData['amount'] as num?)?.toDouble() ?? 0.0,
        'date': txData['date'] ?? DateTime.now().toIso8601String(),
        'type': txData['type'] ?? 'Expense',
        'category': txData['category'] ?? 'Lainnya',
        'wallet': data['name'], // Gunakan nama dompet bersama
        'source': txData['source'] ?? 'Shared',
      });
    }

    return true;
  }

  // Starts real-time listeners for all shared wallets in the local database
  void startListeningToSharedWallets({
    required Function onTransactionUpdated,
    required Function onWalletUpdated,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    // Ambil daftar semua dompet dari SQLite lokal
    final allWallets = await DatabaseHelper.instance.getAllWallets();
    final sharedWallets = allWallets.where((w) => (w['is_shared'] ?? 0) == 1).toList();

    for (var wallet in sharedWallets) {
      final walletId = wallet['id'] as String;
      final walletName = wallet['name'] as String;

      if (_listeners.containsKey(walletId)) continue; // Listener sudah berjalan

      debugPrint("SHARED WALLET: Memulai listener real-time untuk dompet '$walletName' (id=$walletId)");

      final subscription = _firestore
          .collection('shared_wallets')
          .doc(walletId)
          .collection('transactions')
          .snapshots()
          .listen((snapshot) async {
        debugPrint("SHARED WALLET: Menerima update transaksi dari cloud untuk dompet '$walletName'.");
        bool hasChanges = false;

        for (var change in snapshot.docChanges) {
          final docId = change.doc.id;
          final data = change.doc.data();

          if (change.type == DocumentChangeType.removed) {
            // Hapus dari SQLite lokal
            await DatabaseHelper.instance.deleteTransaction(docId);
            hasChanges = true;
          } else {
            if (data != null) {
              // Masukkan atau perbarui SQLite lokal
              await DatabaseHelper.instance.insertTransaction({
                'id': docId,
                'title': data['title'] ?? '',
                'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
                'date': data['date'] ?? DateTime.now().toIso8601String(),
                'type': data['type'] ?? 'Expense',
                'category': data['category'] ?? 'Lainnya',
                'wallet': walletName,
                'source': data['source'] ?? 'Shared',
              });
              hasChanges = true;
            }
          }
        }

        if (hasChanges) {
          onTransactionUpdated();
          onWalletUpdated();
        }
      }, onError: (err) {
        debugPrint("SHARED WALLET ERROR: Gagal sinkronisasi dompet '$walletName': $err");
      });

      _listeners[walletId] = subscription;
    }
  }

  // Stops all listeners
  void stopAllListeners() {
    for (var sub in _listeners.values) {
      sub.cancel();
    }
    _listeners.clear();
    debugPrint("SHARED WALLET: Semua listener real-time berhasil dihentikan.");
  }

  // Uploads a transaction to the shared wallet's collection in Firestore
  Future<void> addSharedTransaction(TransactionEntity tx, String walletId) async {
    await _firestore
        .collection('shared_wallets')
        .doc(walletId)
        .collection('transactions')
        .doc(tx.id)
        .set({
      'title': tx.title,
      'amount': tx.amount,
      'date': tx.date.toIso8601String(),
      'type': tx.type.dbValue,
      'category': tx.category,
      'source': 'Shared',
    });
  }

  // Deletes a transaction from the shared wallet's collection in Firestore
  Future<void> deleteSharedTransaction(String txId, String walletId) async {
    await _firestore
        .collection('shared_wallets')
        .doc(walletId)
        .collection('transactions')
        .doc(txId)
        .delete();
  }
}
