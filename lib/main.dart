import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Import Controller
import 'controllers/transaction_controller.dart';

// Import Screens (Pastikan file-file ini ada di folder lib/screens/)
import 'screens/home_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/form_transaction.dart';
import 'screens/saving_screen.dart'; // Menu Tabungan Baru

void main() {
  // Menjalankan aplikasi dalam Zone aman untuk menangkap error async
  runZonedGuarded(() async {
    // 1. Inisialisasi Binding (Wajib di dalam zone jika pakai runZonedGuarded)
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Setup Error Handler Framework (Sinkron)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      runApp(FatalErrorWidget(error: details.exception, stack: details.stack));
    };

    // 3. Inisialisasi Database Factory (Hanya untuk Desktop Non-Web)
    // Ini mencegah error "databaseFactory not initialized" saat debug di Windows/Mac
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    runApp(const MyApp());
  }, (error, stack) {
    // Handler untuk error Asinkron yang lolos (misal error database startup)
    debugPrint("CRITICAL ASYNC ERROR: $error");
    runApp(FatalErrorWidget(error: error, stack: stack));
  });
}

// Widget Tampilan Error (Layar Merah) - Agar error terbaca di HP
class FatalErrorWidget extends StatelessWidget {
  final Object? error;
  final StackTrace? stack;

  const FatalErrorWidget({super.key, this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report, color: Colors.yellow, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "APLIKASI CRASH!",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Text("$error", style: const TextStyle(color: Colors.yellowAccent), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inisialisasi Controller
        // Note: loadTransactions() dipanggil di HomeScreen agar tidak hang saat splash screen
        ChangeNotifierProvider(create: (_) => TransactionController()),
      ],
      child: MaterialApp(
        title: 'Personal Finance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          scaffoldBackgroundColor: Colors.grey[100],
          // Styling Global AppBar
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            iconTheme: IconThemeData(color: Colors.black87),
          ),
        ),
        home: const MainContainer(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN CONTAINER (NAVIGASI BOTTOM BAR)
// ---------------------------------------------------------------------------

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  // Daftar Halaman
  final List<Widget> _pages = const [
    HomeScreen(),    // Index 0: Ringkasan
    DetailScreen(),  // Index 1: Riwayat
    SavingsScreen(), // Index 2: Tabungan (Screen Baru)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman sesuai tab aktif
      body: _pages[_currentIndex],

      // Tombol Tambah (+) hanya muncul di Home (Index 0)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          // Navigasi ke Form Tambah Transaksi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionForm()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Navigasi Bawah
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: Colors.blueAccent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Ringkasan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Tabungan',
          ),
        ],
      ),
    );
  }
}