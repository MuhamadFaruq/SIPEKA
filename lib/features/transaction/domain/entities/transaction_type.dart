enum TransactionType {
  income,  // Pemasukan
  expense; // Pengeluaran

  String get label => this == income ? 'Pemasukan' : 'Pengeluaran';
  String get dbValue => this == income ? 'Income' : 'Expense';

  static TransactionType fromString(String? value) {
    if (value == 'Income' || value == 'Pemasukan') return income;
    return expense; // default + backward compat
  }
}
