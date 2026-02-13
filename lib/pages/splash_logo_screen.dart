// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'onboarding_page.dart';

class SplashLogoPage extends StatefulWidget {
  const SplashLogoPage({super.key});

  @override
  State<SplashLogoPage> createState() => _SplashLogoPageState();
}

class _SplashLogoPageState extends State<SplashLogoPage> {
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkOnboarding();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      // appVersion = "v${info.version}+${info.buildNumber}";
      appVersion = "v${info.version}";
    });
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(const Duration(seconds: 2));
    final seen = await StorageService.hasSeenOnboarding();
    if (seen) {
      // langsung ke home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      // ke onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
      await StorageService.setOnboardingDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // LOGO
          Center(
            child: Image.asset(
              'assets/images/img_logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 20,
            child: Text(
              appVersion.isNotEmpty ? appVersion : "",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
