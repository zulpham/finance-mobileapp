import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_controller.dart';
import 'home_screen.dart'; // Untuk formatCurrency

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  // --- GLASS WRAPPER REUSABLE ---
  Widget _glassWrapper({required Widget child, bool isDark = false, EdgeInsets? margin, EdgeInsets? padding}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(isDark ? 35 : 120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 20),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            color: isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(130),
            child: child,
          ),
        ),
      ),
    );
  }

  // --- DIALOG KONFIRMASI RESET (Gaya Glass) ---
  Future<void> _showResetConfirmation(BuildContext context, bool isDark) async {
    final TextEditingController confirmController = TextEditingController();
    final controller = Provider.of<TransactionController>(context, listen: false);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B).withAlpha(230) : Colors.white.withAlpha(230),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 10),
                Text("RESET DATA?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Tindakan ini akan menghapus semua data secara permanen. Ketik: RESET DATA"),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    hintText: "RESET DATA",
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.black.withAlpha(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () async {
                  if (confirmController.text == "RESET DATA") {
                    Navigator.pop(ctx);
                    await controller.resetData();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text("RESET SEKARANG"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Decor Blobs
          Positioned(
            top: 20, left: -30,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(isDark ? 40 : 60))),
          ),
          Positioned(
            bottom: 100, right: -40,
            child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withAlpha(isDark ? 30 : 50))),
          ),

          SafeArea(
            child: Consumer<TransactionController>(
              builder: (context, controller, child) {
                final int balance = controller.savingsBalance;
                final int lastMonthFlow = controller.lastMonthNetFlow;
                final bool isPositiveFlow = lastMonthFlow >= 0;

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    // Header Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Text("Tabungan & Data", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ),

                    // 1. KARTU SALDO UTAMA (Liquid Gradient)
                    _glassWrapper(
                      isDark: isDark,
                      padding: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withAlpha(isDark ? 100 : 180),
                              Colors.lightBlue.withAlpha(isDark ? 80 : 150),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Tabungan", style: TextStyle(color: isDark ? Colors.white70 : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text("Rp ${formatCurrency(balance)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 20),
                            // Info bulan lalu di dalam kartu
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.history, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text("Bulan Lalu: ", style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                                  Text(
                                    "${isPositiveFlow ? '+' : ''}Rp ${formatCurrency(lastMonthFlow)}",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. BAGIAN PENGATURAN DATA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Text("Pengaturan Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ),

                    // EKSPOR
                    _buildMenuTile(
                      onTap: () => controller.exportDatabase(),
                      icon: Icons.upload_rounded,
                      color: Colors.blue,
                      title: "Ekspor Database",
                      subtitle: "Backup data ke file JSON",
                      isDark: isDark,
                    ),

                    // IMPOR
                    _buildMenuTile(
                      onTap: () => controller.importDatabase(),
                      icon: Icons.download_rounded,
                      color: Colors.green,
                      title: "Impor Database",
                      subtitle: "Restore data dari file JSON",
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),

                    // RESET DATA (Hati-hati)
                    _buildMenuTile(
                      onTap: () => _showResetConfirmation(context, isDark),
                      icon: Icons.delete_forever_rounded,
                      color: Colors.red,
                      title: "Reset Semua Data",
                      subtitle: "Hapus permanen semua histori",
                      isDark: isDark,
                      isDanger: true,
                    ),

                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required VoidCallback onTap, required IconData icon, required Color color, required String title, required String subtitle, required bool isDark, bool isDanger = false}) {
    return _glassWrapper(
      isDark: isDark,
      padding: const EdgeInsets.all(12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(isDark ? 40 : 30), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDanger ? Colors.red : (isDark ? Colors.white : Colors.black87))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}