// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/modal/checking_user_modal.dart';
import 'package:kreen_app_flutter/pages/content_home/explore_page.dart';
import 'package:kreen_app_flutter/pages/content_home/home_content.dart';
import 'package:kreen_app_flutter/pages/content_home/info_page.dart';
import 'package:kreen_app_flutter/pages/content_home/order_page.dart';
import 'package:kreen_app_flutter/pages/content_home/scan_page.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class HomePage extends StatefulWidget {
  final bool fromLogout;
  final int initialIndex;

  const HomePage({
    super.key,
    this.fromLogout = false,
    this.initialIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? langCode;
  String? home;
  String? explore;
  String? order;
  String? info;
  String? token;

  int _selectedIndex = 0;
  // daftar halaman
  final List<Widget> _pages = [
    const HomeContent(),   // bikin widget khusus isi Home
    const ExplorePage(),   // halaman Eksplore
    const OrderPage(),    // halaman Pesanan
    const InfoPage(),      // halaman Info
  ];

  final prefs = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // _getBahasa();
    _selectedIndex = widget.initialIndex;

    //sementara
    langCode = 'id';
    _checkToken();
  }

  // Future<void> _getBahasa() async {
  //   langCode = await prefs.read(key: 'bahasa') ?? "id";

  //   final homeContent = await LangService.getJsonData(langCode!, "home_content");

  //   setState(() {
  //     home = homeContent['bot_nav_1'];
  //     explore = homeContent['bot_nav_2'];
  //     order = homeContent['bot_nav_3'];
  //     info = homeContent['bot_nav_4'];
  //   });
  // }

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    if (mounted) {
      setState(() {
        token = storedToken;
        if (token == null && widget.fromLogout == false) {
          Future.microtask(() => CheckingUserModal.show(context, langCode!));  
        }
      });
    }
  }

  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {
    // kalau data bahasa belum siap, tampilkan loading
    // if (home == null || explore == null || order == null || info == null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     showLoadingDialog(context);
    //   });
    //   return const Scaffold(); // kosongin dulu
    // } else {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     hideLoadingDialog(context);
    //   });
    // }

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();

        if (lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 1),
            ),
          );

          return false;
        }

        return true; // keluar dari aplikasi
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 0,
        ),

        // --- Floating Action Button (scan) ---
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScannerPage()),
            );
          },
          child: const Icon(Icons.qr_code_scanner, size: 40, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // --- Bottom Navigation Bar ---
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, home ?? "Home", 0),
                _buildNavItem(Icons.search, explore ?? "Eksplore", 1),
                const SizedBox(width: 40),
                _buildNavItem(Icons.receipt_long, order ?? "Pesanan", 2),
                _buildNavItem(Icons.person, info ?? "Info", 3),
              ],
            ),
          ),
        ),

        body: _pages[_selectedIndex],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderPage()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.red : Colors.grey),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}