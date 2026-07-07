// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/modal/checking_user_modal.dart';
import 'package:kreen_app_flutter/pages/content_home/explore_page.dart';
import 'package:kreen_app_flutter/pages/content_home/home_content.dart';
import 'package:kreen_app_flutter/pages/content_home/info_page.dart';
import 'package:kreen_app_flutter/pages/content_home/order_page.dart';
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
  
  List<Widget> get _pages => [
    HomeContent(
      onSeeMoreVote: () => _openExplore(1),
      onSeeMoreEvent: () => _openExplore(2),
    ),
    ExplorePage(initialTab: _exploreTabIndex),
    const OrderPage(),
    const InfoPage(),
  ];

  final prefs = FlutterSecureStorage();
  Map<String, dynamic> bahasa = {};
  bool scanFitur = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
    
      if (!mounted) return;
      
      await _getBahasa();
      await _checkToken();
      await getCurrentLocationWithValidation(context);
    });
  }

  Future<void> _getBahasa() async {
    if (!mounted) return;
    final templangCode = await StorageService.getLanguage();
    
    if (!mounted) return;
    setState(() {
      langCode = templangCode;
    });
    
    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    if (!mounted) return;
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
    if (!mounted) return;
    final storedToken = await StorageService.getToken();

    if (!mounted) return;
    if (mounted) {
      setState(() {
        token = storedToken;
      });

      if (token == null &&
          !SessionManager.isGuest &&
          !SessionManager.checkingUserModalShown) {

        SessionManager.checkingUserModalShown = true;

        Future.microtask(() {
          if (!mounted) return;
          CheckingUserModal.show(context, langCode!, false);
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

        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 0,
        ),

        // --- Floating Action Button (scan) ---
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: scanFitur ? Colors.red : Colors.grey,
        //   onPressed: () async {
        //     scanFitur
        //       ? await Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (_) => const ScannerPage()),
        //         )
        //       : ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //             content: Text(bahasa['upcoming']),
        //             behavior: SnackBarBehavior.floating,
        //             margin: const EdgeInsets.only(
        //               left: 16,
        //               right: 16,
        //             ),
        //           ),
        //         );
        //   },
        //   child: const Icon(Icons.qr_code_scanner, size: 40, color: Colors.white),
        // ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // --- Bottom Navigation Bar ---
        bottomNavigationBar: ValueListenableBuilder(
          valueListenable: langNotifier,
          builder: (context, value, _) {

            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _getBahasa();
              });
            }

            return BottomAppBar(
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
                    _buildNavItem(Icons.receipt_long, order ?? "Pesanan", 2),
                    _buildNavItem(Icons.person, info ?? "Info", 3),
                  ],
                ),
              ),
            );
          },
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
      _exploreTabIndex = tabIndex;
      _selectedIndex = 1;
    });
  }

  void _onNavTap(int index) async {

    if (index == 1) {
      _exploreTabIndex = 0;
    }
    
    if (index == 2) {
      final previousIndex = _selectedIndex;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrderPage()),
      );

      if (result == true) {
        await _checkToken();
      }
      
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
