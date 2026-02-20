import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/content_order/order_event.dart';
import 'package:kreen_app_flutter/pages/content_order/order_vote.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin{
  late TabController _tabController;
  String? token, langCode;
  String? appBarTitle;
  String? notLoginText, notLoginDesc, login;

  int _selectedIndex = 0;

  bool isLoading = true;

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    if (mounted) {
      setState(() {
        token = storedToken;

        isLoading = false;
      });
    }
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });
    

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      appBarTitle = tempbahasa['appBarTitle'];
      notLoginText = tempbahasa['notLogin'];
      notLoginDesc = tempbahasa['notLoginDesc'];
      login = tempbahasa['login'];
    });
  }

  final List<Widget> _pages = [
    OrderVote(),
    OrderEvent(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _checkToken();
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
      body: isLoading
        ? _buildSkeletonLoader()
        : _buildKonten(),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKonten() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(appBarTitle!),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () { token == null
              ? Navigator.pop(context)
              : Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
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
            ? KeyedSubtree(
                key: const ValueKey('not-login'),
                child: getLoginUser(),
              )
            : KeyedSubtree(
                key: const ValueKey('logged-in'),
                child: _pages[_selectedIndex],
              ),
      ),
    );
  }

  Widget getLoginUser() {
    return Container(
      width: double.infinity,
      padding: kGlobalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Text(
            notLoginText!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),
          Text(
            notLoginDesc!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(notLog: true),
                ),
              );

              if (result == true) {
                await _checkToken();

                final newToken = await StorageService.getToken();
                if (mounted) {
                  setState(() {
                    token = newToken;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              elevation: 2,
            ),
            child: Text(
              login!,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
