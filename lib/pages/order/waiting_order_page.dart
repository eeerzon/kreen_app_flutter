// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/modal/check_payment_modal.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';

class WaitingOrderPage extends StatefulWidget {
  final String id_order;
  final bool formHistory;
  final String? currency_session;
  const WaitingOrderPage({super.key, required this.id_order, this.formHistory = false, required this.currency_session});

  @override
  State<WaitingOrderPage> createState() => _WaitingOrderPageState();
}

class _WaitingOrderPageState extends State<WaitingOrderPage> {
  String? langCode, currencyCode;
  DateTime deadline = DateTime(2025, 10, 17, 13, 30, 00, 00, 00);

  final DateTime now = DateTime.now();
  Duration remaining = Duration.zero;
  Timer? _timer;

  bool _isLoading = true;

  bool tapinstruksi = false;

  bool isExpired = false;

  bool showErrorBar = false;
  String errorMessage = '';

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
      if (difference.isNegative) {
        remaining = Duration.zero;
        isExpired = true;
        _timer?.cancel();
      } else {
        remaining = difference;
      }
    });
  }

  Map<String, dynamic> bahasa = {};

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  Map<String, dynamic> detailOrder = {};
  Map<String, dynamic> voteOder = {};
  List<dynamic> voteOrderDetail = [];
  List<dynamic> finalis = [];
  Map<String, dynamic> paymentDetail = {};
  List<dynamic> instruction = [];
  Map<String, dynamic> vote = {};
  List<dynamic> indikator = [];

  var expiresAt;

  Future<void> _loadOrder() async {

    final resultOrder = await ApiService.get("/order/vote/${widget.id_order}", xLanguage: langCode, xCurrency: currencyCode);
    if (resultOrder == null || resultOrder['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultOrder?['message'];
      });
      return;
    }

    final tempOrder = resultOrder['data'] ?? {};

    final temp_vote_order = tempOrder['vote_order'] ?? {};
    final temp_vote_order_detail = tempOrder['vote_order_detail'] ?? [];
    final tempFinalis = tempOrder['vote_finalis'] ?? [];

    final temp_payment_detail = tempOrder['payment_detail'] ?? {};
    final temp_instruction = temp_payment_detail['instruction'] ?? [];

    final temp_vote = tempOrder['vote'] ?? {};
    final temp_indikator_answer = tempOrder['indikator_answer'] ?? [];

    await _precacheAllImages(context, tempFinalis);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        detailOrder = tempOrder;

        voteOder = temp_vote_order;
        voteOrderDetail = temp_vote_order_detail;
        finalis = tempFinalis;

        paymentDetail = temp_payment_detail;
        instruction = temp_instruction;

        vote = temp_vote;
        indikator = temp_indikator_answer;

        final rawExpires = voteOder['order_created_at'];
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
        showErrorBar = false;
      });
    }
  }

  Future<void> _precacheAllImages(
    BuildContext context,
    List<dynamic> finalis
  ) async {
    List<String> allImageUrls = [];

    // Ambil semua file_upload dari ranking (juara / banner)
    for (var item in finalis) {
      final url = item['poster_finalis']?.toString();
      if (url != null && url.isNotEmpty) {
        allImageUrls.add(url);
      }
    }

    // Hilangkan duplikat supaya efisien
    allImageUrls = allImageUrls.toSet().toList();

    // Pre-cache semua gambar
    for (String url in allImageUrls) {
      await precacheImage(NetworkImage(url), context);
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
      body: Stack(
        children: [
          if (_isLoading)
            buildSkeletonHome()
          else if (isExpired)
            buildLinkKadaluarsa()
          else
            buildKontenOrder(),
            
          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadOrder();
            },
          ),
        ],
      ),
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
    
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    String formattedDate = '-';

    String? currencyRegion;
    if (voteOder['order_region'] == "EU"){
      currencyRegion = "EUR";
    } else if (voteOder['order_region'] == "ID"){
      currencyRegion = "IDR";
    } else if (voteOder['order_region'] == "MY"){
      currencyRegion = "MYR";
    } else if (voteOder['order_region'] == "PH"){
      currencyRegion = "PHP";
    } else if (voteOder['order_region'] == "SG"){
      currencyRegion = "SGD";
    } else if (voteOder['order_region'] == "TH"){
      currencyRegion = "THB";
    } else if (voteOder['order_region'] == "US"){
      currencyRegion = "USD";
    } else if (voteOder['order_region'] == "VN"){
      currencyRegion = "VND";
    }
    
    num sum_amount = voteOder['total_amount'] * voteOder['currency_value_region'];
    num total_amount_pg = num.parse(sum_amount.toStringAsFixed(5)); // konversi ke double (num())
    if (currencyRegion == "IDR") {
      total_amount_pg = total_amount_pg.ceil();
    } else {
      total_amount_pg = (total_amount_pg * 100).ceil() / 100;
    }

    num user_currency_amount = num.parse(voteOder['user_currency_amount'].toStringAsFixed(5)); // konversi ke double (num())
    if (currencyRegion == "IDR") {
      user_currency_amount = user_currency_amount.ceil();
    } else {
      user_currency_amount = (user_currency_amount * 100).ceil() / 100;
    }

    num user_currency_total_payment = num.parse(voteOder['user_currency_total_payment'].toStringAsFixed(5)); // konversi ke double (num())
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
        title: Text(bahasa['header']),
        centerTitle: widget.formHistory ? false : true,
        leading: widget.formHistory
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : SizedBox.shrink(),
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
                          bahasa['dont_close'],
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

                      Text(bahasa['sisa_waktu']),

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
                                  _timeBox("$hours".padLeft(2, "0"), bahasa['hour']),
                                  const SizedBox(width: 10),
                                  _separator(),
                                  const SizedBox(width: 10),
                                  _timeBox("$minutes".padLeft(2, "0"), bahasa['minute']),
                                  const SizedBox(width: 10),
                                  _separator(),
                                  const SizedBox(width: 10),
                                  _timeBox("$seconds".padLeft(2, "0"), bahasa['second']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(bahasa['selesaikan_pembayaran']),
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
                                mainAxisAlignment: paymentDetail['qr_url'] != null || paymentDetail['qr_string'] != null
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.spaceAround,
                                children: [
                                  Image.network(
                                    "$baseUrl/image/payment-method/${voteOder['payment_method_image']}",
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

                                  if (paymentDetail['qr_url'] != null || paymentDetail['qr_string'] != null) ...[
                                    const SizedBox(width: 10,),
                                    Text(
                                      voteOder['bank_code'],
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )
                                  ] else ...[
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
                                            bahasa['instruksi_pembayaran'],
                                            style: TextStyle(color: Colors.blue),
                                          )
                                        ],
                                      ),
                                    )
                                  ]
                                ],
                              ),

                              if (tapinstruksi) ... [
                                const SizedBox(height: 10,),
                                Text(
                                  bahasa['instruksi_pembayaran'],
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

                              if (paymentDetail['qr_url'] != null || paymentDetail['qr_string'] != null) ...[
                                SizedBox(height: 16,),
                                SizedBox(
                                  width: double.infinity,
                                  child: Center(
                                    child: Builder(
                                      builder: (context) {
                                        final qrUrl = paymentDetail['qr_url'];
                                        final qrString = paymentDetail['qr_string'];
                                        
                                        if (qrUrl != null && qrUrl.toString().isNotEmpty) {
                                          return Image.network(
                                            qrUrl,
                                            height: 200,
                                            width: 200,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/img_broken.jpg',
                                                height: 200,
                                                width: 200,
                                              );
                                            },
                                          );
                                        }
                                        
                                        if (qrString != null && qrString.toString().isNotEmpty) {
                                          final generatedUrl =
                                            'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=$qrString';

                                          return Image.network(
                                            generatedUrl,
                                            height: 200,
                                            width: 200,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/img_broken.jpg',
                                                height: 200,
                                                width: 200,
                                              );
                                            },
                                          );
                                        }
                                        
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16,),
                              Text(
                                bahasa['kode_pesanan'],
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 10,),
                              Text(
                                voteOder['invoice_number'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              if (paymentDetail['va_number'] != null && paymentDetail['va_number'] != "") ...[

                                const SizedBox(height: 25,),
                                Text(
                                  bahasa['nomor_pembayaran'],
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
                                          content: Text(bahasa['copyVA']),
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
                                '${bahasa['total_pembayaran']} ($currencyRegion)',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 10,),
                              Text(
                                '$currencyRegion ${formatter.format(total_amount_pg)}',
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
                                      vote['banner_vote'],
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/img_broken.jpg',
                                          height: 80,
                                          width: 80,
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 10,),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vote['judul_vote'],
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),

                                        const SizedBox(height: 8,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: List.generate(finalis.length, (i) {
                                            return Text(
                                              '- ${finalis[i]['nama_finalis']} ${voteOrderDetail[i]['qty']} vote(s)',
                                              style: const TextStyle(color: Colors.grey),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20,),
                              Text(
                                bahasa['ringkasan_pembayaran'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bahasa['total_harga'],
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
                                    bahasa['biaya_layanan'],
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
                                    bahasa['total_pembayaran'],
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
                        height: 48,
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
                            bahasa['check_status'],
                            style: TextStyle( fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),

                      if (!widget.formHistory) ... [
                        const SizedBox(height: 20,),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pushReplacement(
                                context, 
                                MaterialPageRoute(builder: (context) => HomePage()),
                              );
                            },
                            child: Text(
                              bahasa['kembali'],
                              style: TextStyle( fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(bahasa['header']),
        centerTitle: widget.formHistory ? false : true,
        leading: widget.formHistory
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : SizedBox.shrink(),
      ),

      body: Center(
        child: Container(
          width: double.infinity,
          padding: kGlobalPadding,
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
                          width: 220,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
          
                  const SizedBox(height: 20),
                  Text(
                    bahasa['link_kadaluarsa'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          
                  const SizedBox(height: 10),
                  Text(
                    bahasa['link_kadaluarsa_desc'],
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
                      if (widget.formHistory) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                              DetailVotePage(id_event: vote['id_vote'].toString()),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      }
                    },
                    child: Text(
                      bahasa['transaksi_lagi'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      text: bahasa['kendala'],
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: bahasa['kontak'],
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
        SizedBox(height: 20), // biar sejajar dengan label bawah
      ],
    );
  }
}