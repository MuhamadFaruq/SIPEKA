import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/core/constants/constants.dart';

/// Reusable bottom sheet widget untuk memilih ikon dari daftar Material Icons.
/// Menampilkan grid ikon yang dikelompokkan per kategori dengan fitur pencarian.
class IconPickerSheet extends StatefulWidget {
  final int currentIconCode;
  final ValueChanged<IconData> onIconSelected;

  const IconPickerSheet({
    super.key,
    required this.currentIconCode,
    required this.onIconSelected,
  });

  /// Menampilkan IconPickerSheet sebagai modal bottom sheet.
  /// Mengembalikan IconData yang dipilih, atau null jika dibatalkan.
  static Future<IconData?> show(BuildContext context, {required int currentIconCode}) {
    return showModalBottomSheet<IconData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IconPickerSheet(
        currentIconCode: currentIconCode,
        onIconSelected: (icon) => Navigator.pop(ctx, icon),
      ),
    );
  }

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> {
  late int _selectedCode;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.currentIconCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memfilter grouped icons berdasarkan search query
  Map<String, Map<String, IconData>> get _filteredIcons {
    if (_searchQuery.isEmpty) return AppIcons.groupedIcons;

    final result = <String, Map<String, IconData>>{};
    for (final group in AppIcons.groupedIcons.entries) {
      final filtered = Map<String, IconData>.fromEntries(
        group.value.entries.where(
          (e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 group.key.toLowerCase().contains(_searchQuery.toLowerCase()),
        ),
      );
      if (filtered.isNotEmpty) {
        result[group.key] = filtered;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF007AFF);
    final filtered = _filteredIcons;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, Color(0xFF00479E)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconData(_selectedCode, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pilih Ikon",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppIcons.getIconName(_selectedCode),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onIconSelected(
                      IconData(_selectedCode, fontFamily: 'MaterialIcons'),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "PILIH",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cari ikon...",
                hintStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Icon grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          "Tidak ada ikon ditemukan",
                          style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, groupIndex) {
                      final groupName = filtered.keys.elementAt(groupIndex);
                      final icons = filtered[groupName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (groupIndex > 0) const SizedBox(height: 12),
                          // Group header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(
                              groupName,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor.withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Icon grid within group
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: icons.entries.map((entry) {
                              final isSelected = _selectedCode == entry.value.codePoint;
                              return Tooltip(
                                message: entry.key,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCode = entry.value.codePoint);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accentColor
                                          : isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : Colors.grey.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: isSelected
                                          ? Border.all(color: accentColor, width: 2)
                                          : null,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: accentColor.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      entry.value,
                                      color: isSelected
                                          ? Colors.white
                                          : isDark
                                              ? Colors.white70
                                              : Colors.grey[700],
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
