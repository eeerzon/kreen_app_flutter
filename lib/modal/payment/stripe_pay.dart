// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> StripePay(String clientSecret) async {
  try {
    // final clientSecret = await createPaymentIntent();

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        customerId: null,
        customerEphemeralKeySecret: null,
        merchantDisplayName: 'Kreen App',
        allowsDelayedPaymentMethods: true,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    debugPrint('Payment success');
  } catch (e) {
    debugPrint('Payment failed: $e');
  }
}
