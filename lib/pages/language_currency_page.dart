// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/pick_login_section.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class LanguageCurrencyPage extends StatefulWidget {
  const LanguageCurrencyPage({super.key});

  @override
  State<LanguageCurrencyPage> createState() => _LanguageCurrencyPageState();
}

class _LanguageCurrencyPageState extends State<LanguageCurrencyPage> {
  String _selectedLang = 'id';
  String _selectedCurrency = 'IDR';
  Map<String, dynamic> bahasa = {};

  String? langCode;
  bool? changed;
  String? currencyCode;

  @override
  void initState() {
    super.initState();
    _getBahasa();
  }

  Future<void> _getBahasa() async {
    langCode = await StorageService.getLanguage() ?? 'id';
    final currency = await StorageService.getCurrency() ?? 'IDR';
    final tempBahasa = await LangService.getJsonData(langCode!, "bahasa");

    await StorageService.setCurrency(currency);
    await StorageService.setIsChoosed(1);

    if (!mounted) return;
    setState(() {
      _selectedLang = langCode!;
      _selectedCurrency = currency;
      bahasa = tempBahasa;
    });
  }

  Future<void> _save() async {
    await StorageService.setLanguage(_selectedLang);
    await StorageService.setCurrency(_selectedCurrency);
    langNotifier.value = _selectedLang;
    currencyCode = _selectedCurrency;

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PickLoginSection()),
    );
  }

  Future<bool?> _showLanguageDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        String tempLang = langCode!;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bahasa['pick_language'] ?? 'Pilih Bahasa'),
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
                        if (val != null) {
                          setState(() {
                            langCode = val; 
                            langNotifier.value = val; // update global
                            _selectedLang = val; // update local
                          });
                          await StorageService.setLanguage(val);
                          // Navigator.pushAndRemoveUntil(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => const HomePage()),
                          //   (route) => false,
                          // );

                          Navigator.pop(context, true);
                        }
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

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempCurr = currencyCode ?? '';
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bahasa['pick_currency'] ?? 'Pilih Mata Uang'),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: currencies.entries.map((entry) {
                    return RadioListTile<String>(
                      value: entry.key,
                      groupValue: tempCurr,
                      onChanged: (val) async {

                        if (val == null) return;
                        setState(() {
                          userCurrency = val;
                          currencyCode = val;
                          isChoosed = 1;

                          _selectedCurrency = val;
                        });

                        await StorageService.setCurrency(val);
                        await StorageService.setIsChoosed(1);

                        Navigator.pop(context, true);
                      },
                      title: Row(
                        children: [
                          Image.asset(
                            "assets/currencies/${entry.key.toString().toLowerCase()}.png", // simpan currency di folder assets/currencies
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(entry.value),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: kGlobalPadding,
          child: Column(
            children: [
              const Spacer(),

              // ilustrasi
              Image.asset(
                'assets/images/img_picklanguage.png', // ganti sesuai asset kamu
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 100, color: Colors.grey),
              ),

              const SizedBox(height: 32),
              Text(
                bahasa['pick_lang_title'] ?? 'Kamu belum menentukan\nbahasa dan mata uang',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                bahasa['pick_lang_desc'] ?? 'Silahkan pilih bahasa dan mata uang\nsebelum melanjutkan',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Pilih Bahasa
              GestureDetector(
                onTap: () async {
                  changed = await _showLanguageDialog();

                  if (changed == true) {
                    setState(() {
                      _getBahasa();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset("assets/flags/$_selectedLang.png", width: 24, height: 24,
                        errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(languages[_selectedLang] ?? bahasa['pick_language'] ?? 'Pilih Bahasa')),
                      const Icon(Icons.translate, color: Colors.blue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Pilih Mata Uang
              GestureDetector(
                onTap: _showCurrencyDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCurrency.isEmpty
                            ? (bahasa['pick_currency'] ?? 'Pilih Mata Uang')
                            : "$_selectedCurrency - ${currencies[_selectedCurrency] ?? ''}",
                        ),
                      ),
                      const Icon(Icons.monetization_on, color: Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Simpan dan Lanjutkan
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _save,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${bahasa['simpan'] ?? 'Simpan'} ${bahasa['dan'] ?? 'dan'} ${bahasa['lanjutkan'] ?? 'Lanjutkan'}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}