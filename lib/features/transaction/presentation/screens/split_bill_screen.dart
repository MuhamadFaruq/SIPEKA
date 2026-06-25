import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:sipeka/core/services/ai_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/services/ocr_helper.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class SplitBillItem {
  final String id;
  String name;
  double price;
  List<String> assignedTo; // List nama teman

  SplitBillItem({
    required this.id,
    required this.name,
    required this.price,
    required this.assignedTo,
  });
}

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _friends = [];
  final List<SplitBillItem> _items = [];
  
  double _tax = 0.0;
  double _service = 0.0;
  
  final TextEditingController _friendNameController = TextEditingController();
  final TextEditingController _paymentDetailsController = TextEditingController(
    text: "Transfer Bank BCA\nNo. Rekening: 123456789\na.n. Muhamad Faruq",
  );
  
  bool _isLoading = false;
  String _loadingMessage = "";

  void _addFriend() {
    final name = _friendNameController.text.trim();
    if (name.isEmpty) return;
    
    if (_friends.any((f) => f.toLowerCase() == name.toLowerCase())) {
      SipekaNotification.showWarning(context, "Nama teman sudah ada!");
      return;
    }
    
    setState(() {
      _friends.add(name);
      _friendNameController.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _removeFriend(String name) {
    setState(() {
      _friends.remove(name);
      // Hapus alokasi teman ini di setiap item
      for (var item in _items) {
        item.assignedTo.remove(name);
      }
    });
  }

  void _addNewManualItem() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Tambah Item Baru", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: "Nama Item",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: "Harga (Rp)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: "Rp ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              
              if (name.isEmpty || price <= 0) {
                SipekaNotification.showWarning(context, "Harap masukkan nama dan harga yang valid!");
                return;
              }

              setState(() {
                _items.add(SplitBillItem(
                  id: const Uuid().v4(),
                  name: name,
                  price: price,
                  assignedTo: [],
                ));
              });
              
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
            },
            child: const Text("TAMBAH", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editItem(SplitBillItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Item", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: "Nama Item",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: "Harga (Rp)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: "Rp ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              
              if (name.isEmpty || price <= 0) {
                SipekaNotification.showWarning(context, "Harap masukkan nama dan harga yang valid!");
                return;
              }

              setState(() {
                item.name = name;
                item.price = price;
              });
              
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
            },
            child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleFriendForItem(SplitBillItem item, String friendName) {
    if (_friends.isEmpty) {
      SipekaNotification.showWarning(context, "Tambahkan nama teman terlebih dahulu di bagian atas!");
      return;
    }
    setState(() {
      if (item.assignedTo.contains(friendName)) {
        item.assignedTo.remove(friendName);
      } else {
        item.assignedTo.add(friendName);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _toggleAllFriendsForItem(SplitBillItem item) {
    if (_friends.isEmpty) {
      SipekaNotification.showWarning(context, "Tambahkan nama teman terlebih dahulu!");
      return;
    }
    setState(() {
      if (item.assignedTo.length == (_friends.length + 1)) {
        item.assignedTo.clear();
      } else {
        item.assignedTo.clear();
        item.assignedTo.add("Saya");
        item.assignedTo.addAll(_friends);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _triggerScan(ImageSource source) async {
    try {
      HapticFeedback.mediumImpact();
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 1080,
        maxHeight: 1920,
      );

      if (image != null) {
        _processCropAndOcr(image);
      }
    } catch (e) {
      debugPrint("Error camera/gallery picker: $e");
      if (mounted) {
        SipekaNotification.showWarning(context, "Gagal mengakses kamera/galeri.");
      }
    }
  }

  void _processCropAndOcr(XFile image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fokuskan pada Item & Harga',
          toolbarColor: AppColors.primaryBlue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Fokuskan pada Item & Harga',
          doneButtonTitle: 'Selesai',
          cancelButtonTitle: 'Batal',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Membaca struk belanja...";
    });

    try {
      final rawText = await OCRHelper.extractFullText(croppedFile.path);
      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception("Gagal mengekstrak teks dari struk.");
      }

      setState(() {
        _loadingMessage = "Memproses item menggunakan AI...";
      });

      final aiItems = await AiService().parseReceiptToItems(rawText);
      if (aiItems == null || aiItems.isEmpty) {
        throw Exception("AI tidak dapat mengidentifikasi daftar item belanja.");
      }

      setState(() {
        for (var item in aiItems) {
          final name = item['name']?.toString() ?? 'Item Tanpa Nama';
          final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
          if (price > 0) {
            _items.add(SplitBillItem(
              id: const Uuid().v4(),
              name: name,
              price: price,
              assignedTo: [],
            ));
          }
        }
      });
      
      if (mounted) {
        SipekaNotification.showSuccess(context, "Berhasil memindai ${_items.length} item!");
      }
    } catch (e) {
      debugPrint("Error Split Bill OCR: $e");
      if (mounted) {
        SipekaNotification.showWarning(context, e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = "";
      });
    }
  }

  // Menghitung draf patungan
  Map<String, double> _calculateSplitDetails() {
    final Map<String, double> personBalances = {};
    
    // Inisialisasi saldo untuk setiap teman (termasuk pemilik, diasumsikan sebagai "Saya")
    personBalances["Saya"] = 0.0;
    for (var f in _friends) {
      personBalances[f] = 0.0;
    }

    double subtotal = 0.0;
    for (var item in _items) {
      subtotal += item.price;
      
      // Jika item tidak di-assign ke siapapun, bagi rata ke semua orang
      List<String> assignees = List.from(item.assignedTo);
      if (assignees.isEmpty) {
        assignees.add("Saya");
        assignees.addAll(_friends);
      }

      final share = item.price / assignees.length;
      for (var person in assignees) {
        personBalances[person] = (personBalances[person] ?? 0.0) + share;
      }
    }

    // Kalkulasi pajak dan biaya layanan secara proporsional
    final double totalExtra = _tax + _service;
    if (subtotal > 0 && totalExtra > 0) {
      final ratio = 1 + (totalExtra / subtotal);
      personBalances.forEach((key, value) {
        personBalances[key] = value * ratio;
      });
    }

    return personBalances;
  }

  void _shareViaWhatsApp() {
    if (_items.isEmpty) {
      SipekaNotification.showWarning(context, "Tambahkan item belanja terlebih dahulu!");
      return;
    }

    final splitDetails = _calculateSplitDetails();
    double grandTotal = 0.0;
    splitDetails.forEach((_, val) => grandTotal += val);

    final formatter = NumberFormat.decimalPattern('id');
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln("🧾 *TAGIHAN PATUNGAN (SPLIT BILL)*");
    buffer.writeln("Aplikasi Pencatatan Keuangan SIPEKA\n");
    
    buffer.writeln("🛍️ *Rincian Belanja:*");
    for (var item in _items) {
      buffer.write("- ${item.name}: Rp ${formatter.format(item.price.toInt())}");
      if (item.assignedTo.isNotEmpty) {
        buffer.write(" (${item.assignedTo.join(', ')})");
      } else {
        buffer.write(" (Semua)");
      }
      buffer.writeln();
    }
    
    if (_tax > 0 || _service > 0) {
      buffer.writeln("\n➕ *Biaya Tambahan:*");
      if (_tax > 0) buffer.writeln("- Pajak (Tax): Rp ${formatter.format(_tax.toInt())}");
      if (_service > 0) buffer.writeln("- Biaya Layanan: Rp ${formatter.format(_service.toInt())}");
    }

    buffer.writeln("\n💰 *Rincian Pembayaran Per Orang:*");
    buffer.writeln("-----------------------------------------");
    splitDetails.forEach((name, total) {
      if (total > 0) {
        buffer.writeln("👤 *$name* : *Rp ${formatter.format(total.toInt())}*");
      }
    });
    buffer.writeln("-----------------------------------------");
    buffer.writeln("*Total Keseluruhan: Rp ${formatter.format(grandTotal.toInt())}*\n");

    if (_paymentDetailsController.text.trim().isNotEmpty) {
      buffer.writeln("💳 *Tujuan Transfer:*");
      buffer.writeln(_paymentDetailsController.text.trim());
      buffer.writeln();
    }
    
    buffer.write("Terima kasih! Dicatat otomatis dengan SIPEKA AI.");

    // ignore: deprecated_member_use
    Share.share(buffer.toString());
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.decimalPattern('id');
    
    // Kalkulasi subtotal
    double subtotal = _items.fold(0.0, (sum, item) => sum + item.price);
    double grandTotal = subtotal + _tax + _service;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Split Bill AI",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: PEMINDAI STRUK
                _buildSectionHeader("1. PINDAI STRUK BELANJA (AI OCR)"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: "Kamera Struk",
                        color: AppColors.primaryBlue,
                        onPressed: () => _triggerScan(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library_rounded,
                        label: "Galeri Foto",
                        color: Colors.green,
                        onPressed: () => _triggerScan(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION 2: TAMBAH ANGGOTA
                _buildSectionHeader("2. ANGGOTA YANG IKUT PATUNGAN"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _friendNameController,
                        style: GoogleFonts.nunito(),
                        decoration: InputDecoration(
                          hintText: "Nama Teman (misal: Andi, Budi)",
                          hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) => _addFriend(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _addFriend,
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Horizontal list of friends
                if (_friends.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _friends.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final name = _friends[idx];
                        return Chip(
                          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          labelStyle: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                          label: Text(name),
                          deleteIcon: const Icon(Icons.cancel, size: 14, color: AppColors.primaryBlue),
                          onDeleted: () => _removeFriend(name),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Text(
                    "Belum ada teman ditambahkan. (Secara default akan dibagi rata dengan Anda)",
                    style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 24),

                // SECTION 3: RINCIAN ITEM BELANJA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader("3. DAFTAR BARANG & ALOKASI"),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text("Tambah Manual", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _addNewManualItem,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  _buildEmptyItemsState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildItemCard(item, formatter);
                    },
                  ),
                const SizedBox(height: 24),

                // SECTION 4: BIAYA TAMBAHAN & PEMBAYARAN
                _buildSectionHeader("4. BIAYA TAMBAHAN & REKENING"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.nunito(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: "Pajak (Tax)",
                          labelStyle: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
                          prefixText: "Rp ",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _tax = double.tryParse(val.trim()) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.nunito(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: "Biaya Layanan (Service)",
                          labelStyle: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
                          prefixText: "Rp ",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _service = double.tryParse(val.trim()) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _paymentDetailsController,
                  maxLines: 3,
                  style: GoogleFonts.nunito(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: "Informasi Rekening / Pembayaran",
                    labelStyle: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 5: RINGKASAN & ACTION
                _buildSectionHeader("5. RINGKASAN PATUNGAN"),
                const SizedBox(height: 10),
                _buildSummaryCard(formatter, subtotal, grandTotal),
                const SizedBox(height: 30),
                
                // Tombol Bagikan
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    label: Text(
                      "BAGIKAN RINCIAN TAGIHAN",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: _shareViaWhatsApp,
                  ),
                ),
                const SizedBox(height: 60), // Space di bawah
              ],
            ),
          ),
          if (_isLoading)
            _buildLoadingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: GoogleFonts.nunito(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            "Belum ada item",
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            "Gunakan tombol Pindai Struk di atas atau Tambah Manual untuk mengisi item.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(SplitBillItem item, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Detail Item & Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Rp ${formatter.format(item.price.toInt())}",
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _editItem(item);
                  } else if (val == 'delete') {
                    setState(() {
                      _items.removeWhere((i) => i.id == item.id);
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text("Edit", style: GoogleFonts.nunito(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text("Hapus", style: GoogleFonts.nunito(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Baris 2: Pemilih Alokasi Anggota
          Text(
            "Dibayar oleh:",
            style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Chip untuk pemilik ("Saya")
              GestureDetector(
                onTap: () => _toggleFriendForItem(item, "Saya"),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.assignedTo.contains("Saya")
                        ? AppColors.primaryBlue
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Saya",
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.assignedTo.contains("Saya") ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
              
              // Chip untuk teman-teman
              ..._friends.map((friendName) {
                final isSelected = item.assignedTo.contains(friendName);
                return GestureDetector(
                  onTap: () => _toggleFriendForItem(item, friendName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      friendName,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                );
              }),

              // Tombol Pilih Semua / Bagi Rata
              GestureDetector(
                onTap: () => _toggleAllFriendsForItem(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.assignedTo.length == (_friends.length + 1)
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.assignedTo.length == (_friends.length + 1)
                          ? Colors.orange
                          : Colors.transparent,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    item.assignedTo.length == (_friends.length + 1) ? "Batalkan Semua" : "Bagi Semua",
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.assignedTo.length == (_friends.length + 1) ? Colors.orange : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat formatter, double subtotal, double grandTotal) {
    final splitDetails = _calculateSplitDetails();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal", style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey)),
              Text("Rp ${formatter.format(subtotal.toInt())}", style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          if (_tax > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pajak (Tax)", style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey)),
                Text("Rp ${formatter.format(_tax.toInt())}", style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (_service > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Biaya Layanan", style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey)),
                Text("Rp ${formatter.format(_service.toInt())}", style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const Divider(height: 20, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Keseluruhan", style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                "Rp ${formatter.format(grandTotal.toInt())}",
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Hasil Patungan Per Orang:",
            style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          
          // Tampilkan per orang
          ...splitDetails.entries.map((entry) {
            if (entry.value <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(entry.key, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(
                    "Rp ${formatter.format(entry.value.toInt())}",
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
