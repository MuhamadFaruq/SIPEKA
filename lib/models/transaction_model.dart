
class Transaction {
  final String id;
  final String title;    // "Makan Siang"
  final double amount;   // 50000
  final DateTime date;   // Tanggal
  final String type;     // "Pemasukan" atau "Pengeluaran"
  final String category; // "Makan", "Transport"
  final String wallet;   // "Dompet" atau "E-Wallet" (INI BARU)
  final String source;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.wallet, // Wajib diisi
    this.source = 'Manual',
  });

  // Pastikan toMap dan fromMap juga diupdate agar masuk ke SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'category': category,
      'wallet': wallet,
      'source': source, // SIMPAN KE DB
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      category: map['category'],
      wallet: map['wallet'],
      source: map['source'] ?? 'Manual', // AMBIL DARI DB
    );
  }
}