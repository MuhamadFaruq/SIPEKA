import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/features/insight/presentation/controllers/financial_health_provider.dart';
import 'package:sipeka/features/transaction/presentation/widgets/transaction_pie_chart.dart';
import 'package:sipeka/features/transaction/presentation/screens/ai_chat_screen.dart';
import 'package:sipeka/features/transaction/presentation/screens/split_bill_screen.dart';


class FinancialInsightTabCard extends StatefulWidget {
  const FinancialInsightTabCard({super.key});

  @override
  State<FinancialInsightTabCard> createState() =>
      _FinancialInsightTabCardState();
}

class _FinancialInsightTabCardState extends State<FinancialInsightTabCard> {
  int _activeTab = 0;
  late final PageController _pageController;


  static const List<_TabMeta> _tabs = [
    _TabMeta(
      icon: Icons.favorite_rounded,
      label: 'Kesehatan',
      gradientStart: Color(0xFF007AFF),
      gradientEnd: Color(0xFF005BC5),
    ),
    _TabMeta(
      icon: Icons.pie_chart_rounded,
      label: 'Pengeluaran',
      gradientStart: Color(0xFF00C896),
      gradientEnd: Color(0xFF007A5A),
    ),
    _TabMeta(
      icon: Icons.auto_awesome_rounded,
      label: 'Fitur AI',
      gradientStart: Color(0xFF9C40FF),
      gradientEnd: Color(0xFF5A00CC),
    ),
  ];

  static const int _virtualBase = 3000;
  static const int _virtualTotal = 9000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _virtualBase);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _tabs[_activeTab];

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 4),
      child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: active.gradientStart.withOpacity(isDark ? 0.25 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: active.gradientStart.withOpacity(isDark ? 0.3 : 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _virtualTotal,
                    onPageChanged: (i) => setState(() => _activeTab = i % _tabs.length),
                    itemBuilder: (context, index) {
                      final pageIndex = index % _tabs.length;
                      switch (pageIndex) {
                        case 0: return _buildHealthPage(context, isDark);
                        case 1: return _buildSpendingPage(context, isDark);
                        case 2: return _buildAiPage(context, isDark);
                        default: return const SizedBox();
                      }
                    },
                  ),
                ),
                _buildDotIndicators(active),
              ],
            ),
        ),
    );
  }




  Widget _buildDotIndicators(_TabMeta active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tabs.length, (i) {
          final isActive = _activeTab == i;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: isActive
                  ? LinearGradient(
                      colors: [active.gradientStart, active.gradientEnd],
                    )
                  : null,
              color: isActive ? null : Colors.grey.withOpacity(0.3),
            ),
          );
        }),
      ),
    );
  }





  Widget _buildHealthPage(BuildContext context, bool isDark) {
    final healthProvider = Provider.of<FinancialHealthProvider>(context);

    Color scoreColor;
    if (healthProvider.score >= 80) {
      scoreColor = AppColors.incomeGreen;
    } else if (healthProvider.score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = AppColors.expenseRed;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Health Gauge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 40,
                lineWidth: 7,
                percent: healthProvider.score / 100,
                animation: true,
                animateFromLastPercent: true,
                circularStrokeCap: CircularStrokeCap.round,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      healthProvider.score.toStringAsFixed(0),
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Skor',
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                progressColor: scoreColor,
                backgroundColor: Colors.grey.withOpacity(0.15),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  healthProvider.status,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Right: AI Advice bubble card
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded,
                        size: 16, color: Color(0xFF9C40FF)),
                    const SizedBox(width: 6),
                    Text(
                      'SIPEKA AI',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9C40FF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => healthProvider.calculateHealthScore(),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.refresh_rounded,
                            size: 14,
                            color: Colors.grey.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C40FF).withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: const Color(0xFF9C40FF).withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: healthProvider.isLoading
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: const LinearProgressIndicator(
                                    minHeight: 2,
                                    color: Color(0xFF9C40FF),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Membaca laporan bulanan...',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              healthProvider.aiAdvice,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.35,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPage(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Distribusi Pengeluaran',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Expanded(child: TransactionPieChart()),
        ],
      ),
    );
  }

  Widget _buildAiPage(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAiChip('Split Bill AI', Icons.receipt_long_rounded,
                  const Color(0xFF007AFF)),
              const SizedBox(width: 8),
              _buildAiChip('AI Konsultan', Icons.psychology_rounded,
                  const Color(0xFF9C40FF)),
            ],
          ),
          const SizedBox(height: 7),
          Expanded(

            child: Row(
              children: [
                _buildAiFeatureTile(
                  context: context,
                  isDark: isDark,
                  icon: Icons.people_alt_rounded,
                  gradientColors: const [
                    Color(0xFF007AFF),
                    Color(0xFF005BC5)
                  ],
                  title: 'Split Bill AI',
                  subtitle: 'Patungan & scan struk pintar',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SplitBillScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _buildAiFeatureTile(
                  context: context,
                  isDark: isDark,
                  icon: Icons.chat_bubble_rounded,
                  gradientColors: const [
                    Color(0xFF9C40FF),
                    Color(0xFF5A00CC)
                  ],
                  title: 'AI Konsultan',
                  subtitle: 'Solusi keuangan personal',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeatureTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(isDark ? 0.18 : 0.09),
                gradientColors[1].withOpacity(isDark ? 0.10 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradientColors[0].withOpacity(isDark ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabMeta {
  final IconData icon;
  final String label;
  final Color gradientStart;
  final Color gradientEnd;

  const _TabMeta({
    required this.icon,
    required this.label,
    required this.gradientStart,
    required this.gradientEnd,
  });
}
