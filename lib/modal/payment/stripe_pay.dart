// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:kreen_app_flutter/pages/order/order_event_paid.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';

Future<void> StripePay(
  BuildContext context, 
  String clientSecret, 
  String type, 
  Map<String, dynamic>? vote, 
  Map<String, dynamic>? voteOrder,
  Map<String, dynamic>? event, 
  Map<String, dynamic>? eventOrder,
) async {
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

    if (type == "vote") {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => 
          AddSupportPage(
            id_vote: vote?['id_vote'], 
            id_order: voteOrder?['id_order'], 
            nama: voteOrder?['voter_name'],
            )
          ),
      );
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => 
          OrderEventPaid(
            idOrder: eventOrder?['id_order'], isSukses: true,
          )
        ),
      );
    }
    debugPrint('Payment success');
  } catch (e) {
    debugPrint('Payment failed: $e');
  }
}

Future<void> GooglePay(
  BuildContext context, 
  String clientSecret, 
  String type, 
  Map<String, dynamic>? vote, 
  Map<String, dynamic>? voteOrder,
  Map<String, dynamic>? event, 
  Map<String, dynamic>? eventOrder,
) async {
  try {
    // final clientSecret = await createPaymentIntent();

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        customerId: null,
        customerEphemeralKeySecret: null,
        merchantDisplayName: 'Kreen App',
        allowsDelayedPaymentMethods: true,
        googlePay: PaymentSheetGooglePay(
          testEnv: true, // false untuk Production
          currencyCode: 'USD', 
          merchantCountryCode: 'US',
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    if (type == "vote") {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => 
          AddSupportPage(
            id_vote: vote?['id_vote'], 
            id_order: voteOrder?['id_order'], 
            nama: voteOrder?['voter_name'],
            )
          ),
      );
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => 
          OrderEventPaid(
            idOrder: eventOrder?['id_order'], isSukses: true,
          )
        ),
      );
    }
    debugPrint('Payment success');
  } catch (e) {
    debugPrint('Payment failed: $e');
  }
}
