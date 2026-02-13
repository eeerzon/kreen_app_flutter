
// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, prefer_typing_uninitialized_variables

import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/pages/event/detail_event/tiket_event.dart';
import 'package:kreen_app_flutter/pages/event/detail_event/tiket_global.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailEventPage extends StatefulWidget {
  final String id_event;
  final num price;
  final String? currencyCode;

  const DetailEventPage({
    super.key, 
    required this.id_event, 
    required this.price,
    this.currencyCode,
  });

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  String? langCode;

  bool _isLoading = true;

  List<int> counts = [];
  List<int> counts_tiket = [];
  List<String> ids_tiket = [];
  List<String> names_tiket = [];
  List<num> prices_tiket = [];
  List<num> prices_tiket_asli = [];
  List<int?> selected_tiket = [];

  Map<String, dynamic> bahasa = {};
  String? notLoginText, notLoginDesc, login;

  var customSection;
  List<dynamic> sections = [];

  bool showErrorBar = false;
  String errorMessage = '';

  Timer? _timer;

  String getTicketStatus(Map<String, dynamic> ticket) {
    try {
      final now = DateTime.now().toUtc();

      final start = DateTime.parse(ticket['sale_datetime_start']);
      final end = DateTime.parse(ticket['sale_datetime_end']);

      if (now.isBefore(start)) {
        return 'not_started';
      } else if (!now.isBefore(end)) {
        return 'ended';
      } else {
        return 'open';
      }
    } catch (_) {
      return 'invalid';
    }
  }

  void startTicketWatcher(List tickets) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }
  
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadEvent();

      startTicketWatcher(event['event_ticket'] ?? []);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> event = {};

  Future<void> _loadEvent() async {
    final body = {
      "id_event": widget.id_event,
    };

    final resultEvent = await ApiService.post('/event/detail', body: body, xCurrency: currencyCode, xLanguage: langCode);
    if (resultEvent == null || resultEvent['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultEvent?['message'];
      });
      return;
    }
    final Map<String, dynamic> tempEvent = resultEvent['data'] ?? {};

    await _precacheAllImages(context, tempEvent);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        event = tempEvent;

        counts = List<int>.filled(event['event_ticket'].length, 0);
        selected_tiket = List.filled(event['event_ticket'].length, null);

        _isLoading = false;
        showErrorBar = false;
      });
    }
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
      notLoginText = bahasa['notLogin'];
      notLoginDesc = bahasa['notLoginDesc'];
      login = bahasa['login'];
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  Future<void> _precacheAllImages(
    BuildContext context,
    Map<String, dynamic> event,
  ) async {
    List<String> allImageUrls = [];
    
    final eventData = event['data'];
    if (eventData is List) {
      for (var item in eventData) {
        final url = item['event']['img_organizer']?.toString();
        if (url != null && url.isNotEmpty) {
          allImageUrls.add(url);
        }
      }
    }

    // Hilangkan duplikat supaya efisien
    allImageUrls = allImageUrls.toSet().toList();

    // Pre-cache semua gambar
    for (String url in allImageUrls) {
      await precacheImage(NetworkImage(url), context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
            ? buildSkeleton()
            : buildKontenEvent(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadEvent();
            },
          ),
        ],
      ),
    );
  }

  Widget buildSkeleton() {
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

  bool get isButtonEnabled => counts.isNotEmpty && counts.any((c) => c > 0);

  Widget buildKontenEvent() {
    final formatter = NumberFormat.decimalPattern("en_US");

    var detailEvent = event['event'];
    List<dynamic> eventTiket = event['event_ticket'] ?? [];
    // var eventDate = event['eventdate'][0];
    var eventDateTime = event['event_datetime'] ?? [];

    if (event['custom_section'] != null && event['custom_section'].isNotEmpty) {
      customSection = event['custom_section'] as Map<String, dynamic>;
    
      sections = customSection.values.map((section) {
        return {
          'label': section['label'],
          'items': (section['isi'] as Map<String, dynamic>).values.toList()
        };
      }).toList();
    }

    final activeTickets = eventTiket
      .where((e) => e['flag_aktif'] == 1)
      .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(detailEvent['title']), // ambil dari api
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context, currencyCode);
          },
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: InkWell(
            onTap: isButtonEnabled
              ? () async {
                final getUser = await StorageService.getUser();

                String? idUser = getUser['id'];

                if (detailEvent['jenis_participant'] == 'Umum') {
                  final token = await StorageService.getToken();

                  if (token == null) {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.noHeader,
                      animType: AnimType.scale,
                      dismissOnTouchOutside: true,
                      body: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 30,
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 16,),
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
                            )
                          ),

                          const SizedBox(height: 24),
                          Text(
                            notLoginText!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),
                          Text(
                            notLoginDesc!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 14),
                          ),

                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => const LoginPage(notLog: true,)),
                              );
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
                              login!,
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ).show();
                  } else {
                    if (detailEvent['flag_only_bayer'] == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TiketGlobalPage(
                            id_event: widget.id_event,
                            price_global: widget.price,
                            qty: counts_tiket,
                            ids_tiket: ids_tiket,
                            namas_tiket: names_tiket,
                            prices_tiket: prices_tiket,
                            prices_tiket_asli: prices_tiket_asli,
                            flag_samakan_input_tiket_pertama: detailEvent['flag_samakan_input_tiket_pertama'],
                            jenis_participant: detailEvent['jenis_participant'],
                            idUser: idUser,
                            rateCurrency: detailEvent['rate_currency_event'],
                            rateCurrencyUser: detailEvent['rate_currency_user'],
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TiketEventPage(
                            id_event: widget.id_event,
                            price_global: widget.price,
                            qty: counts_tiket,
                            ids_tiket: ids_tiket,
                            namas_tiket: names_tiket,
                            prices_tiket: prices_tiket,
                            prices_tiket_asli: prices_tiket_asli,
                            flag_samakan_input_tiket_pertama: detailEvent['flag_samakan_input_tiket_pertama'],
                            jenis_participant: detailEvent['jenis_participant'],
                            idUser: idUser,
                            rateCurrency: detailEvent['rate_currency_event'],
                            rateCurrencyUser: detailEvent['rate_currency_user'],
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  if (detailEvent['flag_only_bayer'] == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TiketGlobalPage(
                          id_event: widget.id_event,
                          price_global: widget.price,
                          qty: counts_tiket,
                          ids_tiket: ids_tiket,
                          namas_tiket: names_tiket,
                          prices_tiket: prices_tiket,
                          prices_tiket_asli: prices_tiket_asli,
                          flag_samakan_input_tiket_pertama: detailEvent['flag_samakan_input_tiket_pertama'],
                          jenis_participant: detailEvent['jenis_participant'],
                          idUser: idUser,
                          rateCurrency: detailEvent['rate_currency_event'],
                          rateCurrencyUser: detailEvent['rate_currency_user'],
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TiketEventPage(
                          id_event: widget.id_event,
                          price_global: widget.price,
                          qty: counts_tiket,
                          ids_tiket: ids_tiket,
                          namas_tiket: names_tiket,
                          prices_tiket: prices_tiket,
                          prices_tiket_asli: prices_tiket_asli,
                          flag_samakan_input_tiket_pertama: detailEvent['flag_samakan_input_tiket_pertama'],
                          jenis_participant: detailEvent['jenis_participant'],
                          idUser: idUser,
                          rateCurrency: detailEvent['rate_currency_event'],
                          rateCurrencyUser: detailEvent['rate_currency_user'],
                        ),
                      ),
                    );
                  }
                }
              }
              : null,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isButtonEnabled ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.confirmation_number_rounded, color: Colors.white),
                  SvgPicture.network(
                    '$baseUrl/image/ticket-white.svg',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 8),
                  Text(
                    bahasa['beli_tiket'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          //konten
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image.network(
                      //   detailEvent['img_organizer']?.toString().isNotEmpty == true
                      //       ? detailEvent['img_organizer']
                      //       : 'https://via.placeholder.com/600x300?text=No+Image',
                      //   fit: BoxFit.cover,
                      //   width: double.infinity,
                      // ),

                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/img_placeholder.jpg',
                          image: detailEvent['img_organizer'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/img_broken.jpg',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: kGlobalPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detailEvent['category_name'],
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Text(
                                  detailEvent['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Share.share(
                                "$baseUrl/ticket-event/${detailEvent['slug']}",
                                subject: detailEvent['title'],
                              );
                            },
                            child: SvgPicture.network(
                              '$baseUrl/image/share-red.svg',
                              height: 20,
                              width: 20,
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 70, // cukup untuk 2 row chip
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event['status'],
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                detailEvent['flag_private'] == 1
                                ? "Private Event"
                                : 'Public Event',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                detailEvent['type_event'],
                                style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event['harga_max'] == 0
                                ? bahasa['harga_detail']
                                : bahasa['berbayar'],
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Image.network(
                            detailEvent['banner'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                            Image.asset(
                              'assets/images/img_broken.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(width: 12),
                          //text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bahasa['penyelenggara'],
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),

                                SizedBox(height: 4),
                                Text(
                                  detailEvent['organizer'],
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  softWrap: true,
                                  overflow: TextOverflow.visible, 
                                ),

                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (detailEvent['link_ig'] != null)
                                      _buildSocialButton(
                                        iconUrl: "$baseUrl/image/ig.svg",
                                        link: detailEvent['link_ig'],
                                        platform: "instagram",
                                      ),

                                    if (detailEvent['link_fb'] != null)
                                      _buildSocialButton(
                                        iconUrl: "$baseUrl/image/fb.svg",
                                        link: detailEvent['link_fb'],
                                        platform: "facebook",
                                      ),

                                    if (detailEvent['link_tiktok'] != null)
                                      _buildSocialButton(
                                        iconUrl: "$baseUrl/image/tiktok.svg",
                                        link: detailEvent['link_tiktok'],
                                        platform: "tiktok",
                                      ),

                                    if (detailEvent['link_youtube'] != null)
                                      _buildSocialButton(
                                        iconUrl: "$baseUrl/image/web.svg",
                                        link: detailEvent['link_web'],
                                        platform: "website",
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // if (event['event']['description'] != null) ... [

                      //   SizedBox(height: 20,),
                      //   Text(
                      //     eventLang['tentang_event_label'],
                      //     style: TextStyle( fontWeight: FontWeight.bold),
                      //   ),
                        
                      //   SizedBox(height: 12,),
                      //   Padding(
                      //     padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
                      //     child: Html(
                      //       data: event['event']['description'] ?? '-',
                      //         style: {
                      //           "p": Style(
                      //             margin: Margins.zero,
                      //             padding: HtmlPaddings.zero,
                      //           ),
                      //           "body": Style(
                      //             margin: Margins.zero,
                      //             padding: HtmlPaddings.zero,
                      //           ),
                      //         },
                      //     ),
                      //   ),
                      // ],

                      const SizedBox(height: 20),
                      Text(
                        bahasa['tgl_waktu_label'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12,),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SvgPicture.network(
                                "$baseUrl/image/Calendar.svg",
                                width: 30,
                                height: 30,
                                fit: BoxFit.contain,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(eventDateTime.length, (idx) {
                                    final item = eventDateTime[idx];
                                    String formattedDate = '-';
                                    String dateStr = item['date_event'];
    
                                    if (dateStr.isNotEmpty) {
                                      try {
                                        // parsing string ke DateTime
                                        final date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
                                        if (langCode == 'id') {
                                          // Bahasa Indonesia
                                          final formatter = DateFormat("$formatDay, $formatDateId", "id_ID");
                                          formattedDate = formatter.format(date);
                                        } else {
                                          // Bahasa Inggris
                                          final formatter = DateFormat("$formatDay, $formatDateEn", "en_US");
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

                                    String formatTime(String time) {
                                      final t = DateFormat("HH:mm:ss").parse(time);
                                      return DateFormat("HH:mm").format(t);
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: idx == eventDateTime.length - 1 ? 0 : 8,),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${formatTime(item['time_start'])} - ${formatTime(item['time_end'])} (${detailEvent['code_timezone']})",
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        bahasa['lokasi'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12,),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SvgPicture.network(
                                    "$baseUrl/image/Locations.svg",
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(width: 12),
                                  //text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          detailEvent['type_event'] == 'offline'
                                          ? detailEvent['location_map'] ?? '-'
                                          : "${detailEvent['type_event']} via ${detailEvent['venue_platform']}",
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ) 
                      ),

                      // const SizedBox(height: 20),
                      // Text(
                      //   "venue",
                      //   style: TextStyle(fontWeight: FontWeight.bold),
                      // ),

                      // const SizedBox(height: 12,),
                      // Container(
                      //   color: Colors.white,
                      //   child: Padding(
                      //     padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      //     child: Column(
                      //       children: [
                      //         Row(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: <Widget>[
                      //             SvgPicture.network(
                      //               "$baseUrlimage/Locations.svg",
                      //               width: 30,
                      //               height: 30,
                      //               fit: BoxFit.contain,
                      //             ),

                      //             const SizedBox(width: 12),
                      //             //text
                      //             Expanded(
                      //               child: Column(
                      //                 crossAxisAlignment: CrossAxisAlignment.start,
                      //                 mainAxisAlignment: MainAxisAlignment.center,
                      //                 children: [
                      //                   Text(
                      //                     detailEvent['venue_name'] ?? '-',
                      //                     style: TextStyle(
                      //                       color: Colors.black,
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ],
                      //     ),
                      //   ) 
                      // ),

                      // const SizedBox(height: 12,),
                      // Text(
                      //   "Harga",
                      //   style: TextStyle(fontWeight: FontWeight.bold),
                      // ),
                      // const SizedBox(height: 12,),
                      // Text(
                      //   hargaFormatted,
                      //   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                      // ),

                      if (event['speaker'] != null && event['speaker'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['pembicara'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['speaker'].length, (index) {
                                final item = event['speaker'][index];
                                final isLast = index == event['speaker'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'] ?? '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                item['profession'] != null && item['profession'] != "" ? item['profession'] : '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      ],

                      if (event['moderator'] != null && event['moderator'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['moderator'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['moderator'].length, (index) {
                                final item = event['moderator'][index];
                                final isLast = index == event['moderator'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'] ?? '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                item['profession'] != null && item['profession'] != "" ? item['profession'] : '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            )
                          )
                        )
                      ],

                      if (event['doorprize'] != null && event['doorprize'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['doorprize'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['doorprize'].length, (index) {
                                final item = event['doorprize'][index];
                                final isLast = index == event['doorprize'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name_doorprize'] ?? '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "${item['qty']} ${item['type_qty']}",
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      ],

                      if (event['sponsor'] != null && event['sponsor'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['sponsor'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['sponsor'].length, (index) {
                                final item = event['sponsor'][index];
                                final isLast = index == event['sponsor'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'],
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      ],

                      if (event['media_partner'] != null && event['media_partner'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['media_partner'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['media_partner'].length, (index) {
                                final item = event['media_partner'][index];
                                final isLast = index == event['media_partner'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'],
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      ],

                      if (event['supported'] != null && event['supported'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['supported'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['supported'].length, (index) {
                                final item = event['supported'][index];
                                final isLast = index == event['supported'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'],
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      ],

                      if (event['guest_star'] != null && event['guest_star'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['guest_star'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['guest_star'].length, (index) {
                                final item = event['guest_star'][index];
                                final isLast = index == event['guest_star'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'] ?? '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),

                                              SizedBox(height: 4),
                                              Text(
                                                item['performance_type'] != null && item['performance_type'] != "" ? item['performance_type'] : '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            )
                          )
                        )
                      ],

                      if (event['special_perform'] != null && event['special_perform'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          bahasa['special_perform'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              children: List.generate(event['special_perform'].length, (index) {
                                final item = event['special_perform'][index];
                                final isLast = index == event['special_perform'].length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Center(
                                              child: Image.network(
                                                item['img'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.contain,
                                                    width: 50,
                                                    height: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        //text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['name'] ?? '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              
                                              SizedBox(height: 4),
                                              Text(
                                                item['performance_type'] != null && item['performance_type'] != "" ? item['performance_type'] : '-',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (!isLast) const SizedBox(height: 10),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      ],

                      if (event['custom_section'] != null && event['custom_section'].isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          sections[0]['label'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sections.map((section) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    ...section['items'].map<Widget>((item) {
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(50),
                                              child: Center(
                                                child: Image.network(
                                                  item['img'],
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Image.asset(
                                                      'assets/images/img_broken.jpg',
                                                      fit: BoxFit.contain,
                                                      width: 50,
                                                      height: 50,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),
                                          //text
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item['name'] ?? '-',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),

                                                SizedBox(height: 4),
                                                Text(
                                                  item['title'] ?? '-',
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      ],

                      const SizedBox(height: 30,),
                      if (activeTickets.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ]),
                                child: Image.network(
                                  '$baseUrl/image/no-ticket.png',
                                  width: 220,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                bahasa['tiket_tidak_tersedia'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(activeTickets.length, (index) {
                          final item = activeTickets[index];

                          final dateStr = item['sale_datetime_end_plus_diff']?.toString() ?? '-';
      
                          String formattedDate = '-';
                          
                          if (dateStr.isNotEmpty) {
                            try {
                              // parsing string ke DateTime
                              final date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
                              if (langCode == 'id') {
                                // Bahasa Indonesia
                                final dayName = DateFormat(formatDay, "id_ID").format(date);
                                final datePart = DateFormat(formatDateId, "id_ID").format(date);
                                formattedDate = "$dayName,\n$datePart";
                              } else {
                                // Bahasa Inggris
                                final dayName = DateFormat(formatDay, "en_US").format(date);
                                final datePart = DateFormat(formatDateEn, "en_US").format(date);

                                // tambahkan suffix (1st, 2nd, 3rd, 4th...)
                                final day = date.day;
                                String suffix = 'th';
                                if (day % 10 == 1 && day != 11) { suffix = 'st'; }
                                else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
                                else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }

                                final datePartWithSuffix = datePart.replaceFirst('$day', '$day$suffix');
                                formattedDate = "$dayName,\n$datePartWithSuffix";
                              }
                            } catch (e) {
                              formattedDate = '-';
                            }
                          }

                          String hargaFormatted = '-';
                          hargaFormatted = currencyCode == null
                            ? "${detailEvent['currency']} ${formatter.format(item['price'] ?? 0)}"
                            : "$currencyCode ${formatter.format(item['price'] ?? 0)}";
                          if (item['price'] == 0) {
                            hargaFormatted = bahasa['harga_detail'];
                          }

                          final dateOutTiket = DateTime.parse("${item['sale_date_end']} ${item['sale_time_end']}");
                          final bool sudahTutup = DateTime.now().isAfter(dateOutTiket) || item['sisa_stok'] == 0 || item['sisa_stok'] < 0;

                          final text = bahasa['batas_event']
                            .replaceAll('{qty}', item['max_qty'].toString());

                          final status = getTicketStatus(item);

                          return item['flag_aktif'] == 1 
                            ? Padding(
                                padding: EdgeInsets.only(bottom: 25),
                                child: Container(
                                  width: double.infinity,
                                  padding: kGlobalPadding,
                                  decoration: BoxDecoration(
                                    color: sudahTutup ? Colors.grey.shade300 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300,),
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        SvgPicture.network(
                                          "$baseUrl/image/barcode.svg",
                                          fit: BoxFit.fitHeight,
                                        ),

                                        SizedBox(width: 8,),
                                        Container(
                                          width: 1.2,
                                          color: Colors.grey.shade400,
                                        ),

                                        SizedBox(width: 12,),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name_ticket'],
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),

                                              SizedBox(height: 8,),
                                              Text(
                                                item['description_ticket'],
                                                softWrap: true,
                                              ),

                                              SizedBox(height: 8,),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  SvgPicture.network(
                                                    "$baseUrl/image/Locations.svg",
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.contain,
                                                  ),

                                                  SizedBox(width: 10,),
                                                  Container(
                                                    width: 1.2,
                                                    height: 30,
                                                    color: Colors.grey.shade400,
                                                  ),

                                                  SizedBox(width: 10,),
                                                  Text(
                                                    '${bahasa['berakhir']} $formattedDate',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(height: 12,),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        hargaFormatted,
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      ),
                                                  
                                                      SizedBox(width: 10,),
                                                      Container(
                                                        width: 1.2,
                                                        height: 30,
                                                        color: Colors.grey.shade400,
                                                      ),
                                                    ],
                                                  ),

                                                  SizedBox(width: 40,),
                                                  status == 'not_started'
                                                    ? Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        child: Text(
                                                          bahasa['segera'],
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      )

                                                    : status == 'ended'
                                                        ? Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            child: Text(
                                                              bahasa['habis'],
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                                color: Colors.red,
                                                              ),
                                                            ),
                                                          )

                                                        : Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                children: [
                                                                  InkWell(
                                                                    onTap: counts[index] > 0
                                                                        ? () {
                                                                            setState(() {
                                                                              counts[index]--;
                                                                              _syncSelectedTickets();
                                                                            });
                                                                          }
                                                                        : null,
                                                                    child: Container(
                                                                      padding: const EdgeInsets.all(8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.red,
                                                                        borderRadius: BorderRadius.circular(100),
                                                                      ),
                                                                      child: const Icon(
                                                                        FontAwesomeIcons.minus,
                                                                        size: 15,
                                                                        color: Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Text(
                                                                    counts[index].toString(),
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 16,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        final maxQty = item['max_qty'];
                                                                        final sisaStok = item['sisa_stok'];

                                                                        final limit =
                                                                            sisaStok < maxQty ? sisaStok : maxQty;

                                                                        if (counts[index] < limit) {
                                                                          counts[index]++;
                                                                          _syncSelectedTickets();
                                                                        }
                                                                      });
                                                                    },
                                                                    child: Container(
                                                                      padding: const EdgeInsets.all(8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.red,
                                                                        borderRadius: BorderRadius.circular(100),
                                                                      ),
                                                                      child: const Icon(
                                                                        FontAwesomeIcons.plus,
                                                                        size: 15,
                                                                        color: Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          )
                                                ],
                                              ),

                                              Text(
                                                detailEvent['show_tickets_available'] == 1 && !sudahTutup
                                                  ? '${bahasa['stok_tiket']}: ${item['sisa_stok']}'
                                                  : '',
                                                style: TextStyle(color: Colors.grey),
                                              ),

                                              if (counts[index] == item['max_qty']) ... [

                                                SizedBox(height: 4,),

                                                Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    "* $text",
                                                    style: const TextStyle(color: Colors.red),
                                                  )
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _syncSelectedTickets() {
    ids_tiket.clear();
    names_tiket.clear();
    counts_tiket.clear();
    prices_tiket.clear();
    prices_tiket_asli.clear();

    for (int i = 0; i < event['event_ticket'].length; i++) {
      final item = event['event_ticket'][i];
      final count = counts[i];
      if (count > 0) {
        ids_tiket.add(item['id_event_ticket']);
        names_tiket.add(item['name_ticket']);
        counts_tiket.add(count);
        prices_tiket.add(item['price']);
        prices_tiket_asli.add(item['price_asli'] ?? 0);
      }
    }
  }


  Widget _buildSocialButton({
    required String iconUrl,
    required String? link,
    required String platform,
  }) {
    final bool isEmpty = link == null || link.trim().isEmpty;

    return GestureDetector(
      onTap: isEmpty
          ? null
          : () async {
              Uri? uri = Uri.tryParse(link);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                await launchUrl(Uri.parse("https://google.com"), mode: LaunchMode.externalApplication);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: SvgPicture.network(
          iconUrl,
          height: 30,
          width: 30,
          colorFilter: isEmpty
              ? const ColorFilter.mode(Colors.grey, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}