import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/core/services/notification_service.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/get_bills.dart';
import '../../domain/usecases/add_bill.dart';
import '../../domain/usecases/update_bill.dart';
import '../../domain/usecases/delete_bill.dart';
import '../../data/repositories/bill_repository_impl.dart';

class BillProvider with ChangeNotifier {
  final GetBillsUseCase getBillsUseCase;
  final AddBillUseCase addBillUseCase;
  final UpdateBillUseCase updateBillUseCase;
  final DeleteBillUseCase deleteBillUseCase;

  List<BillEntity> _bills = [];
  bool _isLoading = false;

  List<BillEntity> get bills => _bills;
  bool get isLoading => _isLoading;

  BillProvider({
    GetBillsUseCase? getBillsUseCase,
    AddBillUseCase? addBillUseCase,
    UpdateBillUseCase? updateBillUseCase,
    DeleteBillUseCase? deleteBillUseCase,
  })  : getBillsUseCase = getBillsUseCase ?? GetBillsUseCase(BillRepositoryImpl()),
        addBillUseCase = addBillUseCase ?? AddBillUseCase(BillRepositoryImpl()),
        updateBillUseCase = updateBillUseCase ?? UpdateBillUseCase(BillRepositoryImpl()),
        deleteBillUseCase = deleteBillUseCase ?? DeleteBillUseCase(BillRepositoryImpl());

  Future<void> fetchBills() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bills = await getBillsUseCase();
    } catch (e) {
      debugPrint("Error fetching bills: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill(BillEntity bill) async {
    try {
      final success = await addBillUseCase(bill);
      if (success) {
        _bills.add(bill);
        await NotificationService.scheduleBillReminder(bill);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding bill: $e");
      return false;
    }
  }

  Future<bool> updateBill(BillEntity bill) async {
    try {
      final success = await updateBillUseCase(bill);
      if (success) {
        final index = _bills.indexWhere((b) => b.id == bill.id);
        if (index != -1) {
          _bills[index] = bill;
        }
        if (bill.isActive && bill.remindMe) {
          await NotificationService.scheduleBillReminder(bill);
        } else {
          await NotificationService.cancelBillReminder(bill.id);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating bill: $e");
      return false;
    }
  }

  Future<bool> deleteBill(String id) async {
    try {
      final success = await deleteBillUseCase(id);
      if (success) {
        _bills.removeWhere((b) => b.id == id);
        await NotificationService.cancelBillReminder(id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting bill: $e");
      return false;
    }
  }

  // --- AUTOMATIC BILLING CHECK & EXECUTION ---
  Future<void> processRecurringBills(BuildContext context) async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    await fetchBills();
    final today = DateTime.now();
    bool updatedAny = false;

    for (int i = 0; i < _bills.length; i++) {
      final bill = _bills[i];
      if (!bill.isActive) continue;

      DateTime nextDue = bill.nextExecutionDate;
      DateTime todayDate = DateTime(today.year, today.month, today.day);
      DateTime nextDueDate = DateTime(nextDue.year, nextDue.month, nextDue.day);

      if (nextDueDate.isBefore(todayDate) || nextDueDate.isAtSameMomentAs(todayDate)) {
        updatedAny = true;
        DateTime tempNextDue = nextDue;
        DateTime? tempLastExecuted = bill.lastExecutedDate;

        while (DateTime(tempNextDue.year, tempNextDue.month, tempNextDue.day).isBefore(todayDate) || 
               DateTime(tempNextDue.year, tempNextDue.month, tempNextDue.day).isAtSameMomentAs(todayDate)) {
          
          final txId = const Uuid().v4();
          final tx = TransactionEntity(
            id: txId,
            title: bill.title,
            amount: bill.amount,
            date: tempNextDue,
            type: bill.type.toLowerCase() == 'income' ? TransactionType.income : TransactionType.expense,
            category: bill.category,
            wallet: bill.wallet,
            source: 'Auto-Billing',
          );

          await txProvider.addTransaction(tx);
          debugPrint("AUTO-BILLING: Berhasil mencatat transaksi rutin: ${bill.title} senilai ${bill.amount}");

          tempLastExecuted = tempNextDue;
          tempNextDue = _calculateNextDate(tempNextDue, bill.frequency);
        }

        final updatedBill = BillEntity(
          id: bill.id,
          title: bill.title,
          amount: bill.amount,
          type: bill.type,
          category: bill.category,
          wallet: bill.wallet,
          frequency: bill.frequency,
          startDate: bill.startDate,
          lastExecutedDate: tempLastExecuted,
          nextExecutionDate: tempNextDue,
          isActive: bill.isActive,
          remindMe: bill.remindMe,
        );

        await updateBillUseCase(updatedBill);
        _bills[i] = updatedBill;
        await NotificationService.scheduleBillReminder(updatedBill);
      }
    }

    if (updatedAny) {
      notifyListeners();
      await txProvider.fetchAndSetTransactions();
    }
  }

  DateTime _calculateNextDate(DateTime currentDate, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
      case 'harian':
        return currentDate.add(const Duration(days: 1));
      case 'weekly':
      case 'mingguan':
        return currentDate.add(const Duration(days: 7));
      case 'monthly':
      case 'bulanan':
        int nextMonth = currentDate.month + 1;
        int nextYear = currentDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear += 1;
        }
        int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int nextDay = currentDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : currentDate.day;
        return DateTime(nextYear, nextMonth, nextDay, currentDate.hour, currentDate.minute);
      case 'yearly':
      case 'tahunan':
        int nextYear = currentDate.year + 1;
        int lastDayOfNextMonth = DateTime(nextYear, currentDate.month + 1, 0).day;
        int nextDay = currentDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : currentDate.day;
        return DateTime(nextYear, currentDate.month, nextDay, currentDate.hour, currentDate.minute);
      default:
        return currentDate.add(const Duration(days: 30));
    }
  }

  Future<void> clearAllData() async {
    _bills = [];
    notifyListeners();
  }
}
