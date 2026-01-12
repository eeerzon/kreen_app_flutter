// ignore_for_file: non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'login_page.dart';
import 'home_page.dart';
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
  String? dialog_title;
  String? lewati;
  String? lanjut;
  String? selesai;
  String? login;
  String? guest;
  String? langCode, currencyCode;

  String _selectedLang = "id";
  final Map<String, String> languages = {
    "id": "Indonesia",
    "en": "English"
  };

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
    StorageService.setLanguage(langCode);

    final onboarding = await LangService.loadOnboarding(langCode);
    final title = await LangService.getText(langCode, "pick_language");
    final lewatiText = await LangService.getText(langCode, "lewati");
    final lanjutText = await LangService.getText(langCode, "lanjut");
    final selesaiText = await LangService.getText(langCode, "selesai");
    final loginText = await LangService.getText(langCode, "login");
    final guestText = await LangService.getText(langCode, "guest_login");

    if (!mounted) return;

    setState(() {
      pages = onboarding;
      dialog_title = title;
      lewati = lewatiText;
      lanjut = lanjutText;
      selesai = selesaiText;
      login = loginText;
      guest = guestText;
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = _selectedLang;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dialog_title ?? '-'),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: languages.entries.map((entry) {
                    return RadioListTile<String>(
                      value: entry.key,
                      groupValue: tempLang,
                      onChanged: (val) async {
                        if (val == null) return;

                        setStateDialog(() {
                          tempLang = val;
                        });

                        await _loadLanguage(val);

                        setState(() {
                          _selectedLang = val;
                        });

                        Navigator.pop(context);
                      },
                      title: Row(
                        children: [
                          Image.asset(
                            "assets/flags/${entry.key}.png", // simpan bendera di folder assets/flags
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(entry.value),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _finishOnboarding() async {
    await prefs.write(key: 'hasSeenOnboarding',value:  'true');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
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

  Future<void> _setOnboardingDone() async {
    await prefs.write(key: 'hasSeenOnboarding',value:  'true');
  }

  void _goToLogin() async {
    await _setOnboardingDone();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goToHome() async {
    await _setOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
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

                          const Spacer(),
                          if (index == pages.length - 1) ...[
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
                                login ?? "-",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _goToHome,
                              child: Text(
                                guest ?? "-",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                )
              ),

              // Bottom controls
              // Navigation bar bawah (hanya tampil kalau bukan halaman terakhir)
              if (_currentPage != pages.length - 1)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          _currentPage == pages.length - 1 ? (selesai ?? "-") : (lanjut ?? "-"),
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

              SizedBox(height: 20,),
            ],
          ),

          
          //bahasa
          Positioned(
            top: 16,
            right: 20,
            child: GestureDetector(
              onTap: _showLanguageDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                Image.asset("assets/flags/$_selectedLang.png",
                    width: 24, height: 24),
                const SizedBox(width: 4),
                Text(
                  _selectedLang.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
