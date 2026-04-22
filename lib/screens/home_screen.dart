import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// Import Provider
import '../providers/transaction_provider.dart';
import '../providers/quick_action_provider.dart';
import '../providers/budget_provider.dart'; 
import '../providers/theme_provider.dart';

// Import Model & Utils
import '../models/transaction_model.dart';
import '../models/quick_action_model.dart';
import '../utils/formatters.dart'; 
import '../utils/constants.dart';
import '../utils/notifications.dart'; 
import '../utils/transaction_helper.dart'; // Import Helper Baru

// Import Screen
import 'all_transactions_screen.dart';
import 'settings_screen.dart'; 

import '../widgets/transaction_pie_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- KODE TAMBAHAN VOICE COMMAND ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = "Tekan & tahan tombol mic untuk bicara...";

  void _showVoiceInputDialog() async {
    if (_speech.isListening) return;

    var status = await Permission.microphone.status;
    if (status.isDenied) {
      if (await Permission.microphone.request().isDenied) {
        if (mounted) SipekaNotification.showWarning(context, "Izin mikrofon ditolak.");
        return;
      }
    }

    try {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Status Voice: $status'),
        onError: (error) {
          debugPrint('Error Voice: $error');
          if (mounted) SipekaNotification.showWarning(context, "Gagal memulai mikrofon: ${error.errorMsg}");
        },
      );

      if (available) {
        setState(() => _voiceText = "Tekan & tahan tombol mic untuk bicara...");
        
        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Pencatatan Cepat (Suara)", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isListening ? const Color(0xFF007AFF) : Colors.transparent, width: 2)
                        ),
                        child: Text(
                          _voiceText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16, 
                            color: _isListening ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : Colors.grey
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onLongPress: () async {
                          setModalState(() {
                            _isListening = true;
                            _voiceText = "Mendengarkan...";
                          });
                          
                          await _speech.listen(
                            onResult: (result) {
                              setModalState(() => _voiceText = result.recognizedWords);
                            },
                            localeId: "id_ID",
                          );
                        },
                        onLongPressUp: () async {
                          setModalState(() => _isListening = false);
                          await _speech.stop();
                          
                          if (_voiceText != "Mendengarkan..." && _voiceText.isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                Navigator.pop(ctx); 
                                // Panggil Helper:
                                TransactionHelper.processVoiceData(context: context, rawText: _voiceText);
                              }
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : const Color(0xFF007AFF)).withOpacity(0.4), 
                                blurRadius: 20, 
                                spreadRadius: 5
                              )
                            ]
                          ),
                          child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(_isListening ? "Lepas jika sudah selesai" : "Tahan tombol untuk bicara", 
                        style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                );
              },
            );
          },
        );
      } else {
        if (mounted) SipekaNotification.showWarning(context, "Fitur suara tidak tersedia.");
      }
    } catch (e) {
      debugPrint("Fatal Error Voice: $e");
      if (mounted) SipekaNotification.showWarning(context, "Gagal memulai mikrofon.");
    }
  }
  // Logika _processVoiceData dan _showCategorySelector sudah dipindah ke TransactionHelper

  void _showAddShortcutDialog() {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final quickActionProvider = Provider.of<QuickActionProvider>(context, listen: false);
    
    List<String> daftarAnggaran = budgetProvider.budgets.map((b) => b.category).toList();

    if (daftarAnggaran.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Anggaran Kosong", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: const Text("Buat anggaran dulu di menu Anggaran sebelum menambah jalan pintas ya!"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    String? selectedKategori;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 25, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tambah Jalan Pintas", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor, 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text("Pilih Kategori Anggaran", style: GoogleFonts.nunito()),
                        value: selectedKategori,
                        items: daftarAnggaran.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: GoogleFonts.nunito()),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedKategori = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: "Nominal Transaksi Cepat",
                      filled: true,
                      fillColor: Theme.of(context).cardColor, 
                      prefixText: "Rp ",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00479E)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () {
                          String cleanValue = amountController.text.replaceAll('.', '');
                          double amt = double.tryParse(cleanValue) ?? 0;
                          
                          if (selectedKategori != null && amt > 0) {
                            int iconCode = budgetProvider.budgets.firstWhere((b) => b.category == selectedKategori).iconCode;
                            
                            quickActionProvider.addAction(QuickAction(
                              id: DateTime.now().toString(),
                              label: selectedKategori!,
                              category: selectedKategori!,
                              amount: amt,
                              icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
                            ));
                            
                            final currentContext = context;
                            Navigator.pop(ctx);
                            SipekaNotification.showSuccess(currentContext, "Jalan pintas $selectedKategori berhasil dibuat!");
                          }
                        },
                        child: Text("SIMPAN JALAN PINTAS", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final List<Transaction> sortedTransactions = provider.transactions;

    double dompetBalance = _calculateBalance(sortedTransactions, 'Dompet');
    double eWalletBalance = _calculateBalance(sortedTransactions, 'E-Wallet');
    double totalBalance = dompetBalance + eWalletBalance;

    String financialStatus = totalBalance < 500000 ? "Uangmu Tinggal Dikit - Irit Dulu Ya!" : "Uangmu Aman, Masih Bisa Jajan";
    Color statusColor = totalBalance < 500000 ? const Color(0xFFFF5252) : const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: RefreshIndicator( 
        onRefresh: () async => await provider.loadTransactions(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, dompetBalance, eWalletBalance, statusColor, financialStatus),
              _buildInsightsSection(context), 
              _buildQuickActionsSection(context),
              _buildLatestTransactionsSection(context, sortedTransactions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Analisis Pengeluaran", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.0 : 0.02), 
                  blurRadius: 10
                )
              ],
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: SizedBox(height: 130, child: TransactionPieChart())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double dompet, double ewallet, Color statusColor, String statusText) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007AFF), Color(0xFF00479E)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hallo ${themeProvider.userName}", 
                        style: GoogleFonts.nunito(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        )
                      ),
                      Text(
                        "Duitmu Aman Kok", 
                        style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70)
                      ),
                    ],
                  );
                },
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _showVoiceInputDialog,
                    icon: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 28)
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SettingsScreen())
                    ), 
                    icon: const Icon(Icons.settings_outlined, color: Colors.white)
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
            child: Text(statusText, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBalanceCard(context, "Dompet", dompet, isNegative: dompet < 0),
              const SizedBox(width: 15),
              _buildBalanceCard(context, "E-Wallet", ewallet, isNegative: ewallet < 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Jalan Pintas", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _showAddShortcutDialog, 
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF007AFF), size: 20)
              )
            ],
          ),
          const SizedBox(height: 15),
          Consumer<QuickActionProvider>(
            builder: (context, actionProvider, child) {
              if (actionProvider.actions.isEmpty) {
                return Center(child: Text("Belum ada pintasan", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: actionProvider.actions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 25), 
                      child: _buildShortcutIcon(context, action.icon, action.label, action.category, action.amount, action.id),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLatestTransactionsSection(BuildContext context, List<Transaction> sortedTransactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Transaksi Terbaru", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTransactionsScreen())),
                child: Text("Lihat Semua >", style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF007AFF))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          sortedTransactions.isEmpty 
          ? Center(child: Text("Belum ada data", style: GoogleFonts.nunito(color: Colors.grey)))
          : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTransactions.length > 5 ? 5 : sortedTransactions.length,
              itemBuilder: (ctx, index) => _buildTransactionItem(context, sortedTransactions[index]),
            ),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx) {
    bool isExpense = tx.type == 'Expense' || tx.type == 'Pengeluaran';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1), 
                shape: BoxShape.circle
              ),
              child: Icon(AppIcons.getIcon(tx.category), size: 20, color: const Color(0xFF007AFF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.title, style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )),
                  Text("${tx.category} • ${DateFormat('HH:mm').format(tx.date)}", 
                    style: GoogleFonts.nunito(color: Colors.grey, fontSize: 11)
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(tx.amount)}",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 15,
                    color: isExpense ? const Color(0xFFFF5252) : const Color(0xFF00C853),
                  ),
                ),
                Text(tx.wallet, style: GoogleFonts.nunito(color: Colors.grey, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateBalance(List<Transaction> transactions, String walletName) {
    double income = 0;
    double expense = 0;
    for (var tx in transactions) {
      if (tx.wallet == walletName) {
        if (tx.type == 'Income' || tx.type == 'Pemasukan') {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }
    return income - expense;
  }

  Widget _buildBalanceCard(BuildContext context, String title, double amount, {bool isNegative = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
              style: GoogleFonts.nunito(
                fontSize: 15, 
                fontWeight: FontWeight.bold, 
                color: isNegative ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutIcon(BuildContext context, IconData icon, String label, String category, double amount, String id) {
    return GestureDetector(
      onTap: () => TransactionHelper.showConfirmationDialog(
        context: context, 
        label: label, 
        category: category, 
        amount: amount, 
        icon: icon, 
        source: "Jalan Pintas"
      ),
      onLongPress: () {
        Provider.of<QuickActionProvider>(context, listen: false).removeAction(id);
        SipekaNotification.showWarning(context, "Jalan pintas $label dihapus");
      },
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, 
              shape: BoxShape.circle, 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.0 : 0.05), 
                  blurRadius: 5
                )
              ]
            ),
            child: Icon(icon, color: const Color(0xFF007AFF), size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
        ],
      ),
    );
  }
}