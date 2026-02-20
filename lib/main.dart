
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'pages/splash_logo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp();

  // Stripe.publishableKey = STRIPE_PUBLIC_KEY_PRODUCTION;
  Stripe.publishableKey = STRIPE_PUBLIC_KEY_SANDBOX; //dev
  await Stripe.instance.applySettings(); 

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashLogoPage(), // langsung splash logo
    );
  }
}
