// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/modal/checking_user_modal.dart';
import 'package:kreen_app_flutter/pages/content_home/explore_page.dart';
import 'package:kreen_app_flutter/pages/content_home/home_content.dart';
import 'package:kreen_app_flutter/pages/content_home/info_page.dart';
import 'package:kreen_app_flutter/pages/content_home/order_page.dart';
import 'package:kreen_app_flutter/pages/content_home/scan_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/helper/session_manager.dart';
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
  String? lastPressedMessage;

  int _selectedIndex = 0;
  int _exploreTabIndex = 0;
  // daftar halaman
  List<Widget> get _pages => [
    HomeContent(
      onSeeMoreVote: () => _openExplore(1),
      onSeeMoreEvent: () => _openExplore(2),
    ),   // bikin widget khusus isi Home
    ExplorePage(initialTab: _exploreTabIndex),   // halaman Eksplore
    const OrderPage(),    // halaman Pesanan
    const InfoPage(),      // halaman Info
  ];

  final prefs = FlutterSecureStorage();
  Map<String, dynamic> bahasa = {};
  bool scanFitur = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _checkToken();
      await getCurrentLocationWithValidation(context);();
    });
  }

  Future<void> _getBahasa() async {
    final templangCode = await StorageService.getLanguage();

    // pastikan di-set dulu
    setState(() {
      langCode = templangCode;
    });

    // baru load content
    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
      home = tempbahasa['bot_nav_1'];
      explore = tempbahasa['bot_nav_2'];
      order = tempbahasa['bot_nav_3'];
      info = tempbahasa['bot_nav_4'];

      lastPressedMessage = tempbahasa['lastPressed'];
    });
  }

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();

    if (mounted) {
      setState(() {
        token = storedToken;
      });

      if (token == null &&
          !SessionManager.isGuest &&
          !SessionManager.checkingUserModalShown) {

        SessionManager.checkingUserModalShown = true;

        Future.microtask(() {
          CheckingUserModal.show(context, langCode!);
        });
      }
    }
  }

  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();

        if (lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;
          Fluttertoast.showToast(
            msg: lastPressedMessage!,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
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
          backgroundColor: scanFitur ? Colors.red : Colors.grey,
          onPressed: () async {
            scanFitur
              ? await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerPage()),
                )
              : ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(bahasa['upcoming']),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                    ),
                  ),
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
          _onNavTap(index);
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
  
  void _openExplore(int tabIndex) {
    setState(() {
      _exploreTabIndex = tabIndex; // vote / event
      _selectedIndex = 1;          // tab Explore
    });
  }

  void _onNavTap(int index) async {

    if (index == 1) {
      _exploreTabIndex = 0;
    }
    
    if (index == 2) {
      final previousIndex = _selectedIndex;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrderPage()),
      );

      // setelah OrderPage di-pop
      setState(() {
        _selectedIndex = previousIndex;
      });

    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}
