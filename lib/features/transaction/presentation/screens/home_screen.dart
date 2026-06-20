import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// Import Provider
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/quick_action/presentation/controllers/quick_action_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/core/theme/theme_provider.dart';

// Import Model & Utils
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/quick_action/domain/entities/quick_action_entity.dart';
import 'package:sipeka/core/utils/formatters.dart'; 
import 'package:sipeka/core/constants/constants.dart' hide AppColors;
import 'package:sipeka/core/services/notifications.dart'; 
import 'package:sipeka/features/transaction/presentation/utils/transaction_helper.dart';

// Import Screen
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/wallet/domain/entities/wallet_entity.dart';
import 'all_transactions_screen.dart';
import 'ai_chat_screen.dart';
import 'input_transaction_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/settings_screen.dart';

import 'package:sipeka/features/transaction/presentation/widgets/transaction_pie_chart.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'dart:async';
import 'package:sipeka/core/services/widget_service.dart';

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

  StreamSubscription<Uri?>? _widgetClickedSubscription;

  @override
  void initState() {
    super.initState();
    _initWidgetInteraction();
  }

  @override
  void dispose() {
    _widgetClickedSubscription?.cancel();
    super.dispose();
  }

  void _initWidgetInteraction() async {
    // 1. Cek jika aplikasi diluncurkan pertama kali dari widget (saat mati)
    final Uri? initialUri = await WidgetService.getInitiallyLaunchedUri();
    if (initialUri != null) {
      _handleWidgetClickAction(initialUri);
    }

    // 2. Dengarkan klik widget jika aplikasi sedang berjalan di background/aktif
    _widgetClickedSubscription = WidgetService.widgetClickedStream.listen((Uri? uri) {
      if (uri != null) {
        _handleWidgetClickAction(uri);
      }
    });
  }

  void _handleWidgetClickAction(Uri uri) {
    debugPrint("Klik Widget Terdeteksi: ${uri.toString()}");
    final String actionPath = uri.path;

    if (actionPath.contains("voice")) {
      // Buka dialog Input Suara
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _showVoiceInputDialog();
      });
    } else if (actionPath.contains("camera")) {
      // Buka kamera scan nota
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        Navigator.push(
          context,
          SmoothPageRoute(
            child: const InputTransactionScreen(startOcrScan: true),
          ),
        );
      });
    } else if (actionPath.contains("shortcut")) {
      // Buka dialog tambah jalan pintas
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _showAddShortcutDialog();
      });
    }
  }

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
                          border: Border.all(color: _isListening ? AppColors.primaryBlue : Colors.transparent, width: 2)
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
                      Listener(
                        onPointerDown: (_) async {
                          setModalState(() {
                            _isListening = true;
                            _voiceText = "Mendengarkan...";
                          });
                          
                          await _speech.listen(
                            onResult: (result) {
                              setModalState(() {
                                _voiceText = TransactionHelper.formatVoiceTextToRupiah(result.recognizedWords);
                              });
                            },
                            localeId: "id_ID",
                            listenMode: stt.ListenMode.confirmation,
                            partialResults: true,
                          );
                        },
                        onPointerUp: (_) async {
                          setModalState(() => _isListening = false);
                          await _speech.stop();
                          
                          Future.delayed(const Duration(milliseconds: 650), () {
                            if (_voiceText != "Mendengarkan..." && 
                                _voiceText.isNotEmpty && 
                                _voiceText != "Tekan & tahan tombol mic untuk bicara...") {
                              if (context.mounted && Navigator.canPop(ctx)) {
                                Navigator.pop(ctx); 
                                // Panggil Helper:
                                TransactionHelper.processVoiceData(context: context, rawText: _voiceText);
                              }
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : AppColors.primaryBlue).withOpacity(0.4), 
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
                      
                      // --- TOMBOL PROSES MANUAL JIKA AUTO-POP TIDAK TERJADI/LAMBAT ---
                      if (_voiceText.isNotEmpty &&
                          _voiceText != "Tekan & tahan tombol mic untuk bicara..." &&
                          _voiceText != "Mendengarkan..." &&
                          !_isListening) ...[
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (Navigator.canPop(ctx)) {
                                Navigator.pop(ctx);
                                TransactionHelper.processVoiceData(context: context, rawText: _voiceText);
                              }
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  "PROSES TRANSAKSI",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                        gradient: AppColors.primaryGradient,
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
                              id: const Uuid().v4(),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isLoading = provider.isLoading;
    final List<Transaction> sortedTransactions = provider.transactions;

    // Tampilkan skeleton loading saat data pertama kali dimuat
    if (isLoading && sortedTransactions.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Skeleton Header
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
              ),
            ),
            const Spacer(),
            Text(
              "Memuat data keuangan...",
              style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    final wallets = Provider.of<WalletProvider>(context).wallets;
    final double totalBalance = provider.getTotalBalance(wallets);

    String financialStatus;
    if (totalBalance <= 0) {
      financialStatus = "Waduh, Uangmu Habis! Cari Cuan Dulu Yuk.";
    } else if (totalBalance < 500000) {
      financialStatus = "Uangmu Tinggal Dikit Lho - Irit Dulu Ya!";
    } else {
      financialStatus = "Uangmu Aman, Masih Bisa Jajan";
    }
    Color statusColor = totalBalance < 500000 ? AppColors.expenseRed : AppColors.incomeGreen;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: RefreshIndicator( 
        onRefresh: () async => await provider.loadTransactions(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: CollapsingHeaderDelegate(
                statusBarHeight: statusBarHeight,
                wallets: wallets,
                txProvider: provider,
                userName: themeProvider.userName,
                statusText: financialStatus,
                statusColor: statusColor,
                onVoicePressed: _showVoiceInputDialog,
                onSettingsPressed: () => Navigator.push(
                  context, 
                  SmoothPageRoute(child: const SettingsScreen())
                ),
                onAiChatPressed: () => Navigator.push(
                  context, 
                  SmoothPageRoute(child: const AiChatScreen())
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildInsightsSection(context)),
            SliverToBoxAdapter(child: _buildQuickActionsSection(context)),
            SliverToBoxAdapter(child: _buildLatestTransactionsSection(context, sortedTransactions)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Analisis Pengeluaran", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
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

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Jalan Pintas", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _showAddShortcutDialog, 
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20)
              )
            ],
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Transaksi Terbaru", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, SmoothPageRoute(child: const AllTransactionsScreen())),
                child: Text("Lihat Semua >", style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          sortedTransactions.isEmpty 
          ? Center(child: Text("Belum ada data", style: GoogleFonts.nunito(color: Colors.grey)))
          : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTransactions.length > 5 ? 5 : sortedTransactions.length,
              itemBuilder: (ctx, index) => _buildTransactionItem(context, sortedTransactions[index]),
            ),
          const SizedBox(height: 30), 
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx) {
    bool isExpense = tx.type == TransactionType.expense;

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
                color: AppColors.primaryBlue.withOpacity(0.1), 
                shape: BoxShape.circle
              ),
              child: Icon(AppIcons.getIcon(tx.category), size: 20, color: AppColors.primaryBlue),
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
                    color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final walletProv = Provider.of<WalletProvider>(context, listen: false);
                    final wallet = walletProv.wallets.firstWhere(
                      (w) => w.name.toLowerCase() == tx.wallet.toLowerCase(),
                      orElse: () => const WalletEntity(id: '', name: '', initialBalance: 0, iconCode: 0, colorHex: '#9E9E9E'),
                    );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tx.wallet, style: GoogleFonts.nunito(color: Colors.grey, fontSize: 9)),
                        if (wallet.isShared) ...[
                          const SizedBox(width: 3),
                          const Icon(Icons.cloud_done_rounded, size: 10, color: Colors.blue),
                        ],
                      ],
                    );
                  }
                ),
              ],
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
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
        ],
      ),
    );
  }
}

class CollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final List<WalletEntity> wallets;
  final TransactionProvider txProvider;
  final String userName;
  final String statusText;
  final Color statusColor;
  final VoidCallback onVoicePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onAiChatPressed;

  CollapsingHeaderDelegate({
    required this.statusBarHeight,
    required this.wallets,
    required this.txProvider,
    required this.userName,
    required this.statusText,
    required this.statusColor,
    required this.onVoicePressed,
    required this.onSettingsPressed,
    required this.onAiChatPressed,
  });

  @override
  double get minExtent => statusBarHeight + 70.0; // Collapsed height

  @override
  double get maxExtent => statusBarHeight + 210.0; // Expanded height

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate collapse ratio (0.0 fully expanded, 1.0 fully collapsed)
    final double delta = maxExtent - minExtent;
    final double percent = (shrinkOffset / (delta > 0 ? delta : 1.0)).clamp(0.0, 1.0);

    // Opacities for smooth transition
    final double expandedOpacity = (1.0 - percent * 2.0).clamp(0.0, 1.0);
    final double collapsedOpacity = (percent - 0.5).clamp(0.0, 1.0) * 2.0;

    // Corner radius of the header collapses from 30 to 0
    final double borderRadius = (30.0 * (1.0 - percent)).clamp(0.0, 30.0);

    final double totalBalance = txProvider.getTotalBalance(wallets);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Stack(
            children: [
              // Top row content (Greeting vs. Total Saldo + Icons)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Transitioning title
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Opacity(
                            opacity: expandedOpacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Hallo $userName",
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Duitmu Aman Kok",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Opacity(
                            opacity: collapsedOpacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total Saldo",
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(totalBalance),
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons (Mic, AI Chat & Settings)
                    Row(
                      children: [
                        IconButton(
                          onPressed: onAiChatPressed,
                          icon: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
                          tooltip: "AI Chatbot",
                        ),
                        IconButton(
                          onPressed: onVoicePressed,
                          icon: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 28),
                        ),
                        IconButton(
                          onPressed: onSettingsPressed,
                          icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expanded components (Status badge and balance cards)
              if (expandedOpacity > 0)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (wallets.isNotEmpty)
                          SizedBox(
                            height: 60,
                            child: wallets.length == 1
                                ? _buildWalletCard(
                                    context,
                                    wallets[0],
                                    wallets[0].initialBalance +
                                        txProvider.getWalletBalance(wallets[0].name),
                                    customWidth: double.infinity,
                                  )
                                : wallets.length == 2
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: _buildWalletCard(
                                              context,
                                              wallets[0],
                                              wallets[0].initialBalance +
                                                  txProvider.getWalletBalance(wallets[0].name),
                                              customWidth: double.infinity,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildWalletCard(
                                              context,
                                              wallets[1],
                                              wallets[1].initialBalance +
                                                  txProvider.getWalletBalance(wallets[1].name),
                                              customWidth: double.infinity,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: wallets.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final wallet = wallets[index];
                                          final balance = wallet.initialBalance +
                                              txProvider.getWalletBalance(wallet.name);
                                          return _buildWalletCard(context, wallet, balance);
                                        },
                                      ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, WalletEntity wallet, double balance, {double? customWidth}) {
    final walletColor = Color(int.parse(wallet.colorHex.replaceFirst('#', '0xFF')));
    return Container(
      width: customWidth ?? 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                IconData(wallet.iconCode, fontFamily: 'MaterialIcons'),
                color: walletColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  wallet.name,
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(balance),
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: balance < 0 ? AppColors.expenseRed : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CollapsingHeaderDelegate oldDelegate) {
    return true;
  }
}