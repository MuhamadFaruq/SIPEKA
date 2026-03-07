
class Transaction {
  final String id;
  final String title;    // "Makan Siang"
  final double amount;   // 50000
  final DateTime date;   // Tanggal
  final String type;     // "Pemasukan" atau "Pengeluaran"
  final String category; // "Makan", "Transport"
  final String wallet;   // "Dompet" atau "E-Wallet" (INI BARU)

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.wallet, // Wajib diisi
  });
}