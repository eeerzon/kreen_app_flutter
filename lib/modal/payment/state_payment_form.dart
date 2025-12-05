// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/helper/get_geo_location.dart';
import 'package:kreen_app_flutter/pages/event/waiting_order_event.dart';
import 'package:kreen_app_flutter/services/api_services.dart';

class StatePaymentForm extends StatefulWidget {
  final String id_event;
  final List<String> ids_tiket;
  final List<String> names_tiket;
  final List<int> counts_tiket;
  final List<int> prices_tiket;
  final num totalHarga;
  final List<TextEditingController> first_names;
  final List<String?> genders;
  final List<TextEditingController> emails;
  final List<TextEditingController> phones;
  final List<List<String>> ids_order_form_details;
  final List<List<String>> ids_order_form_master;
  final List<List<String>> answers;
  final bool formGlobal;
  final bool fromDetail;
  final String jenis_participant;
  final String? idUser;

  const StatePaymentForm({
    super.key,
    
    required this.id_event,
    required this.ids_tiket,
    required this.names_tiket,
    required this.counts_tiket,
    required this.prices_tiket,
    required this.totalHarga,
    required this.first_names,
    required this.genders,
    required this.emails,
    required this.phones,
    required this.ids_order_form_details,
    required this.ids_order_form_master,
    required this.answers,
    required this.formGlobal,
    required this.fromDetail,
    required this.jenis_participant,
    this.idUser
  });

  @override
  State<StatePaymentForm> createState() => _StatePaymentFormState();
}

class _StatePaymentFormState extends State<StatePaymentForm> {
  var get_user;
  var user_id;
  var first_name;
  var last_name;
  var gender;
  var phone;
  var email;

  String? inputNama;

  Map<String, dynamic> detailVote = {};
  Map<String, dynamic> detailEvent = {};
  Map<String, dynamic> payment = {};
  List<dynamic> indikator = [];
  String? voteCurrency, eventCurrency;
  var totalPayment, feeLayanan;

  String? id_payment_method, mobile_number, id_card_number, card_number, expiry_month, expiry_year, cvv;

  String? id_indikator, answer;
  String? selectedGender;

  late List<TextEditingController> answerControllers;
  
  int? selectedIndex;

  final formatter = NumberFormat.decimalPattern("id_ID");
  final ScrollController _scrollController = ScrollController();
  final TextEditingController expDateController = TextEditingController();
  bool _isEditing = false;
  bool loading = true;

  Future<Map<String, dynamic>?> getFee(String feeCurrency, var total_price, var feePersen, var ppn, var base_fee, var rate) async {
    var total_payment;
    var fee;

    var fee_percent_decimal = feePersen / 100;
    var ppn_decimal = ppn / 100;

    if (feeCurrency == 'IDR') {
      var fee_percent_with_ppn = fee_percent_decimal * (1 + ppn_decimal);
      var base_fee_with_ppn = base_fee * (1 + ppn_decimal);

      var grossed_total = total_price / (1 - fee_percent_with_ppn);
      var total_with_fee = grossed_total + base_fee_with_ppn;
      fee = (total_with_fee - total_price).ceilToDouble();
      total_payment = total_with_fee.ceilToDouble();
    } else {
      var total_price_pg = total_price * rate;

      var fee_percent_with_ppn = fee_percent_decimal * (1 + ppn_decimal);
      var base_fee_with_ppn = base_fee * (1 + ppn_decimal);

      var grossed_total_pg = total_price_pg / (1 - fee_percent_with_ppn);
      var total_with_fee_pg = grossed_total_pg + base_fee_with_ppn;

      // Tambahan 1% untuk luar negeri
      var extra_fee_pg = total_price_pg * 0.01;
      total_with_fee_pg += extra_fee_pg;

      // Konversi kembali ke mata uang asli
      var total_with_fee_foreign = total_with_fee_pg / rate;

      total_payment = (total_with_fee_foreign * 100000).ceil() / 100000;
      fee = total_payment - total_price;
    }

    return {
        'total_payment': total_payment,
        'fee_layanan': fee
    };
  }

