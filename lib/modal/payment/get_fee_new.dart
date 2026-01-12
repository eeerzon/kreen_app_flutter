import 'package:intl/intl.dart';

Future<Map<String, dynamic>?> getFeeNew(
  String currencyCode,
  String voteCurrency, 
  String feeCurrency, 
  num totalPrice, 
  num feePersen, 
  num ppn, 
  num baseFee, 
  num rate, 
  List<int>? countsFinalis,
  num rateCurrencyPg,
  num rateCurrencyVote,
  num rateCurrencyUser
) async {

  num fee = baseFee;
  var resultFeeCurrVote = convertCurrency(fromRate: rateCurrencyPg, toRate: rateCurrencyVote, nominal: fee, toCurrency: feeCurrency); // convert ke currency vote dulu
  num feeCurrVote = resultFeeCurrVote['original_number']; // ini currency vote

  var resultFee = convertCurrency(fromRate: rateCurrencyPg, toRate: rateCurrencyUser, nominal: fee, toCurrency: voteCurrency); //currency vote ke session
  fee = resultFee['original_number']; // ini currency session

  num feeFinalCurrVote = num.parse(((totalPrice /
    (1 - (feePersen / 100) * (1 + ppn / 100)) +
    feeCurrVote * (1 + ppn / 100)) - totalPrice).toStringAsFixed(5));

  if (voteCurrency != "IDR") {
    feeFinalCurrVote += totalPrice * 1 / 100;
    feeFinalCurrVote = (feeFinalCurrVote * 100).ceil() / 100;
  } else {
    feeFinalCurrVote = feeFinalCurrVote.ceil();
  }

  num currencyValueSession = rateCurrencyUser / rateCurrencyVote;
  var convertSessionCurrency = getPriceCurrency(currencyCode: currencyCode, toCurrency: feeCurrency, totalPrice: totalPrice, fee: feeFinalCurrVote, currencyValueRegion: currencyValueSession);

  num amountInSessionCurrency = convertSessionCurrency['amount'];
  num feeInSessionCurrency = convertSessionCurrency['fee'];
  num totalAmountInSessionCurrency = convertSessionCurrency['total_amount']; // plus_first yang sama dengan pgpp

  if (countsFinalis != null && countsFinalis.isNotEmpty) {
      int total = countsFinalis.reduce((a, b) => a + b);

      return {
        'total_price': amountInSessionCurrency,
        'total_payment': totalAmountInSessionCurrency,
        'fee_layanan': feeInSessionCurrency,
        'total_votes': total
      };
    } else {

      return {
        'total_price': amountInSessionCurrency,
        'total_payment': totalAmountInSessionCurrency,
        'fee_layanan': feeInSessionCurrency
      };
    }
}

// SERTAKAN FROM CURRENCY KALAU TERIMA NILAI ASLI, PAHAM!
Map<String, dynamic> convertCurrency({
  required num fromRate,
  required num toRate,
  required num nominal,
  required String toCurrency,
}) {
  // nilai hasil konversi mentah
  num converted = nominal * (toRate / fromRate);

  // samakan dengan toFixed(5) di JS
  num convertedFixed5 = num.parse(converted.toStringAsFixed(5));

  num formatted;

  if (toCurrency == 'IDR') {
    // IDR → ceil ke integer
    formatted = convertedFixed5.ceil();
  } else {
    // selain IDR → ceil 2 desimal
    formatted = (convertedFixed5 * 100).ceil() / 100;
  }

  // formatter ribuan
  final formatter = NumberFormat.decimalPattern('en_US');

  return {
    'result': toCurrency == 'IDR'
        ? '$toCurrency ${formatter.format(formatted)}'
        : '$toCurrency ${formatter.format(num.parse(formatted.toStringAsFixed(2)))}', // '$toCurrency ${formatter.format(num.parse(formatted).toStringAsFixed(2))}',

    'number': toCurrency == 'IDR'
        ? formatted.toInt()
        : num.parse(formatted.toStringAsFixed(2)),

    'original_number': converted,

    'original_result': '$toCurrency $converted',
  };
}

Map<String, dynamic> getPriceCurrency ({
  required String currencyCode,
  required String toCurrency,
  required num totalPrice,
  required num fee,
  required num currencyValueRegion
}) {

  num priceRegion = (totalPrice + fee) * currencyValueRegion;
  priceRegion = num.parse(priceRegion.toStringAsFixed(5));

  num amount = totalPrice * currencyValueRegion;
  amount = num.parse(amount.toStringAsFixed(5));

  num totalAmount;

  if (toCurrency == 'IDR') {
    amount = amount.ceil();
    totalAmount = priceRegion.ceil();
  } else {
    if (currencyCode == "IDR"){
      amount = amount.ceil();
      totalAmount = priceRegion.ceil();
    } else {
      amount = (amount * 100).ceil() / 100;
      totalAmount = (priceRegion * 100).ceil() / 100;
    }
  }

  num calculatedFee = totalAmount - amount;
  calculatedFee = toCurrency == 'IDR' ? calculatedFee.floor() : calculatedFee;

  return {
    'amount': amount,
    'fee': calculatedFee,
    'total_amount': totalAmount
  };
}



