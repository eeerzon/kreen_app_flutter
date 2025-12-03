import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/content_order/order_event.dart';
import 'package:kreen_app_flutter/pages/content_order/order_vote.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin{
  late TabController _tabController;
  String? token;

  int _selectedIndex = 0;

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    if (mounted) {
      setState(() {
        token = storedToken;
      });
    }
  }

  final List<Widget> _pages = [
    OrderVote(),
    OrderEvent(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkToken();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text("History Transaksi"),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 4) / 2;

                return ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  borderColor: Colors.red.shade200,
                  selectedBorderColor: Colors.red,
                  selectedColor: Colors.white,
                  fillColor: Colors.red,
                  color: Colors.grey,
                  renderBorder: true,
                  isSelected: [_selectedIndex == 0, _selectedIndex == 1],
                  onPressed: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  constraints: BoxConstraints(
                    minHeight: 40,
                    minWidth: buttonWidth,
                  ),
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_vote_rounded),
                        SizedBox(width: 6),
                        Text("Vote"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_rounded),
                        SizedBox(width: 6),
                        Text("Event"),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: token == null 
          ? getLoginUser()
          : _pages[_selectedIndex],
      ),
    );
  }

  Widget getLoginUser() {
    return Container(
      padding: kGlobalPadding,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              "assets/images/img_ovo30d.png",
              height: 60,
              width: 60,
            )
          ),

          const SizedBox(height: 24),
          const Text(
            "Ayo... Login terlebih Dahulu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),
          const Text(
            "Klik tombol dibawah ini untuk menuju halaman Login",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LoginPage(notLog: true,)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              elevation: 2,
            ),
            child: const Text(
              "Login Sekarang",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
