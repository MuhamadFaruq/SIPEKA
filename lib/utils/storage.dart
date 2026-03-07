import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const String _transactionsKey = 'transactions';
  static const String _categoriesKey = 'categories';
  static const String _budgetsKey = 'budgets';
  static const String _wishlistsKey = 'wishlists';
  static const String _quickActionsKey = 'quick_actions';
  static const String _debtsKey = 'debts';
  static const String _userNameKey = 'user_name';
  static const String _dompetBalanceKey = 'dompet_balance';
  static const String _ewalletBalanceKey = 'ewallet_balance';

  // Transactions
  static Future<List<Map<String, dynamic>>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_transactionsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transactionsKey, json.encode(transactions));
  }

  // Categories
  static Future<List<Map<String, dynamic>>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoriesKey, json.encode(categories));
  }

  // Budgets
  static Future<List<Map<String, dynamic>>> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_budgetsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveBudgets(List<Map<String, dynamic>> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetsKey, json.encode(budgets));
  }

  // Wishlists
  static Future<List<Map<String, dynamic>>> loadWishlists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_wishlistsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveWishlists(List<Map<String, dynamic>> wishlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wishlistsKey, json.encode(wishlists));
  }

  // Quick Actions
  static Future<List<Map<String, dynamic>>> loadQuickActions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_quickActionsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveQuickActions(List<Map<String, dynamic>> quickActions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quickActionsKey, json.encode(quickActions));
  }

  // User Settings
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Wallet Balances
  static Future<double> getDompetBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dompetBalanceKey) ?? 0.0;
  }

  static Future<void> saveDompetBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dompetBalanceKey, balance);
  }

  static Future<double> getEwalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_ewalletBalanceKey) ?? 0.0;
  }

  static Future<void> saveEwalletBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ewalletBalanceKey, balance);
  }

  // Debts
  static Future<List<Map<String, dynamic>>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_debtsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveDebts(List<Map<String, dynamic>> debts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_debtsKey, json.encode(debts));
  }
}

