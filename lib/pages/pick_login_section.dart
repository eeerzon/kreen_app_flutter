// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/session_manager.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class PickLoginSection extends StatefulWidget {
  const PickLoginSection({super.key});

  @override
  State<PickLoginSection> createState() => _PickLoginSectionState();
}

class _PickLoginSectionState extends State<PickLoginSection> {
  
  Map<String, dynamic> bahasa = {};
  List<Map<String, dynamic>> pages = [];

  String? langCode;

  @override
  void initState() {
    super.initState();
    _getBahasa();
  }

  Future<void> _getBahasa() async {
    langCode = await StorageService.getLanguage() ?? 'id';
    final tempBahasa = await LangService.getJsonData(langCode!, "bahasa");

    final data = await LangService.loadOnboarding(langCode!);

    if (!mounted) return;
    setState(() {
      bahasa = tempBahasa;
      pages = data;
    });
  }

  Future<void> _setOnboardingDone() async {
    await StorageService.setOnboardingDone(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(bahasa['top_nav'] ?? 'Selamat Datang di Kreen'),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: kGlobalPadding,
          child: Column(
            children: [
              // tengah — image, title, desc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/img_onboarding3.png',
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pages[0]["title"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      pages[0]["desc"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // bawah — buttons
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  _setOnboardingDone();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Text(
                  bahasa['login'] ?? 'Login',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                onPressed: () {
                  _setOnboardingDone();
                  SessionManager.isGuest = true;
                  SessionManager.checkingUserModalShown = true;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                },
                child: Text(
                  bahasa['guest_login'] ?? 'Lanjut sebagai Tamu',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}