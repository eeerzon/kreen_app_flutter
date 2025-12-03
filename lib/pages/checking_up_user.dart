import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

class CheckingUpUserPage extends StatefulWidget {
  const CheckingUpUserPage({super.key});

  @override
  State<CheckingUpUserPage> createState() => _CheckingUpUserPageState();
}

class _CheckingUpUserPageState extends State<CheckingUpUserPage> {
  String login = "";
  String guest = "";
  List<Map<String, dynamic>> pages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent('id');
    });
  }

  Future<void> _loadContent (String langCode) async {
    final data = await LangService.loadOnboarding(langCode);
    setState(() {
      pages = data;
    });
  }

  @override

  Widget build(Object context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            SizedBox(height: 32),
            Image.asset(
              'assets/images/img_onboarding3.png',
              height: 250,
              fit: BoxFit.contain,
            ),

            SizedBox(height: 32),
            Text(
              pages[0]["title"]!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),
            Text(
              pages[0]["desc"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red,
              ),
              onPressed: _goToLogin,
              child: Text(
                'Masuk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

            SizedBox(height: 12),

            TextButton(
            onPressed: _goToHome,
            child: Text(
                'Mstuk sebagai Tamu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), 
              )
            )
          ],
        ),
      ),
    );
  }



  void _goToLogin() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  void _goToHome() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }
}