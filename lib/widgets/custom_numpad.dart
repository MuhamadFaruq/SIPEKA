import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class CustomNumpad extends StatefulWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final String submitLabel;

  const CustomNumpad({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onSubmit,
    this.submitLabel = "SIMPAN TRANSAKSI",
  });

  @override
  State<CustomNumpad> createState() => _CustomNumpadState();
}

class _CustomNumpadState extends State<CustomNumpad> {
  Timer? _deleteTimer;

  void _startDeleteTimer() {
    widget.onDelete();
    _deleteTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      widget.onDelete();
    });
  }

  void _stopDeleteTimer() {
    _deleteTimer?.cancel();
  }

  @override
  void dispose() {
    _stopDeleteTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNumRow(context, ['1', '2', '3']),
          const SizedBox(height: 10),
          _buildNumRow(context, ['4', '5', '6']),
          const SizedBox(height: 10),
          _buildNumRow(context, ['7', '8', '9']),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildNumKey(context, '000'),
              const SizedBox(width: 10),
              _buildNumKey(context, '0'),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTapDown: (_) => _startDeleteTimer(),
                    onTapUp: (_) => _stopDeleteTimer(),
                    onTapCancel: () => _stopDeleteTimer(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.backspace_outlined,
                          color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onSubmit,
                child: Text(
                  widget.submitLabel,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumRow(BuildContext context, List<String> keys) {
    return Row(children: [
      _buildNumKey(context, keys[0]),
      const SizedBox(width: 10),
      _buildNumKey(context, keys[1]),
      const SizedBox(width: 10),
      _buildNumKey(context, keys[2])
    ]);
  }

  Widget _buildNumKey(BuildContext context, String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onKeyPressed(key),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              key,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