  Future<void> getPaymentEvent(String id_event) async {

    final body = {
      "id_event": id_event,
    };

    final resultEvent = await ApiService.post('/event/detail', body: body);
    final resultPayment = await ApiService.get("/event/$id_event/payment-methods");

    setState(() {
      detailEvent = resultEvent?['data'] ?? {};
      eventCurrency = detailEvent['event']['currency'];
      payment = resultPayment?['data'] ?? {};
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getPaymentEvent(widget.id_event);
    });
  }

  @override
  Widget build(BuildContext context) {
    expDateController.addListener(() {
      final text = expDateController.text;

      if (_isEditing) return;
        _isEditing = true;

      // Hapus karakter selain angka dan '/'
      final cleaned = text.replaceAll(RegExp(r'[^0-9/]'), '');

      String newText = cleaned;

      // Kalau user baru ketik 2 digit dan belum ada '/'
      if (cleaned.length == 2 && !cleaned.contains('/')) {
        newText = "$cleaned/";
      }

      // Potong kalau lebih dari 5 karakter
      if (newText.length > 5) {
        newText = newText.substring(0, 5);
      }

      if (newText != text) {
        expDateController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }

      if (newText.contains('/')) {
        final parts = newText.split('/');
        expiry_month = parts[0];
        expiry_year = parts.length > 1 ? parts[1] : null;
      } else {
        expiry_month = newText;
        expiry_year = null;
      }

      _isEditing = false;
    });

    void handleConfirm() async {
      final position = await getCurrentLocationWithValidation(context);

      if (position == null) {
        // Stop, jangan lanjut submit
        return;
      }

      final latitude = position.latitude;
      final longitude = position.longitude;
      //payment
      String platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : Platform.operatingSystem;

      final tickets = <Map<String, dynamic>>[];

      int globalIndex = 0;

      for (int i = 0; i < widget.ids_tiket.length; i++) {
        final idTicket = widget.ids_tiket[i];
        final count = int.tryParse(widget.counts_tiket[i].toString()) ?? 1;

        for (int j = 0; j < count; j++) {
          tickets.add({
            "id_ticket": idTicket,
            "first_name": widget.first_names[globalIndex].text,
            "email": widget.emails[globalIndex].text,
            "phone": widget.phones[globalIndex].text,
            // "gender": genders[globalIndex],
            "order_form_answers": List.generate(
              widget.ids_order_form_master[j].length,
              (index) => {
                "id_order_form_master": widget.ids_order_form_master[j][index],
                "id_order_form_detail": widget.ids_order_form_details[j][index],
                "answer": widget.answers[globalIndex][index],
              },
            ),
          });
          globalIndex++;
        }
      }

      final body = {
        "id_event": widget.id_event,
        "id_user": widget.idUser,
        'platform': platform,
        "latitude": latitude,
        "longitude": longitude,
        "tickets": tickets,
        "payment_method": {
            "id_payment_method": id_payment_method,
            "mobile_number": mobile_number,
            "id_card_number": id_card_number,
            "card_number": card_number,
            "expiry_month": expiry_month,
            "expiry_year": expiry_year,
            "cvv": cvv
        },
      };

      var resultEventOrder = await ApiService.post("/order/event/checkout", body: body);

      if (resultEventOrder != null) {
        final tempOrder = resultEventOrder['data'];

        var id_order = tempOrder['data']['id_order'];
        Navigator.pop(context);//tutup modal

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WaitingOrderEvent(id_order: id_order)),
        );
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.topSlide,
          title: 'Oops!',
          desc: 'Terjadi kesalahan. Silakan coba lagi.',
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
          buttonsTextStyle: TextStyle(color: Colors.white),
          headerAnimationLoop: false,
          dismissOnTouchOutside: true,
          showCloseIcon: true,
        ).show();
      }
    }

    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.red,)),
      );
    }

    final creditCard = payment['Credit Card'] ?? [];
    final virtualAkun = payment['Virtual Account'] ?? [];
    final paymentBank = payment['Payment Bank'] ?? [];
    final eWallet = payment['E-Wallet'] ?? [];
    final retail = payment['Retail'] ?? [];
    final konter = payment['Counter'] ?? [];
    final qrCode = payment['QR Codes'] ?? [];
    final debit = payment['Direct Debit'] ?? [];

    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: kGlobalPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300,),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Pembayaran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: kGlobalPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //pembayaran
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(FontAwesomeIcons.dollarSign),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        "Pilih Metode Pembayaran",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Yuk pilih metode pembayaranmu..."
                      ),

                      const SizedBox(height: 12,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (creditCard.isNotEmpty) ... [
                            const Text(
                              "International Payments",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...creditCard.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;

                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = creditCard[idx]['id_metod'];
                                  });

                                  final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                  if (resultFee !=null) {
                                    setState(() {
                                      totalPayment = resultFee['total_payment'];
                                      feeLayanan = resultFee['fee_layanan'];
                                    });
                                  }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),

                                              if (isSelected) ... [
                                                const SizedBox(height: 20,),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Kartu Kredit',
                                                    ),
                                                    Container(
                                                      color: Colors.white,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        autofocus: false,
                                                        onChanged: (value) {
                                                          card_number = value;
                                                        },
                                                        keyboardType: TextInputType.number,
                                                        decoration: InputDecoration(
                                                          hintText: "xxxx xxxx xxxx xxxx",
                                                          hintStyle: const TextStyle(
                                                            color: Colors.grey,
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(8),
                                                              topRight: Radius.circular(8),
                                                            ),
                                                          ),
                                                        ),
                                                        inputFormatters: [
                                                          LengthLimitingTextInputFormatter(16),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            color: Colors.white,
                                                            child: TextField(
                                                              controller: expDateController,
                                                              autofocus: false,
                                                              decoration: InputDecoration(
                                                                hintText: "MM/YY",
                                                                hintStyle: const TextStyle(
                                                                  color: Colors.grey,
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: const BorderRadius.only(
                                                                    bottomLeft: Radius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              inputFormatters: [
                                                                LengthLimitingTextInputFormatter(5),
                                                              ],
                                                            ),
                                                          )
                                                        ),

                                                        Expanded(
                                                          child: Container(
                                                            color: Colors.white,
                                                            child: TextField(
                                                              autofocus: false,
                                                              onChanged: (value) {
                                                                cvv = value;
                                                              },
                                                              decoration: InputDecoration(
                                                                hintText: "CVV",
                                                                hintStyle: const TextStyle(
                                                                  color: Colors.grey,
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: const BorderRadius.only(
                                                                    bottomRight: Radius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              inputFormatters: [
                                                                LengthLimitingTextInputFormatter(3),
                                                              ],
                                                              obscureText: true,
                                                            ),
                                                          )
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                )
                                              ]
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (virtualAkun.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Virtual Account",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...virtualAkun.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = virtualAkun[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (paymentBank.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Payment Bank",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...paymentBank.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = paymentBank[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (eWallet.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "E-Wallet",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...eWallet.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = eWallet[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (retail.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Retail",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...retail.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = retail[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (konter.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Counter",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...konter.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + retail.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = konter[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (qrCode.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "QR Codes",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...qrCode.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + retail.length + konter.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = qrCode[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          if (debit.isNotEmpty) ... [
                            const SizedBox(height: 20),

                            const Text(
                              "Direct Debit",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            ...debit.asMap().entries.map((entry) {
                              final index = entry.key;
                              final idx = creditCard.length + virtualAkun.length + paymentBank.length + eWallet.length + retail.length + konter.length + qrCode.length + entry.key;
                              final item = entry.value;
                              
                              final payment_name = item['payment_name'];
                              final id_pg_type = item['id_pg_type'];
                              final exchange_rate = item['exchange_rate_new'];
                              final limit_min = item['limit_min']; 
                              final limit_max = item['limit_max'];

                              final currentcy_min = limit_min * exchange_rate;
                              final currentcy_max = limit_max * exchange_rate;
                              int roundedValue_min = currentcy_min.ceil();
                              int roundedValue_max = currentcy_max.ceil();

                              final isSelected = selectedIndex == idx;

                              final isDisabled = widget.totalHarga < limit_min || widget.totalHarga > limit_max;

                              return GestureDetector(
                                onTap: isDisabled
                                ? null 
                                : () async {
                                  setState(() {
                                    selectedIndex = idx;
                                    id_payment_method = debit[index]['id_metod'];
                                  });
                                  
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOut,
                                      );
                                    });

                                    final resultFee = await getFee(eventCurrency!, widget.totalHarga, item['fee_percent'], item['ppn'], item['fee'], item['rate']);

                                    if (resultFee != null) {
                                      setState(() {
                                        totalPayment = resultFee['total_payment'];
                                        feeLayanan = resultFee['fee_layanan'];
                                      });
                                    }
                                },
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Opacity(
                                      opacity: isDisabled ? 0.6 : 1.0,
                                      child: ColorFiltered(
                                        colorFilter: isDisabled
                                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Image.network(
                                                    "$baseUrl/image/payment-method/${item['img']}",
                                                    height: 70,
                                                    width: 70,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        height: 70,
                                                        width: 70,
                                                      );
                                                    },
                                                  ),

                                                  const SizedBox(width: 8,),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            // Teks akan menyesuaikan ruang sisa
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Text(
                                                                  "$payment_name $id_pg_type",
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(width: 6),
                                                            // Badge region
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                item['region'] ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.red.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(height: 6),
                                                        if (widget.totalHarga < limit_min)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text(
                                                              "Limit minimal transaksi $eventCurrency ${formatter.format((roundedValue_min + 1000))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),
                                                        
                                                        if (widget.totalHarga > limit_max)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Text( limit_max == 0
                                                              ? "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max + 1000))}"
                                                              : "Limit maksimail transaksi $eventCurrency ${formatter.format((roundedValue_max))}",
                                                              softWrap: true,
                                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  )

                                                ],
                                              ),

                                              if (isSelected) ... [
                                                const SizedBox(height: 20,),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      color: Colors.white,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        autofocus: false,
                                                        onChanged: (value) {
                                                          mobile_number = value;
                                                        },
                                                        keyboardType: TextInputType.number,
                                                        decoration: InputDecoration(
                                                          hintText: "masukkan nomor handphone kamu",
                                                          hintStyle: const TextStyle(
                                                            color: Colors.grey,
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(8),
                                                              topRight: Radius.circular(8),
                                                            ),
                                                          ),
                                                        ),
                                                        inputFormatters: [
                                                          LengthLimitingTextInputFormatter(16),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ]
                                            ],
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ]
                        ],
                      ),

                      if (selectedIndex != null) ...[
                        const SizedBox(height: 25),
                        const Text(
                          "Detail Harga",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 16,),
                        Column(
                          children: [
                            Column(
                              children: [
                                for (int i = 0; i < widget.names_tiket.length; i++) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("${widget.names_tiket[i]} (${widget.counts_tiket[i]}x)"),
                                      Text(
                                        "$eventCurrency ${formatter.format(widget.counts_tiket[i] * widget.prices_tiket[i])}",
                                      ),
                                    ],
                                  ),
                                  if (i != widget.names_tiket.length - 1)
                                    SizedBox(height: 16),
                                ],
                              ],
                            ),

                            const SizedBox(height: 16,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Biaya Layanan"),
                                Text('$eventCurrency ${formatter.format(feeLayanan)}')
                              ],
                            ),

                            const SizedBox(height: 6,),
                            const Divider(
                              thickness: 1,
                              color: Color.fromARGB(255, 224, 224, 224),
                            ),

                            const SizedBox(height: 6,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total Bayar", style: TextStyle(fontWeight: FontWeight.bold),),
                                Text("$eventCurrency ${formatter.format(totalPayment)}", style: TextStyle(fontWeight: FontWeight.bold),)
                              ],
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedIndex != null ? Colors.red : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: handleConfirm,
                                child: const Text(
                                  "Konfirmasi",
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Batal"),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}