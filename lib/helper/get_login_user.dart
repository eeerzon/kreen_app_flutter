import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';

class LoginPrompt extends StatelessWidget {
  final Map bahasa;
  final Function(Map getUser, String token) onLoginSuccess;

  const LoginPrompt({
    super.key,
    required this.bahasa,
    required this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: kGlobalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ),

          const SizedBox(height: 24),
          Text(
            bahasa['notLogin'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),
          Text(
            bahasa['notLoginDesc'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
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
                final storedUser = await StorageService.getUser();

                final storedToken = await StorageService.getToken();
                onLoginSuccess(storedUser, storedToken!);
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
              bahasa['login'],
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
