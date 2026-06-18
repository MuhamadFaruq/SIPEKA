import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sipeka/core/services/ai_service.dart';
import 'package:sipeka/core/theme/theme_provider.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final AiService _aiService;
  ChatSession? _chatSession;
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _aiService = AiService();
    // Add default initial welcome message
    _messages.add(ChatMessage(
      text: "Halo! Saya SIPEKA AI, konsultan keuangan pribadi Anda. Saya sudah membaca ringkasan data keuangan Anda bulan ini. Ada yang bisa saya bantu atau analisis hari ini?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initAiChat();
      _isInit = true;
    }
  }

  void _initAiChat() {
    final contextData = _buildContextData(context);
    try {
      _chatSession = _aiService.startFinancialChat(contextData);
    } catch (e) {
      debugPrint("Gagal menginisialisasi Chat Session AI: $e");
    }
  }

  String _buildContextData(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    
    final totalBalance = txProvider.dompetBalance + txProvider.ewalletBalance;
    final now = DateTime.now();
    final monthTransactions = txProvider.transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    
    double income = 0;
    double expense = 0;
    for (var t in monthTransactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    
    String budgetStr = "";
    for (var b in budgetProvider.budgets) {
      double spent = monthTransactions
          .where((tx) => tx.category == b.category && tx.type == TransactionType.expense)
          .fold(0.0, (sum, item) => sum + item.amount);
      budgetStr += "- Kategori ${b.category}: Terpakai Rp ${NumberFormat.decimalPattern('id').format(spent)} dari Batas Rp ${NumberFormat.decimalPattern('id').format(b.limit)}\n";
    }

    final userName = Provider.of<ThemeProvider>(context, listen: false).userName;

    return """
Nama Pengguna: $userName
Saldo Saat Ini:
- Dompet: Rp ${NumberFormat.decimalPattern('id').format(txProvider.dompetBalance)}
- E-Wallet: Rp ${NumberFormat.decimalPattern('id').format(txProvider.ewalletBalance)}
- Total Saldo: Rp ${NumberFormat.decimalPattern('id').format(totalBalance)}

Laporan Bulan Ini (${DateFormat('MMMM yyyy', 'id_ID').format(now)}):
- Total Uang Masuk: Rp ${NumberFormat.decimalPattern('id').format(income)}
- Total Uang Keluar: Rp ${NumberFormat.decimalPattern('id').format(expense)}
- Tabungan Bersih (Sisa): Rp ${NumberFormat.decimalPattern('id').format(income - expense)}

Daftar Anggaran Kategori:
${budgetStr.isEmpty ? 'Belum ada anggaran kategori.' : budgetStr}
""";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    String reply = "";
    if (_chatSession != null) {
      try {
        final response = await _chatSession!.sendMessage(Content.text(text)).timeout(const Duration(seconds: 15));
        reply = response.text?.trim() ?? "Maaf, saya tidak memahami pesan Anda.";
      } catch (e) {
        debugPrint("Chat AI Error: $e");
        reply = "Koneksi ke AI terputus. Pastikan kunci API Gemini Anda sudah terpasang dengan benar di file `.env`.";
      }
    } else {
      reply = "Gagal terhubung dengan asisten finansial AI. Coba restart aplikasi.";
    }

    setState(() {
      _messages.add(ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "SIPEKA AI Konsultan",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, isDark);
              },
            ),
          ),
          // Typing loader
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "SIPEKA AI sedang berpikir...",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          // Input bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final Color userBubbleColor = AppColors.primaryBlue;
    final Color aiBubbleColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
    
    final Color userTextColor = Colors.white;
    final Color aiTextColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.nunito(
                      color: message.isUser ? userTextColor : aiTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 9,
                        color: message.isUser ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Tanya SIPEKA AI tentang keuangan...",
                  hintStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
