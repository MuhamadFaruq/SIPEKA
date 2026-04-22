import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../utils/notifications.dart'; // Import Notifikasi Atas SIPEKA

class SUSEvaluationScreen extends StatefulWidget {
  const SUSEvaluationScreen({super.key});

  @override
  State<SUSEvaluationScreen> createState() => _SUSEvaluationScreenState();
}

class _SUSEvaluationScreenState extends State<SUSEvaluationScreen> {
  final PageController _pageController = PageController();
  int _currentQuestion = 0;
  final List<int> _answers = List.filled(10, -1); // 10 SUS questions

  // Definisi warna gradasi agar konsisten dengan halaman lain
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  final List<Map<String, String>> _questions = [
    {
      'question': 'Ribet gak pas dipake?',
      'positive': 'Gampang banget dipake',
      'negative': 'Ribet banget',
    },
    {
      'question': 'Fitur-fitur aplikasinya kompleks?',
      'positive': 'Sederhana dan jelas',
      'negative': 'Sangat kompleks',
    },
    {
      'question': 'Aplikasinya mudah digunakan?',
      'positive': 'Sangat mudah',
      'negative': 'Sulit digunakan',
    },
    {
      'question': 'Perlu bantuan teknis untuk pakai aplikasi?',
      'positive': 'Tidak perlu bantuan',
      'negative': 'Perlu banyak bantuan',
    },
    {
      'question': 'Fitur-fitur aplikasinya terintegrasi dengan baik?',
      'positive': 'Sangat terintegrasi',
      'negative': 'Tidak terintegrasi',
    },
    {
      'question': 'Aplikasinya tidak konsisten?',
      'positive': 'Sangat konsisten',
      'negative': 'Tidak konsisten',
    },
    {
      'question': 'Kebanyakan orang bisa langsung pakai aplikasi ini?',
      'positive': 'Ya, langsung bisa',
      'negative': 'Tidak, perlu belajar',
    },
    {
      'question': 'Aplikasinya rumit?',
      'positive': 'Sederhana',
      'negative': 'Sangat rumit',
    },
    {
      'question': 'Percaya diri pakai aplikasi ini?',
      'positive': 'Sangat percaya diri',
      'negative': 'Tidak percaya diri',
    },
    {
      'question': 'Perlu belajar banyak hal baru sebelum pakai aplikasi?',
      'positive': 'Tidak perlu belajar',
      'negative': 'Perlu belajar banyak',
    },
  ];

  final List<String> _emojis = ['😠', '😕', '😐', '🙂', '🤩'];
  final List<String> _labels = ['Sangat Tidak', 'Tidak', 'Netral', 'Setuju', 'Sangat Setuju'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectAnswer(int value) {
    setState(() {
      _answers[_currentQuestion] = value;
    });
  }

  void _nextQuestion() {
    if (_answers[_currentQuestion] == -1) {
      SipekaNotification.showWarning(context, "Pilih jawaban dulu ya!");
      return;
    }

    if (_currentQuestion < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitEvaluation();
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitEvaluation() async {
    double totalScore = 0;

    for (int i = 0; i < _answers.length; i++) {
      int response = _answers[i] + 1; 

      if (i % 2 == 0) {
        totalScore += (response - 1);
      } else {
        totalScore += (5 - response);
      }
    }

    double finalSusScore = totalScore * 2.5;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sus_score', finalSusScore);
    await prefs.setBool('sus_completed', true);
    await prefs.setString('sus_date', DateTime.now().toIso8601String());

    if (mounted) {
      Navigator.pop(context);
      SipekaNotification.showSuccess(
        context, 
        'Feedback terkirim! Skor SUS: ${finalSusScore.toStringAsFixed(1)}/100'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        // Sesuaikan Gradient dengan halaman lain
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          'Feedback Aplikasi',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: List.generate(
                  _questions.length,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentQuestion
                            ? AppColors.primaryBlue
                            : AppColors.neutralGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Question Card
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestion = index;
                  });
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(index);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Kembali',
                        onPressed: _previousQuestion,
                        backgroundColor: AppColors.neutralGrey,
                        isLarge: false,
                      ),
                    ),
                  if (_currentQuestion > 0)
                    const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: CustomButton(
                      text: _currentQuestion < _questions.length - 1 ? 'Lanjut' : 'Selesai',
                      onPressed: _nextQuestion,
                      isLarge: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    final isOddQuestion = index % 2 == 0;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pertanyaan ${index + 1} dari ${_questions.length}',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          Text(
            question['question']!,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            isOddQuestion ? question['positive']! : question['negative']!,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXXL),
          
          // Emoji buttons
          Wrap( // Gunakan Wrap agar lebih aman di layar kecil
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(
              _emojis.length,
              (i) => GestureDetector(
                onTap: () => _selectAnswer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    color: _answers[index] == i
                        ? AppColors.primaryBlue.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    border: Border.all(
                      color: _answers[index] == i
                          ? AppColors.primaryBlue
                          : AppColors.neutralGrey,
                      width: _answers[index] == i ? 2 : 1,
                    ),
                    boxShadow: _answers[index] == i ? [] : [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Column(
                    children: [
                      Text(
                        _emojis[i],
                        style: const TextStyle(fontSize: 35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _labels[i],
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: _answers[index] == i ? FontWeight.bold : FontWeight.normal,
                          color: _answers[index] == i ? AppColors.primaryBlue : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}