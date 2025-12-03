// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'dart:async';
import 'onboarding_page.dart';

class SplashLogoPage extends StatefulWidget {
  const SplashLogoPage({super.key});

  @override
  State<SplashLogoPage> createState() => _SplashLogoPageState();
}

class _SplashLogoPageState extends State<SplashLogoPage> {

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final seen = await StorageService.hasSeenOnboarding();
    if (seen) {
      // langsung ke home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        // MaterialPageRoute(builder: (_) => CheckingUpUserPage()),
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
      body: Center(
      child: Image.asset(
        'assets/images/img_logo.png',
        width: 200, // bisa disesuaikan
        height: 200,
        fit: BoxFit.contain,
        ),
      ),
    );
  }
}
