// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/modal/check_payment_modal.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class WaitingOrderEvent extends StatefulWidget {
  final String id_order;
  final bool formHistory;
  final String? currency_session;
  const WaitingOrderEvent({super.key, required this.id_order, this.formHistory = false, required this.currency_session});

  @override
  State<WaitingOrderEvent> createState() => _WaitingOrderEventState();
}

class _WaitingOrderEventState extends State<WaitingOrderEvent> {
  String? langCode, currencyCode;
  DateTime deadline = DateTime(2025, 10, 17, 13, 30, 00, 00, 00);

  final DateTime now = DateTime.now();
  Duration remaining = Duration.zero;
  Timer? _timer;

  bool _isLoading = true;

  bool tapinstruksi = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadOrder();
      _startCountdown();
    });
  }

  void _startCountdown() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    setState(() {
      remaining = difference.isNegative ? Duration.zero : difference;
    });
  }

  Map<String, dynamic> paymentLang = {};
  Map<String, dynamic> detailFinalisLang = {};

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final temppaymentlang = await LangService.getJsonData(langCode!, "payment");
    final tempdetailfinalislang = await LangService.getJsonData(langCode!, "detail_finalis");

    setState(() {
      paymentLang = temppaymentlang;
      detailFinalisLang = tempdetailfinalislang;
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  Map<String, dynamic> detailOrder = {};
  Map<String, dynamic> eventOder = {};
  List<dynamic> eventOrderDetail = [];
  List<dynamic> eventTiket = [];
  Map<String, dynamic> paymentDetail = {};
  List<dynamic> instruction = [];
  Map<String, dynamic> event = {};

  var expiresAt;

  Future<void> _loadOrder() async {

    final resultOrder = await ApiService.get("/order/event/${widget.id_order}", xLanguage: langCode, xCurrency: currencyCode);

    final tempOrder = resultOrder?['data'] ?? {};

    final temp_event_order = tempOrder['event_order'] ?? {};
    final temp_event_order_detail = tempOrder['event_order_detail'] ?? [];
    final temp_event_tiket = tempOrder['event_ticket'] ?? [];

    final temp_payment_detail = tempOrder['payment_detail'] ?? {};
    final temp_instruction = temp_payment_detail['instruction'] ?? [];

    final temp_event = tempOrder['event'] ?? {};

    if (mounted) {
        detailOrder = tempOrder;

        eventOder = temp_event_order;
        eventOrderDetail = temp_event_order_detail;
        eventTiket = temp_event_tiket;

        paymentDetail = temp_payment_detail;
        instruction = temp_instruction;

        event = temp_event;

        final rawExpires = eventOder['order_created_at'];
        if (rawExpires != null && rawExpires.toString().isNotEmpty) {
          final date = DateTime.parse(rawExpires.replaceAll(' ', 'T'));

          // tambahkan 1 jam
          final newDate = date.add(const Duration(hours: 1));
          
          expiresAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDate);
        } else {
          expiresAt = '';
        }

        deadline = DateTime.parse(expiresAt).toLocal();
        _isLoading = false;
    }
  }

  final formatter = NumberFormat.decimalPattern("en_US");

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? buildSkeletonHome()
          : buildKontenOrder()
    );
  }

  Widget buildSkeletonHome() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        centerTitle: false,
        leading: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(height: 40, width: 40, color: Colors.white)
        ),
        actions: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: Container(height: 40, width: 40, color: Colors.white),
            ) 
          )
        ],
      ),

      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey[200],
          padding: kGlobalPadding,
          child: Column(
            children: [

              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Header shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/img_placeholder.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildKontenOrder() {
    // Cek waktu kadaluarsa
    if (expiresAt.isNotEmpty) {
      final expiredDate = DateTime.parse(expiresAt);
      final now = DateTime.now();

      if (now.isAfter(expiredDate)) {
        // waktu sudah lewat, tampilkan halaman kadaluarsa
        return buildLinkKadaluarsa();
      }
    }
    
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    String formattedDate = '-';

    String? currencyRegion;
    if (eventOder['order_region'] == "ID"){
      currencyRegion = 'IDR';
    } else if (eventOder['order_region'] == "US"){
      currencyRegion = 'USD';
    } else if (eventOder['order_region'] == "SG"){
      currencyRegion = 'SGD';
    } else if (eventOder['order_region'] == "MY"){
      currencyRegion = 'MYR';
    } else if (eventOder['order_region'] == "TH"){
      currencyRegion = 'THB';
    } else if (eventOder['order_region'] == "VN"){
      currencyRegion = 'VND';
    }

    num user_currency_amount = num.parse(eventOder['user_currency_amount'].toStringAsFixed(5)); // konversi ke double (num())
    if (currencyRegion == "IDR") {
      user_currency_amount = user_currency_amount.ceil();
    } else {
      user_currency_amount = (user_currency_amount * 100).ceil() / 100;
    }

    num user_currency_total_payment = num.parse(eventOder['user_currency_total_payment'].toStringAsFixed(5)); // konversi ke double (num())
    if (currencyRegion == "IDR") {
      user_currency_total_payment = user_currency_total_payment.ceil();
    } else {
      user_currency_total_payment = (user_currency_total_payment * 100).ceil() / 100;
    }

    num fee = user_currency_total_payment - user_currency_amount;

    if (expiresAt.isNotEmpty) {
      try {
        // parsing string ke DateTime
        final date = DateTime.parse(expiresAt); // pastikan format ISO (yyyy-MM-dd)
        if (langCode == 'id') {
          // Bahasa Indonesia
          final formatter = DateFormat("dd MMMM yyyy, HH:mm", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          // Bahasa Inggris
          final formatter = DateFormat("MMMM d yyyy, hh:mm a", "en_US");
          formattedDate = formatter.format(date);

          // tambahkan suffix (1st, 2nd, 3rd, 4th...)
          final day = date.day;
          String suffix = 'th';
          if (day % 10 == 1 && day != 11) { suffix = 'st'; }
          else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
          else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
          formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
        }
      } catch (e) {
        formattedDate = '-';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(paymentLang['header']),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline_outlined, color: Colors.blue,),
                    SizedBox(width: 4,),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          paymentLang['dont_close'], //'Jangan tutup halaman ini sebelum Anda menyelesaikan pembayaran',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        )
                      ),
                    ),
                  ],
                ),
              )
            ),

            const SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ?Colors.red[50],
                    Colors.white
                  ],
                  stops: [0.3, 0.7],
                )
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: kGlobalPadding,
                  child: Column(
                    children: [

                      Text(paymentLang['sisa_waktu']), //const Text("Sisa Waktu Pembayaran"),

                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.red, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: kGlobalPadding,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _timeBox("$hours".padLeft(2, "0"), detailFinalisLang['hour']), //"Jam"
                                  const SizedBox(width: 10),
                                  _separator(),
                                  const SizedBox(width: 10),
                                  _timeBox("$minutes".padLeft(2, "0"), detailFinalisLang['minute']), //"Menit"
                                  const SizedBox(width: 10),
                                  _separator(),
                                  const SizedBox(width: 10),
                                  _timeBox("$seconds".padLeft(2, "0"), detailFinalisLang['second']), //"Detik"
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(paymentLang['selesaikan_pembayaran']), //const Text("Selesaikan pembayaranmu sebelum"),
                      Text(
                        formattedDate,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Image.network(
                                    "$baseUrl/image/payment-method/${eventOder['payment_method_image']}",
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

                                  const SizedBox(width: 10,),
                                  Text(
                                    eventOder['bank_code'] ?? "",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),

                                  if (eventOder['bank_code'] == null || eventOder['bank_code'] == "") ... [
                                    InkWell(
                                      onTap: () {
                                        if (tapinstruksi) {
                                          tapinstruksi = false;
                                        } else {
                                          tapinstruksi = true;
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue,),
                                          Text(
                                            paymentLang['instruksi_pembayaran'],
                                            style: TextStyle(color: Colors.blue),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                  
                                ],
                              ),

                              if (tapinstruksi) ... [
                                const SizedBox(height: 10,),
                                Text(
                                  paymentLang['instruksi_pembayaran'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),

                                const SizedBox(height: 10,),
                                ...instruction.asMap().entries.map((entry) {
                                  final item = entry.value;

                                  var metod_instruction_payget;
                                  var instruction_payget;

                                  if (langCode == 'id') {
                                    metod_instruction_payget = item['metod_instruction_payget'];
                                    instruction_payget = item['instruction_payget'];
                                  } else if (langCode == 'en') {
                                    metod_instruction_payget = item['en_metod_instruction_payget'];
                                    instruction_payget = item['en_instruction_payget'];
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        metod_instruction_payget,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                  
                                      const SizedBox(height: 8,),
                                      Html(
                                        data: instruction_payget
                                      )
                                    ],
                                  );
                                }),
                              ],
                              
                              const Divider(
                                thickness: 1,
                                color: Color.fromARGB(255, 224, 224, 224),
                              ),

                              if (paymentDetail['qr_url'] != null) ...[
                                SizedBox(height: 16,),
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        paymentDetail['qr_url'],
                                        height: 200,
                                        width: 200,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/img_broken.jpg',
                                            height: 200,
                                            width: 200,
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                )
                              ],

                              const SizedBox(height: 16,),
                              Text(
                                paymentLang['kode_pesanan'], //'Kode Pesanan',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 10,),
                              Text(
                                eventOder['invoice_number'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              if (paymentDetail['va_number'] != null) ... [

                                const SizedBox(height: 25,),
                                Text(
                                  paymentLang['nomor_pembayaran'], //'Nomor Pembayaran',
                                  style: TextStyle(color: Colors.grey,),
                                ),
                                
                                const SizedBox(height: 10,),
                                InkWell(
                                  onTap: () async {
                                    final vaNumber = paymentDetail['va_number']?.toString() ?? '';

                                    if (vaNumber.isNotEmpty) {
                                      // Salin ke clipboard
                                      await Clipboard.setData(ClipboardData(text: vaNumber));

                                      // Tampilkan snackbar konfirmasi
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(paymentLang['copyVA']), //content: Text('Nomor VA berhasil disalin'),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        paymentDetail['va_number'],
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),

                                      const SizedBox(width: 4,),
                                      Icon(Icons.copy_outlined, color: Colors.grey,)
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10,),
                              Text(
                                '${paymentLang['total_pembayaran']} ($currencyRegion)', //'Total Pembayaran ${event['currency_event']}',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 10,),
                              Text(
                                '$currencyRegion ${formatter.format(paymentDetail['amount'])}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10,),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                                    child: Image.network(
                                      event['event_banner'],
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/img_broken.jpg',
                                        height: 80,
                                        width: 80,
                                      );
                                    }, // tambahin ini biar proporsional
                                    ),
                                  ),

                                  const SizedBox(width: 10,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['event_title'],
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),

                                      const SizedBox(height: 8,),
                                      Text(
                                        '${eventTiket[0]['ticket_name']} (${eventOrderDetail[0]['qty']}x)',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              
                              const SizedBox(height: 20,),
                              Text(
                                paymentLang['ringkasan_pembayaran'], //'Ringkasan Pembayaran',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    detailFinalisLang['total_harga'], //'Total Harga'
                                  ),

                                  Text(
                                    '${widget.currency_session} ${formatter.format(user_currency_amount)}'
                                  )
                                ],
                              ),

                              const SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paymentLang['biaya_layanan'], //'Biaya Layanan'
                                  ),

                                  Text(
                                    '${widget.currency_session} ${formatter.format(fee)}'
                                  )
                                ],
                              ),

                              const SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paymentLang['total_pembayaran'], //'Total Pembayaran',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),

                                  Text(
                                    '${widget.currency_session} ${formatter.format(user_currency_total_payment)}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),


                      const SizedBox(height: 30,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await CheckPaymentModal.show(
                              context,
                              widget.id_order
                            );
                          },
                          child: Text(
                            paymentLang['check_status'],
                            style: TextStyle( fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                )
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget buildLinkKadaluarsa() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: Colors.grey.shade200,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300,),
            ),
            child: Padding(
              padding: kGlobalPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Image.network(
                      '$baseUrl/image/expired_order.png',
                      width: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/img_broken.jpg',
                          height: 180,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    paymentLang['link_kadaluarsa'], //'Link Pembayaran Kadaluwarsa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    paymentLang['link_kadaluarsa_desc'], //'Maaf... Tautan ini memiliki batas waktu akses demi keamanan dan pengelolaan akses yang lebih baik.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      paymentLang['transaksi_lagi'], //"Ayo, lakukan transaksi kembali",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      text: paymentLang['kendala'], // 'Jika kendala berlanjut, hubungi ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: paymentLang['kontak'], // "Kontak Kami",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeBox(String value, String label,) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _separator() {
    return Column(
      children: [
        Text(
          ":",
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}