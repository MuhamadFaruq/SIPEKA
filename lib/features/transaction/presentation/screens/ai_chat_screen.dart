import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sipeka/core/services/ai_service.dart';
import 'package:sipeka/core/services/local_kb_service.dart';
import 'package:sipeka/core/theme/theme_provider.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] as String,
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
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
  String? _initError;
  bool _isLoading = false;
  bool _isInit = false;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _aiService = AiService();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final dbMsgs = await DatabaseHelper.instance.getAllChatMessages();
      setState(() {
        _messages.clear();
        if (dbMsgs.isEmpty) {
          // Tambahkan pesan sambutan default jika belum ada riwayat
          _messages.add(ChatMessage(
            text: "Halo! Saya SIPEKA AI, konsultan keuangan pribadi Anda. Saya sudah membaca ringkasan data keuangan Anda bulan ini. Ada yang bisa saya bantu atau analisis hari ini?",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        } else {
          _messages.addAll(dbMsgs.map((m) => ChatMessage.fromMap(m)));
        }
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading chat history: $e");
      setState(() {
        _isLoadingHistory = false;
      });
    }
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
      _initError = null;
    } catch (e) {
      debugPrint("Gagal menginisialisasi Chat Session AI: $e");
      _initError = e.toString();
    }
  }

  String _buildContextData(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    final wallets = walletProvider.wallets;
    final totalBalance = txProvider.getTotalBalance(wallets);
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

    String walletsStr = "";
    for (var w in wallets) {
      final bal = w.initialBalance + txProvider.getWalletBalance(w.name);
      walletsStr += "- ${w.name}: Rp ${NumberFormat.decimalPattern('id').format(bal)}\n";
    }

    return """
Nama Pengguna: $userName
Saldo Saat Ini:
$walletsStr- Total Saldo: Rp ${NumberFormat.decimalPattern('id').format(totalBalance)}

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
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();

    // Simpan pesan user ke database
    try {
      await DatabaseHelper.instance.insertChatMessage(userMsg.toMap());
    } catch (e) {
      debugPrint("Gagal menyimpan pesan user ke DB: $e");
    }

    final isFinance = LocalKbService().isFinanceRelated(text);

    if (!isFinance) {
      // Pertanyaan non-keuangan langsung dijawab secara lokal tanpa API Gemini
      const reply = "Maaf, sebagai SIPEKA AI Konsultan Keuangan, saya hanya dirancang khusus untuk membantu Anda dalam mengelola keuangan pribadi (seperti anggaran, transaksi, wishlist, hutang piutang, dan tips finansial). Silakan tanyakan hal yang berkaitan dengan keuangan!";
      
      final aiMsg = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMsg);
      });
      _scrollToBottom();

      try {
        await DatabaseHelper.instance.insertChatMessage(aiMsg.toMap());
      } catch (e) {
        debugPrint("Gagal menyimpan pesan AI ke DB: $e");
      }
      return;
    }

    // Jika terkait keuangan, kirim ke Gemini API dengan RAG
    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    String reply = "";
    if (_chatSession != null) {
      try {
        final matchedArticles = LocalKbService().retrieveContext(text);
        String enrichedPrompt = text;
        if (matchedArticles.isNotEmpty) {
          final contextString = matchedArticles.map((a) => "- ${a.title}: ${a.content}").join("\n");
          enrichedPrompt = "$text\n\n[INFORMASI REFERENSI LOKAL SIPEKA]\n$contextString\n[Gunakan informasi referensi di atas untuk memberikan jawaban yang akurat jika relevan dengan pertanyaan user]";
        }

        final response = await _chatSession!.sendMessage(Content.text(enrichedPrompt)).timeout(const Duration(seconds: 15));
        reply = response.text?.trim() ?? "Maaf, saya tidak memahami pesan Anda.";
      } catch (e) {
        debugPrint("Chat AI Error: $e");
        reply = AiService.formatError(e);
      }
    } else {
      reply = AiService.formatError(_initError);
    }

    final aiMsg = ChatMessage(
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(aiMsg);
      _isLoading = false;
    });
    _scrollToBottom();

    // Simpan respons AI ke database
    try {
      await DatabaseHelper.instance.insertChatMessage(aiMsg.toMap());
    } catch (e) {
      debugPrint("Gagal menyimpan pesan AI ke DB: $e");
    }
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Bersihkan Chat?", style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color
        )),
        content: Text("Seluruh riwayat obrolan dengan AI Konsultan akan dihapus permanen.", style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BATAL", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              // Tampilkan loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadCtx) => const Center(child: CircularProgressIndicator()),
              );
              try {
                await DatabaseHelper.instance.clearChatMessagesTable();
                if (mounted) Navigator.pop(context); // Tutup loading
                setState(() {
                  _messages.clear();
                  // Masukkan kembali welcome message
                  _messages.add(ChatMessage(
                    text: "Halo! Saya SIPEKA AI, konsultan keuangan pribadi Anda. Saya sudah membaca ringkasan data keuangan Anda bulan ini. Ada yang bisa saya bantu atau analisis hari ini?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ));
                });
                _scrollToBottom();
                if (mounted) SipekaNotification.showSuccess(context, "Riwayat chat telah dibersihkan.");
              } catch (e) {
                if (mounted) Navigator.pop(context); // Tutup loading
                if (mounted) SipekaNotification.showWarning(context, "Gagal membersihkan chat: $e");
              }
            },
            child: const Text("HAPUS")
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF2C1E1B), const Color(0xFF1F1513)]
              : [const Color(0xFFFFF1F0), const Color(0xFFFFE5E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(isDark ? 0.0 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "AI Gemini API Key Belum Diatur",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.red[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Layanan konsultasi AI SIPEKA membutuhkan kunci API. Silakan tambahkan variabel GEMINI_API_KEY ke dalam file .env di folder root proyek Anda untuk mulai menggunakannya.",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: "Bersihkan Chat",
            onPressed: _showClearChatConfirmation,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_initError != null) _buildErrorBanner(),
          // Message list or Loading history
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                SipekaNotification.showSuccess(context, "Pesan disalin ke papan klip");
              },
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
                    MarkdownRichText(
                      text: message.text,
                      style: GoogleFonts.nunito(
                        color: message.isUser ? userTextColor : aiTextColor,
                        fontSize: 14,
                      ),
                      boldStyle: GoogleFonts.nunito(
                        color: message.isUser ? userTextColor : aiTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            SipekaNotification.showSuccess(context, "Pesan disalin");
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 11,
                                  color: message.isUser ? Colors.white70 : Colors.grey,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "Salin",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: message.isUser ? Colors.white70 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 9,
                            color: message.isUser ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    final bool hasError = _initError != null;
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
                color: hasError
                    ? (isDark ? Colors.white10 : Colors.grey[200])
                    : (isDark ? Colors.black26 : const Color(0xFFF2F2F7)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !hasError,
                style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: hasError 
                      ? "Fitur dinonaktifkan karena error API Key..."
                      : "Tanya SIPEKA AI tentang keuangan...",
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
              decoration: BoxDecoration(
                gradient: hasError ? null : AppColors.primaryGradient,
                color: hasError ? Colors.grey : null,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: hasError ? null : _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkdownRichText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle? boldStyle;

  const MarkdownRichText({
    super.key,
    required this.text,
    required this.style,
    this.boldStyle,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> lines = text.split('\n');
    final List<Widget> children = [];

    final actualBoldStyle = boldStyle ?? style.copyWith(fontWeight: FontWeight.bold);

    for (var line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      bool isBullet = false;
      int indentLevel = 0;
      String cleanLine = line;

      // Detect indentation for nested bullets
      final trimmedLeft = line.trimLeft();
      final leadingSpaces = line.length - trimmedLeft.length;

      // Check if it is a list bullet
      if (trimmedLeft.startsWith('* ')) {
        isBullet = true;
        indentLevel = leadingSpaces;
        cleanLine = trimmedLeft.substring(2);
      } else if (trimmedLeft.startsWith('- ')) {
        isBullet = true;
        indentLevel = leadingSpaces;
        cleanLine = trimmedLeft.substring(2);
      }

      // Detect headers (e.g., ### Title)
      int headerLevel = 0;
      if (cleanLine.startsWith('#')) {
        int count = 0;
        while (count < cleanLine.length && cleanLine[count] == '#') {
          count++;
        }
        if (count < cleanLine.length && cleanLine[count] == ' ') {
          headerLevel = count;
          cleanLine = cleanLine.substring(count + 1);
        }
      }

      // Parse bold parts: split by '**'
      final parts = cleanLine.split('**');
      final List<TextSpan> spans = [];

      // Determine text styles based on header level
      TextStyle normalStyle = style;
      TextStyle customBoldStyle = actualBoldStyle;

      if (headerLevel > 0) {
        double factor = 1.0;
        if (headerLevel == 1) factor = 1.4;
        else if (headerLevel == 2) factor = 1.25;
        else factor = 1.15;

        normalStyle = style.copyWith(
          fontSize: (style.fontSize ?? 14.0) * factor,
          fontWeight: FontWeight.bold,
        );
        customBoldStyle = actualBoldStyle.copyWith(
          fontSize: (style.fontSize ?? 14.0) * factor,
          fontWeight: FontWeight.bold,
        );
      }

      // If it is a bullet, prepend a bullet point character
      if (isBullet) {
        spans.add(TextSpan(text: '•  ', style: customBoldStyle));
      }

      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 1) {
          // Odd index is bold
          spans.add(TextSpan(text: parts[i], style: customBoldStyle));
        } else {
          // Even index is normal
          spans.add(TextSpan(text: parts[i], style: normalStyle));
        }
      }

      children.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: 4,
            left: isBullet ? (12.0 + indentLevel * 4.0) : 0, // Indent based on bullet/spaces
          ),
          child: RichText(
            text: TextSpan(
              children: spans,
              style: normalStyle, // Default fallback
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
