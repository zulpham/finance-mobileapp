import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_controller.dart';
import 'home_screen.dart'; // Untuk formatCurrency

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  // --- DIALOG KONFIRMASI RESET KHUSUS ---
  Future<void> _showResetConfirmation(BuildContext context) async {
    final TextEditingController confirmController = TextEditingController();
    final controller = Provider.of<TransactionController>(context, listen: false);

    return showDialog(
      context: context,
      barrierDismissible: false, // User harus memilih tombol, tidak bisa klik luar
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text("HAPUS SEMUA DATA?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tindakan ini akan menghapus seluruh riwayat transaksi dan kategori secara permanen.\n\nUntuk melanjutkan, ketik: RESET DATA",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "RESET DATA",
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                // VALIDASI INPUT PENGGUNA
                if (confirmController.text == "RESET DATA") {
                  Navigator.pop(ctx); // Tutup dialog

                  // Eksekusi Reset
                  await controller.resetData();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Semua data berhasil direset ke pengaturan awal."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Konfirmasi salah. Reset dibatalkan."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("HAPUS SEKARANG"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionController>(
      builder: (context, controller, child) {
        final int balance = controller.savingsBalance;
        final int lastMonthFlow = controller.lastMonthNetFlow;
        final bool isPositiveFlow = lastMonthFlow >= 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Tabungan & Data"),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView( // Agar bisa discroll di layar kecil
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. CONTAINER UTAMA: SALDO TABUNGAN
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tabungan Saya :",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Rp ${formatCurrency(balance)}",
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // 2. CONTAINER INFO: TRANSAKSI BULAN LALU
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.history, color: Colors.grey[700], size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Transaksi Bulan Kemarin", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              "${isPositiveFlow ? '+' : '-'} Rp ${formatCurrency(lastMonthFlow.abs())}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isPositiveFlow ? Colors.green : Colors.red
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // -------------------------------------------------------------
                // 3. BAGIAN PENGATURAN DATA (NEW)
                // -------------------------------------------------------------
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text("Migrasi & Pengaturan Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),

                // TOMBOL EKSPOR (JSON)
                ListTile(
                  onTap: () async {
                    await controller.exportDatabase();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File JSON siap dibagikan/disimpan.")));
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  tileColor: Colors.white,
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.upload, color: Colors.white)),
                  title: const Text("Ekspor Database", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Backup data ke file JSON"),
                  trailing: const Icon(Icons.chevron_right),
                ),

                const SizedBox(height: 10),

                // TOMBOL IMPOR (JSON)
                ListTile(
                  onTap: () async {
                    try {
                      await controller.importDatabase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Data berhasil dipulihkan dari file JSON!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Gagal mengimpor data. Pastikan format file benar.")),
                        );
                      }
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  tileColor: Colors.white,
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.download, color: Colors.white)),
                  title: const Text("Impor Database", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Restore data dari file JSON"),
                  trailing: const Icon(Icons.chevron_right),
                ),

                const SizedBox(height: 30),

                // TOMBOL RESET DATA (BAHAYA)
                ListTile(
                  onTap: () => _showResetConfirmation(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200)),
                  tileColor: Colors.red.shade50,
                  leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.delete_forever, color: Colors.white)),
                  title: const Text("Reset Semua Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: const Text("Hapus permanen semua data"),
                  trailing: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                ),

                const SizedBox(height: 40), // Spasi bawah agar tidak mentok
              ],
            ),
          ),
        );
      },
    );
  }
}