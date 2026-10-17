import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sipeka/features/debt/presentation/controllers/debt_provider.dart';
import 'package:sipeka/features/debt/domain/entities/debt_entity.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/debt/presentation/screens/debt_history_screen.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/core/services/finance_sync_service.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  bool _isHutangMode = false; 

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeList = provider.debts.where((d) {
      bool matchType = _isHutangMode ? d.type == 'Borrowed' : d.type == 'Lent';
      return matchType && !d.isPaid;
    }).toList();

    final Color themeColor = _isHutangMode ? const Color(0xFFFF5252) : const Color(0xFF00C853);
    final double totalAmount = _isHutangMode ? provider.totalHutang : provider.totalPiutang;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue])),
        ),
        elevation: 0,
        title: Text("Catatan Hutang", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, "Total ${_isHutangMode ? 'Hutang' : 'Piutang'}", totalAmount, themeColor),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isHutangMode ? "Daftar Hutang Aktif" : "Daftar Piutang Aktif", 
                    style: GoogleFonts.nunito(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color 
                    )
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, SmoothPageRoute(child: const DebtHistoryScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, 
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05), 
                            blurRadius: 5
                          )
                        ]
                      ),
                      child: Icon(Icons.history, color: startBlue, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            activeList.isEmpty 
              ? _buildEmptyState("Tidak ada tagihan aktif")
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: activeList.length,
                  itemBuilder: (context, index) => _buildDebtCard(context, activeList[index], themeColor),
                ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDebtDialog(context),
        backgroundColor: startBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Tambah", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.03), 
            blurRadius: 10
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: startBlue.withOpacity(0.1),
                child: Text(debt.name.substring(0,1).toUpperCase(), 
                     style: TextStyle(color: startBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name, style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color 
                    )),
                    if (debt.notes != null && debt.notes!.isNotEmpty)
                      Text(
                        debt.notes!,
                        style: GoogleFonts.nunito(
                          color: isDark ? Colors.white70 : Colors.grey[600], 
                          fontSize: 12, 
                          fontStyle: FontStyle.italic
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text("Dibuat: ${DateFormat('d MMM yyyy').format(debt.date)}", 
                         style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                onSelected: (value) {
                  if (value == 'edit') _showDebtDialog(context, debt: debt);
                  if (value == 'delete') _confirmDelete(context, debt);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text("Edit")])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(debt.amount),
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17, color: color),
              ),
              ElevatedButton(
                onPressed: () => _confirmLunas(context, debt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text("LUNAS", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, double amount, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startBlue, endBlue]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.transparent : Colors.black12, 
                  blurRadius: 10, offset: const Offset(0, 5)
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.nunito(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
                  style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.8), 
              borderRadius: BorderRadius.circular(30)
            ),
            child: Row(
              children: [
                _buildTabButton("Orang hutang ke saya", !_isHutangMode),
                _buildTabButton("Saya hutang ke orang", _isHutangMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isHutangMode = text == "Saya hutang ke orang"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? startBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  void _showDebtDialog(BuildContext context, {Debt? debt}) {
    final bool isEdit = debt != null;
    final nameC = TextEditingController(text: isEdit ? debt.name : "");
    final amountC = TextEditingController(
      text: isEdit ? NumberFormat.decimalPattern('id').format(debt.amount) : ""
    );
    final notesC = TextEditingController(text: isEdit ? debt.notes : "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? "Edit Catatan" : "Tambah Catatan Baru", style: GoogleFonts.nunito(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color
              )),
              const SizedBox(height: 20),
              _buildTextField(context, nameC, "Nama Orang / Toko", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(context, amountC, "Nominal (Rp)", Icons.money, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField(context, notesC, "Catatan Kecil (Opsional)", Icons.notes, maxLines: 2),
              const SizedBox(height: 20),
              _buildSubmitButton(context, isEdit, debt, nameC, amountC, notesC),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: startBlue),
        filled: true, 
        fillColor: Theme.of(context).cardColor, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: isNumber ? (value) {
        if (value.isNotEmpty) {
          String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
          String formatted = NumberFormat.decimalPattern('id').format(int.parse(clean));
          controller.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
        }
      } : null,
    );
  }

  Widget _buildSubmitButton(BuildContext context, bool isEdit, Debt? debt, TextEditingController nameC, TextEditingController amountC, TextEditingController notesC) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(15)),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
          onPressed: () async {
            if (nameC.text.isNotEmpty && amountC.text.isNotEmpty) {
              // Tampilkan loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator()),
              );

              final provider = Provider.of<DebtProvider>(context, listen: false);
              double cleanAmount = double.parse(amountC.text.replaceAll('.', ''));

              try {
                if (isEdit) {
                  await provider.updateDebt(debt!.id, nameC.text, cleanAmount, notesC.text);
                  if (context.mounted) Navigator.pop(context); // Tutup loading dialog
                  if (context.mounted) Navigator.pop(context); // Tutup form/sheet
                  if (context.mounted) SipekaNotification.showSuccess(context, "Berhasil diperbarui!");
                } else {
                  await provider.addDebt(Debt(
                    id: const Uuid().v4(),
                    name: nameC.text,
                    amount: cleanAmount,
                    date: DateTime.now(),
                    type: _isHutangMode ? 'Borrowed' : 'Lent',
                    notes: notesC.text,
                  ));
                  if (context.mounted) Navigator.pop(context); // Tutup loading dialog
                  if (context.mounted) Navigator.pop(context); // Tutup form/sheet
                  if (context.mounted) SipekaNotification.showSuccess(context, "Catatan berhasil disimpan!");
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context); // Tutup loading dialog
                if (context.mounted) SipekaNotification.showWarning(context, "Gagal menyimpan: $e");
              }
            } else {
              SipekaNotification.showWarning(context, "Mohon isi semua data!");
            }
          },
          child: Text(isEdit ? "PERBARUI" : "SIMPAN", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _confirmLunas(BuildContext context, Debt debt) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final syncMode = await FinanceSyncService.instance.getSyncMode();
    final defaultWallet = await FinanceSyncService.instance.getDefaultWallet(context);
    final wallets = walletProvider.wallets;

    String selectedWallet = defaultWallet;
    bool shouldSyncWallet = syncMode != FinanceSyncMode.disabled;
    final bool isHutang = debt.type == 'Borrowed';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Tandai Lunas?", style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHutang
                        ? "Yakin Anda sudah melunasi hutang ke '${debt.name}'?"
                        : "Yakin '${debt.name}' sudah melunasi tagihannya?",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Nominal: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(debt.amount)}",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isHutang ? Colors.redAccent : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (syncMode == FinanceSyncMode.manual) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHutang ? "Potong Saldo Dompet" : "Tambah ke Saldo Dompet",
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Switch(
                          value: shouldSyncWallet,
                          activeThumbColor: const Color(0xFF00C853),
                          onChanged: (val) => setDialogState(() => shouldSyncWallet = val),
                        ),
                      ],
                    ),
                    if (shouldSyncWallet) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: wallets.any((w) => w.name == selectedWallet)
                                ? selectedWallet
                                : (wallets.isNotEmpty ? wallets.first.name : 'Dompet'),
                            isExpanded: true,
                            icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 18),
                            items: (wallets.isNotEmpty ? wallets.map((w) => w.name).toList() : ['Dompet'])
                                .map((name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedWallet = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ] else if (syncMode == FinanceSyncMode.automatic) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isHutang
                                  ? "Saldo otomatis terpotong dari: $defaultWallet"
                                  : "Saldo otomatis masuk ke: $defaultWallet",
                              style: GoogleFonts.nunito(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Provider.of<DebtProvider>(context, listen: false).markAsPaid(debt.id);

                    if (shouldSyncWallet && syncMode != FinanceSyncMode.disabled) {
                      final targetWallet = syncMode == FinanceSyncMode.automatic ? defaultWallet : selectedWallet;
                      await FinanceSyncService.instance.recordDebtTransaction(
                        context: context,
                        debt: debt,
                        walletName: targetWallet,
                      );
                    }

                    if (context.mounted) {
                      final syncMsg = shouldSyncWallet && syncMode != FinanceSyncMode.disabled
                          ? " & saldo dompet diperbarui"
                          : "";
                      SipekaNotification.showSuccess(context, "Berhasil! Catatan dipindahkan ke histori$syncMsg.");
                    }
                  },
                  child: const Text("YA, LUNAS", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Catatan?", style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color
        )),
        content: Text("Yakin ingin menghapus catatan '${debt.name}'?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<DebtProvider>(context, listen: false).deleteDebt(debt.id);
              Navigator.pop(ctx);
              SipekaNotification.showWarning(context, "Catatan telah dihapus");
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(message, style: GoogleFonts.nunito(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
