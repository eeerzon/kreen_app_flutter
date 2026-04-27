// ignore_for_file: non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, unused_field

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/language_currency_page.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import '/services/lang_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final prefs = FlutterSecureStorage();

  List<Map<String, dynamic>> pages = [];
  String? lewati;
  String? lanjut;
  String? langCode;

  String _selectedLang = langNotifier.value;
  final Map<String, String> languages = {
    "id": "Indonesia",
    "en": "English"
  };
  String? currencyCode;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      _selectedLang = langCode!;
      await _getCurrency();
      await _loadLanguage(langCode ?? "id");
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage() ?? "id";

    setState(() {
      langCode = code;
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency() ?? "IDR";
    await StorageService.setCurrency(code);

    setState(() {
      currencyCode = code;
    });
  }

  //setting bahasa
  Future<void> _loadLanguage(String langCode) async {
    await StorageService.setLanguage(langCode);

    langNotifier.value = langCode;

    final onboarding = await LangService.loadOnboarding(langCode);
    final tempbahasa = await LangService.getJsonData(langCode, "bahasa");

    if (!mounted) return;

    setState(() {
      pages = onboarding;
      lewati = tempbahasa['lewati'];
      lanjut = tempbahasa['lanjut'];
    });
  }

  Future<void> _finishOnboarding() async {
    await prefs.write(key: 'hasSeenOnboarding',value:  'true');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LanguageCurrencyPage()),
    );
  }

  void _nextPage() {
    if (_currentPage == pages.length - 1) {
      _finishOnboarding();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [

          //konten page
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (_, index) {
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            pages[index]["image"]!,
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            pages[index]["title"]!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pages[index]["desc"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                )
              ),

              // Bottom controls
              // Navigation bar bawah (hanya tampil kalau bukan halaman terakhir)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lewati
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        lewati ?? "-",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),

                    // Indicator
                    Row(
                      children: List.generate(
                        pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.red
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),

                    // Lanjut
                    TextButton(
                      onPressed: _nextPage,
                      child: Text(
                        lanjut ?? "-",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
