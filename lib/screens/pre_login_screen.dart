import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/quick_action_provider.dart';
import '../utils/notifications.dart';
import '../utils/transaction_helper.dart';
import 'pin_screen.dart';
import 'main_navigation.dart';
import 'package:sipeka/providers/transaction_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';
import '../utils/ocr_helper.dart';
import '../providers/budget_provider.dart';

class PreLoginScreen extends StatefulWidget {
  const PreLoginScreen({super.key});

  @override
  State<PreLoginScreen> createState() => _PreLoginScreenState();
}


class _PreLoginScreenState extends State<PreLoginScreen> {

  @override
  void initState() {
    super.initState();
    // Tarik data anggaran segera setelah screen dimuat
    Future.microtask(() {
      if (mounted) {
        Provider.of<BudgetProvider>(context, listen: false).fetchAndSetBudgets();
      }
    });
  }

  // --- Variabel Voice ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceText = "Tekan & tahan tombol mic untuk bicara...";

  // --- Fungsi Voice ---
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

        // ✅ Simpan screenContext sebelum masuk builder
        final screenContext = context;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))
          ),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Pencatatan Cepat (Suara)",
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isListening ? const Color(0xFF007AFF) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _voiceText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color
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
                            // Tambahkan fetch budgets di sini juga supaya data kategori siap
                            await Provider.of<BudgetProvider>(context, listen: false).fetchAndSetBudgets();

                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                Navigator.pop(ctx);
                                TransactionHelper.processVoiceData(
                                  context: screenContext,
                                  rawText: _voiceText,
                                );
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
                                color: (_isListening ? Colors.red : const Color(0xFF007AFF))
                                  .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _isListening ? "Lepas jika sudah selesai" : "Tahan tombol untuk bicara",
                        style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                      ),
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

  void _showShortcutPicker(BuildContext context) {
    final actionProvider = Provider.of<QuickActionProvider>(context, listen: false);
    
    // ✅ Simpan context PreLoginScreen di sini, sebelum masuk builder
    final screenContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pilih Jalan Pintas", 
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              if (actionProvider.actions.isEmpty)
                Text("Belum ada jalan pintas", 
                  style: GoogleFonts.nunito(color: Colors.grey))
              else
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, childAspectRatio: 0.8
                    ),
                    itemCount: actionProvider.actions.length,
                    itemBuilder: (_, index) {
                      final action = actionProvider.actions[index];
                      return Column(
                        children: [
                          IconButton(
                            icon: Icon(action.icon, color: const Color(0xFF007AFF)),
                            onPressed: () {
                              debugPrint("Mencoba memproses Pintas untuk: ${action.label}");
                              Navigator.pop(ctx);

                              // ✅ Delay singkat agar BottomSheet benar-benar tutup dulu
                              Future.delayed(const Duration(milliseconds: 300), () {
                                TransactionHelper.showConfirmationDialog(
                                  context: screenContext,
                                  label: action.label,
                                  category: action.category,
                                  amount: action.amount,
                                  icon: action.icon,
                                  source: "Jalan Pintas",
                                );
                              });
                            },
                          ),
                          Text(action.label, 
                            style: GoogleFonts.nunito(fontSize: 12), 
                            textAlign: TextAlign.center),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data tema saat ini
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      // Hapus background gradient hardcoded, ganti dengan scaffoldBackgroundColor
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Jika ingin tetap ada sedikit gradasi yang mengikuti tema:
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [theme.scaffoldBackgroundColor, theme.cardColor] 
              : [const Color(0xFFE0F7FA), theme.scaffoldBackgroundColor],
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              Icons.account_balance_wallet_rounded, 
              size: 80, 
              color: theme.primaryColor // Mengikuti Primary Color SIPEKA
            ),
            const SizedBox(height: 10),
            Text(
              "SIPEKA", 
              style: GoogleFonts.nunito(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                color: theme.primaryColor
              )
            ),
            const Spacer(flex: 2),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickIcon(context, Icons.camera_alt_rounded, "Foto Nota", () {
                  _showFotoNota();
                }),
                _buildQuickIcon(context, Icons.mic_rounded, "Voice", () {
                  _showVoiceInputDialog();
                }),
                _buildQuickIcon(context, Icons.bolt_rounded, "Pintas", () {
                   _showShortcutPicker(context);
                }),
              ],
            ),
            
            const SizedBox(height: 50),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    // Gunakan primary color atau warna aksen dari tema
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final bool isSecurityActive = prefs.getBool('is_security_enabled') ?? false;
                    
                    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                    final bgProvider = Provider.of<BudgetProvider>(context, listen: false);

                    // Tambahkan await fetch di sini agar data sinkron
                    await Future.wait([
                      txProvider.fetchAndSetTransactions(),
                      bgProvider.fetchAndSetBudgets(),
                    ]);

                    if (!mounted) return;
                    if (isSecurityActive) {
                     await Navigator.push(context, MaterialPageRoute(builder: (context) => const PinScreen()));
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
                    }
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: Text(
                    "LOGIN", 
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "v1.0.0", 
              style: GoogleFonts.nunito(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), 
                fontSize: 12
              )
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickIcon(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              // Warna background kotak mengikuti cardColor tema
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                  blurRadius: 10
                )
              ]
            ),
            child: Icon(icon, color: theme.primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: GoogleFonts.nunito(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color // Warna teks adaptif
            )
          ),
        ],
      ),
    );
  }

  // --- Variabel Foto Nota ---
  final ImagePicker _picker = ImagePicker();

  // --- Fungsi Foto Nota ---
  void _showFotoNota() async {
    try {
      HapticFeedback.mediumImpact();

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1920,
      );

      if (image != null && mounted) {
        _processImageResult(image);
      }
    } catch (e) {
      debugPrint("Error Camera PreLogin: $e");
      if (mounted) SipekaNotification.showWarning(context, "Kamera tidak bisa dibuka. Cek izin aplikasi.");
    }
  }

  void _processImageResult(XFile image) async {
    // 1. Crop Image
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        IOSUiSettings(
          title: 'Fokuskan pada Total Belanja',
          doneButtonTitle: 'Selesai',
          cancelButtonTitle: 'Batal',
          aspectRatioLockEnabled: false,
        ),
        AndroidUiSettings(
          toolbarTitle: 'Fokuskan pada Total Belanja',
          toolbarColor: const Color(0xFF007AFF),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );

    if (croppedFile == null || !mounted) return;

    // 2. Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF007AFF)),
      ),
    );

    try {
      // 3. Proses OCR & Ambil Budget
      double? result = await OCRHelper.extractTotal(croppedFile.path);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      
      // Jika data masih kosong, paksa tarik dari DB
      if (budgetProvider.budgets.isEmpty) {
        await budgetProvider.fetchAndSetBudgets();
      }
      
      final userCategories = budgetProvider.budgets.map((b) => b.category).toList();

      // 4. Tutup loading
      if (mounted) Navigator.pop(context);

      // 5. Validasi Hasil
      if (result != null && result > 0) {
        if (userCategories.isEmpty) {
          if (mounted) SipekaNotification.showWarning(context, "Buat anggaran dulu di menu utama.");
          return;
        }

        HapticFeedback.lightImpact();
        final formattedAmount = "Rp ${result.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}";

        SipekaNotification.showSuccess(context, "Terdeteksi: $formattedAmount");

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        TransactionHelper.showCategorySelector(
          context: context,
          rawText: "FOTO NOTA",
          amount: result,
          categories: userCategories,
          source: "Foto Nota",
        );
      } else {
        if (mounted) SipekaNotification.showWarning(context, "Gagal mendeteksi angka. Coba foto ulang.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error OCR: $e");
    }
  }
}