import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_controller.dart';

// Helper Format Mata Uang
String formatCurrency(num amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
}

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode
  });

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
    final isDark = widget.currentThemeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
      body: Stack(
        children: [
          // 1. BACKGROUND DECORATION
          Positioned(
            top: -40, right: -20,
            child: _buildBlob(200, isDark ? Colors.blue.withAlpha(40) : Colors.blue.withAlpha(80)),
          ),
          Positioned(
            bottom: 60, left: -30,
            child: _buildBlob(160, isDark ? Colors.purple.withAlpha(30) : Colors.purple.withAlpha(60)),
          ),

          // 2. CONTENT DENGAN SWIPE + ANIMASI SLIDE
          Consumer<TransactionController>(
            builder: (context, controller, child) {
              if (controller.isLoading) return const Center(child: CircularProgressIndicator());

              final filteredTransactions = controller.transactions
                  .where((tx) => tx.isIncome == _isIncomeSelected).toList();

              final Map<String, double> categoryData = {};
              for (var tx in filteredTransactions) {
                final catName = tx.categoryName ?? 'Lainnya';
                categoryData[catName] = (categoryData[catName] ?? 0) + tx.amount;
              }

              final double totalAmount = categoryData.values.fold(0, (sum, item) => sum + item);

              final Map<String, Color> categoryColors = {};
              int colorIndex = 0;
              final List<Color> incomePalette = [Colors.green, Colors.teal, Colors.lightGreen, Colors.cyan, Colors.lime];
              final List<Color> expensePalette = [Colors.red, Colors.orange, Colors.deepOrange, Colors.pink, Colors.amber];
              final List<Color> currentPalette = _isIncomeSelected ? incomePalette : expensePalette;

              for (var key in categoryData.keys) {
                categoryColors[key] = currentPalette[colorIndex % currentPalette.length];
                colorIndex++;
              }

              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    if (_isIncomeSelected) setState(() => _isIncomeSelected = false);
                  }
                  else if (details.primaryVelocity! > 0) {
                    if (!_isIncomeSelected) setState(() => _isIncomeSelected = true);
                  }
                },
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildGlassHeader(isDark, controller),
                      const SizedBox(height: 12),

                      // --- AREA ANIMASI START ---
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutQuart,
                          switchOutCurve: Curves.easeInQuart,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            // Animasi Slide dari samping + Fade
                            final offsetAnimation = Tween<Offset>(
                              begin: Offset(_isIncomeSelected ? -0.2 : 0.2, 0.0),
                              end: const Offset(0.0, 0.0),
                            ).animate(animation);

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              ),
                            );
                          },
                          // Key unik agar Flutter tahu konten berubah dan animasi dijalankan
                          key: ValueKey<bool>(_isIncomeSelected),
                          child: ListView(
                            key: ValueKey<bool>(_isIncomeSelected),
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            children: [
                              _glassWrapper(
                                isDark: isDark,
                                child: Column(
                                  children: [
                                    SimpleDonutChart(
                                      data: categoryData,
                                      total: totalAmount == 0 ? 1 : totalAmount,
                                      colorMap: categoryColors,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      "Total ${_isIncomeSelected ? 'Pemasukan' : 'Pengeluaran'}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                          letterSpacing: 0.5
                                      ),
                                    ),
                                    Text(
                                      "Rp ${formatCurrency(totalAmount)}",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: _isIncomeSelected ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 25),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  "Rincian Kategori",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (categoryData.isEmpty)
                                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Belum ada data")))
                              else
                                ...categoryData.keys.map((key) => _buildGlassTile(key, categoryData[key]!, categoryColors[key]!, isDark)),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      // --- AREA ANIMASI END ---
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- COMPONENT HELPERS TETAP SAMA ---

  Widget _buildGlassHeader(bool isDark, TransactionController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(130),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildTabButton("Pemasukan", true, isDark),
                    _buildTabButton("Pengeluaran", false, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _buildGlassDropdown(isDark, controller),
              ),
              const SizedBox(width: 12),
              _glassWrapper(
                isDark: isDark,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  onPressed: () => widget.onThemeChanged(!isDark),
                  icon: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    color: isDark ? Colors.amber : Colors.orange,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, bool isIncome, bool isDark) {
    bool isSelected = _isIncomeSelected == isIncome;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isIncomeSelected = isIncome),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? (isIncome ? Colors.green : Colors.red) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [BoxShadow(color: (isIncome ? Colors.green : Colors.red).withAlpha(100), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(
            title,
            style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
                fontWeight: FontWeight.bold,
                fontSize: 13
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown(bool isDark, TransactionController controller) {
    return _glassWrapper(
      isDark: isDark,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, size: 18, color: isDark ? Colors.blueAccent : Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedFilter,
                isExpanded: true,
                borderRadius: BorderRadius.circular(20),
                icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white70 : Colors.black54),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white.withAlpha(240),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87
                ),
                items: ['Semua', 'Tahun Ini', 'Bulan Ini'].map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val),
                )).toList(),
                onChanged: (v) => v != null ? controller.setFilter(v) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTile(String key, double value, Color color, bool isDark) {
    return _glassWrapper(
      isDark: isDark,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: color.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color))),
              ),
              const SizedBox(width: 15),
              Text(key, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 15)),
            ],
          ),
          Text(
              "Rp ${formatCurrency(value)}",
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 15)
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _glassWrapper({required Widget child, required bool isDark, EdgeInsets? margin, EdgeInsets? padding}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.white.withAlpha(35) : Colors.white.withAlpha(120),
            width: 1.5
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 25),
              blurRadius: 15,
              offset: const Offset(0, 10)
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
}

// --- CHART COMPONENT TETAP SAMA ---
class SimpleDonutChart extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final Map<String, Color> colorMap;

  const SimpleDonutChart({super.key, required this.data, required this.total, required this.colorMap});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 140),
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
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -pi / 2;
    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * pi;
      final paint = Paint()
        ..color = colorMap[key] ?? Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}