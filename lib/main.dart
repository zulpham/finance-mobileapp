import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'controllers/transaction_controller.dart';
import 'screens/home_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/form_transaction.dart';
import 'screens/saving_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };

    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    runApp(const MyApp());
  }, (error, stack) {
    debugPrint("CRITICAL ERROR: $error");
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionController()),
      ],
      child: MaterialApp(
        title: 'Personal Finance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF020617),
        ),
        themeMode: _themeMode,
        home: MainContainer(
          currentThemeMode: _themeMode,
          onThemeChanged: _toggleTheme,
        ),
      ),
    );
  }
}

class MainContainer extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(bool) onThemeChanged;

  const MainContainer({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeScreen(
        currentThemeMode: widget.currentThemeMode,
        onThemeChanged: widget.onThemeChanged,
      ),
      const DetailScreen(),
      const SavingsScreen(),
    ];

    final isDark = widget.currentThemeMode == ThemeMode.dark;

    return Scaffold(
      // Body mengikuti tab yang dipilih
      body: _pages[_currentIndex],

      // TOMBOL (+) DIPINDAH KE POJOK KANAN BAWAH
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionForm()),
          );
        },
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      )
          : null,

      // POSISI DIUBAH KE endFloat AGAR DI POJOK
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) => setState(() => _currentIndex = index),
        // Warna background navigasi menyesuaikan tema
        backgroundColor: isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.white.withOpacity(0.8),
        elevation: 0,
        indicatorColor: Colors.blueAccent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Ringkasan'
          ),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Riwayat'
          ),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Tabungan'
          ),
        ],
      ),
    );
  }
}