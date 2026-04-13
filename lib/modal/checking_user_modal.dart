// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/session_manager.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

class CheckingUserModal {
  static Future<void> show(BuildContext context, String langCode, bool onboarding) async {
    List<Map<String, dynamic>> pages = [];
    final data = await LangService.loadOnboarding(langCode);
    pages = data;

    final bahasa = await LangService.getJsonData(langCode, "bahasa");
    await showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: kGlobalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    if (!onboarding) ... [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bahasa['top_nav'] ?? 'Selamat Datang di Kreen',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      Image.asset(
                        'assets/images/img_onboarding3.png',
                        height: 125,
                        fit: BoxFit.contain,
                      ),
                      
                      SizedBox(height: 12),
                      Text(
                        pages[0]["title"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      Text(
                        pages[0]["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],

                    SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginPage()),
                        );
                      },
                      child: Text(
                        bahasa['login'] ?? 'Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 12),
                    // TextButton(
                    // onPressed: () {
                    //   Navigator.pop(context);
                    // },
                    // child: Text(
                    //     loginAs ?? "",
                    //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), 
                    //   )
                    // )
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
                        if (onboarding) {
                          Navigator.pop(context);
                          SessionManager.isGuest = true;
                          SessionManager.checkingUserModalShown = true;
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        bahasa['guest_login'] ?? 'Lanjut sebagai Tamu',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}