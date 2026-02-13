// ignore_for_file: non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/pages/content_info/help_center.dart';
import 'package:kreen_app_flutter/pages/content_info/privacy_policy.dart';
import 'package:kreen_app_flutter/pages/content_info/profile.dart';
import 'package:kreen_app_flutter/pages/content_info/tentang_page.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/pages/register_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? login, daftar, dialog_language, dialog_currency;
  String? token;

  bool isLoading = true;
  Map<String, dynamic> bahasa = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _checkToken();
    });
  }

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
    
    final tempbahasa = await LangService.getJsonData(langCode!, 'bahasa');

    setState(() {
      bahasa = tempbahasa;
      login = bahasa['login'];
      daftar = bahasa['daftar'];
      dialog_language = bahasa['pick_language'];
      dialog_currency = bahasa['pick_currency'];
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  final Map<String, String> languages = {
    "id": "Indonesia",
    "en": "English"
  };

  final Map<String, String> currencies = {
    "EUR" : "Euro\nEUR",
    "IDR" : "Indonesia Rupiah\nIDR",
    "MYR" : "Malaysia Ringgit\nMYR",
    "PHP" : "Philippine Peso\nPHP",
    "SGD" : "Singapore Dollar\nSGD",
    "THB" : "Thai Baht\nTHB",
    "USD" : "United States Dollar\nUSD",
    "VND" : "Vietnamese Dong\nVND"
  };

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = langCode!;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dialog_language!),
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
                            langCode = val; // update global
                          });
                          await StorageService.setLanguage(val);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (route) => false,
                          );
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
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dialog_currency!),
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
                        // if (val != null) {
                        //   setState(() {
                        //     currencyCode = val; // update global
                        //   });
                        //   await StorageService.setCurrency(val);
                        //   Navigator.pushAndRemoveUntil(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => const HomePage()),
                          //   (route) => false,
                          // );
                        // }

                        if (val == null) return;
                        setState(() {
                          userCurrency = val;
                          currencyCode = val;
                          isChoosed = 1;
                        });

                        await StorageService.setCurrency(val);
                        await StorageService.setIsChoosed(1);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        );
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
      body: isLoading
          ? buildSkeleton()
          : buildKonten()
    ); 
  }

  Widget buildSkeleton() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: kGlobalPadding,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: List.generate(6, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                    ),

                    const SizedBox(width: 16),
                    Container(
                      width: 16,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                  ],
                )
              );
            })
          )
        )
      )
    );
  }

  Widget buildKonten() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20,),

              //profile section
              token != null
                ? InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Profile(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/img_profile.png',
                                height: 50,
                                width: 50,
                              ),
                          
                              SizedBox(width: 12,),
                              Text(
                                bahasa['profil'], //"Profil"
                              )
                            ],
                          ),
                          Icon(Icons.arrow_forward_ios)
                        ],
                      ),
                    )
                  )
                : Container(
                    padding: EdgeInsets.all(0),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage()
                                ),
                              );
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                login!, //"Masuk",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisPage(fromProfil: true,)
                                ),
                              );
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                daftar!, //"Daftar",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

              // Bahasa section
              SizedBox(height: 20,),
              Container(
                padding: EdgeInsets.all(14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300,),
                ),
                child: InkWell(
                  onTap: _showLanguageDialog,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/img_bahasa.png',
                            height: 50,
                            width: 50,
                          ),
                      
                          SizedBox(width: 12,),
                          Text(
                            bahasa['bahasa'], //"Bahasa"
                          )
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios)
                    ],
                  ),
                ),
              ),

              //currency
              SizedBox(height: 20,),
              Container(
                padding: EdgeInsets.all(14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300,),
                ),
                child: InkWell(
                  onTap: _showCurrencyDialog,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/img_currency.png',
                            height: 50,
                            width: 50,
                          ),
                      
                          SizedBox(width: 12,),
                          Text(
                            bahasa['currency'], //"Mata Uang"
                          )
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios)
                    ],
                  ),
                ),
              ),

              // Pusat Bantuan section
              SizedBox(height: 20,),
              Container(
                padding: EdgeInsets.all(14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300,),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterPage(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/img_bantuan.png',
                            height: 50,
                            width: 50,
                          ),
                      
                          SizedBox(width: 12,),
                          Text(
                            bahasa['pusat_bantuan'], //"Pusat Bantuan"
                          )
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios)
                    ],
                  )
                ),
              ),

              // Tentang section
              SizedBox(height: 20,),
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TentangPage(),
                      ),
                    );
                },
                child: Container(
                  padding: EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/img_tentang.png',
                            height: 50,
                            width: 50,
                          ),
                      
                          SizedBox(width: 12,),
                          Text(
                            "${bahasa['tentang']} Kreen", //"Tentang"
                          )
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios)
                    ],
                  ),
                ),
              ),

              // Kebijakan Privasi section
              SizedBox(height: 20,),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivacyPolicyPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/img_kebijakan.png',
                            height: 50,
                            width: 50,
                          ),
                      
                          SizedBox(width: 12,),
                          Text(
                            bahasa['kebijakan_privasi'], //"Kebijakan Privasi"
                          )
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios)
                    ],
                  ),
                ),
              ),

              // Rating section
              // SizedBox(height: 20,),
              // Container(
              //   padding: EdgeInsets.all(14),
              //   width: double.infinity,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.grey.shade300,),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Container(
              //         child: Row(
              //           children: [
              //             Image.asset(
              //               'assets/images/img_rating.png',
              //               height: 50,
              //               width: 50,
              //             ),

              //             SizedBox(width: 12,),
              //             Text(
              //               "Bari Rating"
              //             )
              //           ],
              //         ),
              //       ),
              //       Icon(Icons.arrow_forward_ios)
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      )
    );
  }
}