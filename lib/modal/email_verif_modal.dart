// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';

class EmailVerifModal {
  static Future<void> show(
    BuildContext context, 
    String token, 
    String langCode, 
    Map<String, dynamic> bahasa, 
    String email, 
    Color color
  ) async {
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: kGlobalPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  "$baseUrl/image/verify-email.png",
                  width: 200,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 16),

                Text(
                  bahasa['modal_verif_email_title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  bahasa['modal_verif_email_desc'],
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    bahasa['modal_verif_email_button'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final resultVerifEmail = await ApiService.postSetProfil('$baseapiUrl/send-email-verification',token: token, body: null, xLanguage: langCode);

                    if (resultVerifEmail?['rc'] == 200) {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.success,
                        title: langCode == 'id' ? 'Berhasil' : 'Success',
                        desc:
                          "${bahasa['desc_email_1']}\n"
                          "${bahasa['desc_email_2']} $email\n"
                          "${bahasa['desc_email_3']}",
                        transitionAnimationDuration: const Duration(milliseconds: 1000),
                        btnOkText: "OK",
                        btnOkColor: Colors.red,
                        btnOkOnPress: () {},
                      ).show();
                    } else {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.noHeader,
                        animType: AnimType.topSlide,
                        title: bahasa['maaf'],
                        desc: bahasa['error'], //"Terjadi kesalahan. Silakan coba lagi.",
                        btnOkOnPress: () {},
                        btnOkColor: Colors.red,
                        buttonsTextStyle: TextStyle(color: Colors.white),
                        headerAnimationLoop: false,
                        dismissOnTouchOutside: true,
                        showCloseIcon: true,
                      ).show();
                    }
                  },
                )
              ],
            ),
          ),
        );
      }
    );
  }

  static Future<bool> showLogin(
    BuildContext context,
    Map<String, dynamic> bahasa,
    Color color,
    {
      VoidCallback? onLoginSuccess,  // <-- tambah ini
    }
  ) async {
    final completer = Completer<bool>();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: kGlobalPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/img_ovo30d.png",
                  width: 200,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),
                Text(
                  bahasa['notLogin'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),
                Text(
                  bahasa['notLoginDesc'],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    final loginResult = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const LoginPage(notLog: true,)),
                    );

                    final success = loginResult == true;
                    if (success) onLoginSuccess?.call();

                    if (!completer.isCompleted) completer.complete(success);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    elevation: 2,
                  ),
                  child: Text(
                    bahasa['login'],
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
    
    if (!completer.isCompleted) completer.complete(false);

    return completer.future;
  }
}