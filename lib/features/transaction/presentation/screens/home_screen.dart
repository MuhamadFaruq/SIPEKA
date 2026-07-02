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
import 'package:sipeka/features/insight/presentation/controllers/financial_health_provider.dart';

import 'package:sipeka/features/transaction/presentation/widgets/financial_insight_tab_card.dart';
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
  bool _showBalance = true;

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
    final Color statusColor = totalBalance < 500000 ? AppColors.expenseRed : AppColors.incomeGreen;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadTransactions();
          if (!context.mounted) return;
          await Provider.of<FinancialHealthProvider>(context, listen: false).calculateHealthScore();
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Fixed Header ─────────────────────────────────────────
              _buildCompactHeader(
                context,
                provider,
                wallets,
                totalBalance,
                financialStatus,
                statusColor,
                themeProvider.userName,
              ),
              // ── Financial Insight Tab Card ────────────────────────────
              const FinancialInsightTabCard(),
              // ── Quick Actions ─────────────────────────────────────────
              _buildQuickActionsSection(context),
              // ── Transaksi Terbaru (fills remaining space) ─────────────
              Expanded(
                child: _buildLatestTransactionsSection(context, sortedTransactions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    TransactionProvider txProvider,
    List<WalletEntity> wallets,
    double totalBalance,
    String statusText,
    Color statusColor,
    String userName,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Greeting + Action Buttons (Sleek Glassmorphic Circles)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hallo $userName",
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            style: GoogleFonts.nunito(
                              fontSize: 12, 
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Glassmorphic Action Buttons
              _buildHeaderActionButton(
                icon: Icons.smart_toy_outlined,
                tooltip: "AI Chatbot",
                onTap: () => Navigator.push(context, SmoothPageRoute(child: const AiChatScreen())),
              ),
              const SizedBox(width: 8),
              _buildHeaderActionButton(
                icon: Icons.mic_none_rounded,
                tooltip: "Voice Input",
                onTap: _showVoiceInputDialog,
              ),
              const SizedBox(width: 8),
              _buildHeaderActionButton(
                icon: Icons.settings_outlined,
                tooltip: "Settings",
                onTap: () => Navigator.push(context, SmoothPageRoute(child: const SettingsScreen())),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total Saldo Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL SALDO",
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: _showBalance ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        firstChild: Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(totalBalance),
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        secondChild: Text(
                          "Rp ••••••••",
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _showBalance = !_showBalance),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Wallet cards
          if (wallets.isNotEmpty)
            SizedBox(
              height: 56,
              child: wallets.length == 1
                  ? _buildWalletCard(context, wallets[0],
                      wallets[0].initialBalance + txProvider.getWalletBalance(wallets[0].name),
                      customWidth: double.infinity)
                  : wallets.length == 2
                      ? Row(children: [
                          Expanded(child: _buildWalletCard(context, wallets[0],
                              wallets[0].initialBalance + txProvider.getWalletBalance(wallets[0].name),
                              customWidth: double.infinity)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildWalletCard(context, wallets[1],
                              wallets[1].initialBalance + txProvider.getWalletBalance(wallets[1].name),
                              customWidth: double.infinity)),
                        ])
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: wallets.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final w = wallets[index];
                            return _buildWalletCard(context, w,
                                w.initialBalance + txProvider.getWalletBalance(w.name));
                          },
                        ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, WalletEntity wallet, double balance, {double? customWidth}) {
    return Container(
      width: customWidth ?? 145,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconData(wallet.iconCode, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 11,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  wallet.name,
                  style: GoogleFonts.nunito(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (wallet.isShared) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.people_rounded,
                  color: Colors.white70,
                  size: 11,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showBalance ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(balance),
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              "Rp ••••",
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Jalan Pintas",
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _showAddShortcutDialog, 
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20),
                ),
              )
            ],
          ),
          const SizedBox(height: 1),
          Consumer<QuickActionProvider>(
            builder: (context, actionProvider, child) {
              if (actionProvider.actions.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.04),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Belum ada pintasan. Tekan '+' untuk menambah.",
                      style: GoogleFonts.nunito(color: Colors.grey, fontSize: 11.5),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 34,
                child: ListView(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: actionProvider.actions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10), 
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
      padding: const EdgeInsets.only(top: 4, left: 20, right: 20, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaksi Terbaru",
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, SmoothPageRoute(child: const AllTransactionsScreen())),
                child: Text(
                  "Lihat Semua >",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: sortedTransactions.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada data transaksi",
                      style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double availableHeight = constraints.maxHeight;
                      // Setiap item transaksi memakan tinggi sekitar 58dp (card + spacing)
                      final int itemsThatFit = (availableHeight / 58).floor();
                      // Tampilkan minimal 3 item, dan maksimal 5 item sesuai ruang yang tersedia
                      final int maxItems = itemsThatFit.clamp(3, 5);
                      final int count = sortedTransactions.length > maxItems 
                          ? maxItems 
                          : sortedTransactions.length;

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: count,
                        itemBuilder: (ctx, index) => _buildTransactionItem(context, sortedTransactions[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx) {
    bool isExpense = tx.type == TransactionType.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isExpense ? AppColors.expenseRed : AppColors.incomeGreen).withOpacity(0.08), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                AppIcons.getIcon(tx.category), 
                size: 18, 
                color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title, 
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13.5,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${tx.category} • ${DateFormat('HH:mm').format(tx.date)}", 
                    style: GoogleFonts.nunito(
                      color: Colors.grey, 
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.amount)}",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, 
                    fontSize: 14,
                    color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final walletProv = Provider.of<WalletProvider>(context, listen: false);
                    final wallet = walletProv.wallets.firstWhere(
                      (w) => w.name.toLowerCase() == tx.wallet.toLowerCase(),
                      orElse: () => const WalletEntity(id: '', name: '', initialBalance: 0, iconCode: 0, colorHex: '#9E9E9E'),
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tx.wallet, 
                            style: GoogleFonts.nunito(
                              color: Colors.grey[600], 
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (wallet.isShared) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.people_rounded, size: 9, color: AppColors.primaryBlue),
                          ],
                        ],
                      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 12),
            ),
            const SizedBox(width: 8),
            Text(
              label, 
              style: GoogleFonts.nunito(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}