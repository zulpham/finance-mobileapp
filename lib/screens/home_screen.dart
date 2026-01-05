import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_controller.dart';
import '../models/models.dart';

String formatCurrency(num amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isIncomeSelected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionController>(context, listen: false).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredTransactions = controller.transactions
            .where((tx) => tx.isIncome == _isIncomeSelected)
            .toList();

        final Map<String, double> categoryData = {};
        for (var tx in filteredTransactions) {
          final catName = tx.categoryName ?? 'Lainnya';
          if (categoryData.containsKey(catName)) {
            categoryData[catName] = categoryData[catName]! + tx.amount;
          } else {
            categoryData[catName] = tx.amount.toDouble();
          }
        }

        final double totalAmount = categoryData.values.fold(0, (sum, item) => sum + item);

        final Map<String, Color> categoryColors = {};
        int colorIndex = 0;
        categoryData.keys.forEach((key) {
          categoryColors[key] = Colors.primaries[colorIndex % Colors.primaries.length];
          colorIndex++;
        });

        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 1. HEADER TOGGLE (Pemasukan / Pengeluaran)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Pemasukan", true),
                      _buildTabButton("Pengeluaran", false),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. DROPDOWN FILTER (Semua, Tahun Ini, Bulan Ini)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedFilter,
                        isDense: true,
                        icon: const Icon(Icons.filter_list, size: 20),
                        items: ['Semua', 'Tahun Ini', 'Bulan Ini'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            controller.setFilter(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. CHART SECTION
              SizedBox(
                height: 240,
                child: categoryData.isEmpty
                    ? Center(child: Text("Belum ada data (${controller.selectedFilter})"))
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SimpleDonutChart(
                      data: categoryData,
                      total: totalAmount,
                      colorMap: categoryColors,
                    ),
                    const SizedBox(height: 15),
                    Column(
                      children: [
                        Text(
                          "Total ${_isIncomeSelected ? 'Pemasukan' : 'Pengeluaran'}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          "Rp ${formatCurrency(totalAmount)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _isIncomeSelected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 4. LIST VIEW
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(child: Text("Tidak ada transaksi"))
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: categoryData.length,
                  itemBuilder: (context, index) {
                    String key = categoryData.keys.elementAt(index);
                    double value = categoryData[key]!;
                    Color itemColor = categoryColors[key] ?? Colors.grey;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: itemColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Text(
                              "Rp ${formatCurrency(value)}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTabButton(String title, bool isIncome) {
    bool isSelected = _isIncomeSelected == isIncome;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isIncomeSelected = isIncome),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isIncome ? Colors.green : Colors.red)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleDonutChart extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final Map<String, Color> colorMap;

  const SimpleDonutChart({
    super.key,
    required this.data,
    required this.total,
    required this.colorMap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(160, 160),
      painter: DonutChartPainter(data, total, colorMap),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;
  final Map<String, Color> colorMap;

  DonutChartPainter(this.data, this.total, this.colorMap);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 25.0;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    double startAngle = -pi / 2;

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * pi;
      final color = colorMap[key] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}