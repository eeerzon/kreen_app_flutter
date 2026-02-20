// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/pages/content_info/profile.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:kreen_app_flutter/helper/widget_webview.dart';
import 'package:kreen_app_flutter/helper/auto_play_carousel.dart';
import 'package:shimmer/shimmer.dart';

class HomeContent extends StatefulWidget {
  final VoidCallback onSeeMoreVote;
  final VoidCallback onSeeMoreEvent;

  const HomeContent({
    super.key,
    required this.onSeeMoreVote,
    required this.onSeeMoreEvent,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? login;
  String? token;
  Map<String, dynamic> bahasa = {};

  String? selamatDatang, first_name, photo_user;

  String? event_title, event_desc, event_recomen;
  String? vote_title, latest_vote;
  String? comingsoon_title, comingsoon_desc;
  String? partner, partner_btn;
  String? news_title, news_desc;
  String? leaderboard_title;
  String? seeMore;

  bool isLoadingContent = true;
  
  bool showErrorBar = false;
  String errorMessage = ''; 

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadContent();
    });
  }

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();

    if (!mounted) return;
    setState(() {
      token = storedToken;
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;

      selamatDatang = bahasa['top_nav'];
      login = bahasa['login'];
      event_title = bahasa['event_title'];
      event_recomen = bahasa['event_recomen'];
      event_desc = bahasa['event_desc'];

      vote_title = bahasa['vote_title'];
      latest_vote = bahasa['latest_vote'];

      leaderboard_title = bahasa['leaderboard_title'];

      comingsoon_title = bahasa['comingsoon_title'];
      comingsoon_desc = bahasa['comingsoon_desc'];

      partner = bahasa['partner'];
      partner_btn = bahasa['partner_btn'];

      news_title = bahasa['news_title'];
      news_desc = bahasa['news_desc'];

      seeMore = bahasa['more'];
    });
  }

  Future<void> _getCurrency() async {
    var code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  List<dynamic> activeBanners = [];
  List<double?> aspectRatios = [];

  List<dynamic> votes = [];
  List<dynamic> juara = [];
  List<dynamic> hitsevent = [];
  List<dynamic> latestvotes = [];
  List<dynamic> recomenevent = [];
  List<dynamic> listArtikel = [];

  List<dynamic> closePayment = [];
  List<dynamic> tglBukaVote = [];

  Future<void> _loadContent() async {

    await _checkToken();

    var get_user = await StorageService.getUser();
    first_name = get_user['first_name'];

    final resultbanner = await ApiService.get("/setting-banner/active", xLanguage: langCode);
    if (resultbanner == null || resultbanner['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultbanner?['message'];
      });
      return;
    }

    final resultVote = await ApiService.get("/vote/popular", xCurrency: currencyCode, xLanguage: langCode);
    if (resultVote == null || resultVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultVote?['message'];
      });
      return;
    }

    final resultJuara = await ApiService.get("/vote/juara", xLanguage: langCode);
    if (resultJuara == null || resultJuara['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultJuara?['message'];
      });
      return;
    }

    final resulthitEvent = await ApiService.get("/event/hits", xCurrency: currencyCode, xLanguage: langCode);
    if (resulthitEvent == null || resulthitEvent['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resulthitEvent?['message'];
      });
      return;
    }

    final resultlatestVote = await ApiService.get("/vote/latest", xCurrency: currencyCode, xLanguage: langCode);
    if (resultlatestVote == null || resultlatestVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultlatestVote?['message'];
      });
      return;
    }

    final resultrecomenEvent = await ApiService.get("/event/recommended", xCurrency: currencyCode, xLanguage: langCode);
    if (resultrecomenEvent == null || resultrecomenEvent['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultrecomenEvent?['message'];
      });
      return;
    }

    final resultArtikel = await ApiService.get("/articles?limit=8", xLanguage: langCode);
    if (resultArtikel == null || resultArtikel['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultArtikel?['message'];
      });
      return;
    }

    final now = DateTime.now();
    final allBanners = resultbanner['data'] as List<dynamic>? ?? [];

    final filtered = allBanners.where((banner) {
      final takedownDateStr = banner['takedown_date']?.toString();
      if (takedownDateStr == null || takedownDateStr.isEmpty) return true;

      final takedownDate = DateTime.tryParse(takedownDateStr);
      if (takedownDate == null) return true;

      return now.isBefore(takedownDate);
    }).toList();

    final tempActiveBanners = filtered;
    final tempVotes = resultVote['data'] ?? [];
    
    final rawData = resultJuara['data'];

    List<dynamic> tempJuara = [];

    if (rawData is Map<String, dynamic>) {
      tempJuara = rawData.values.toList();
    } else if (rawData is List) {
      tempJuara = rawData;
    }

    final tempHitsevent = resulthitEvent['data'] ?? [];
    final tempLatestVotes = resultlatestVote['data'] ?? [];
    final tempRecomenEvent = resultrecomenEvent['data'] ?? [];
    final tempListArtikel = resultArtikel['data'] ?? [];
    
    await _precacheAllImages(context, tempActiveBanners, tempVotes);

    if (!mounted) return;
    if (mounted) {
      setState(() {

        photo_user = get_user['photo'];

        activeBanners = tempActiveBanners;
        votes = tempVotes;
        juara = tempJuara;
        hitsevent = tempHitsevent;
        latestvotes = tempLatestVotes;
        recomenevent = tempRecomenEvent;
        listArtikel = tempListArtikel;

        preloadImageSizes();
        isLoadingContent = false;
        showErrorBar = false;
      });
    }
  }

  Future<void> _precacheAllImages(BuildContext context, List<dynamic> banners, List<dynamic> votes) async {
    List<String> allImageUrls = [];

    // ambil semua file_upload dari banner
    for (var item in banners) {
      final url = item['file_upload']?.toString();
      if (url != null && url.isNotEmpty) allImageUrls.add(url);
    }

    // ambil semua img dari vote populer
    for (var item in votes) {
      final url = item['img']?.toString();
      if (url != null && url.isNotEmpty) allImageUrls.add(url);
    }

    // hilangkan duplikat biar efisien
    allImageUrls = allImageUrls.toSet().toList();

    // pre-cache semua gambar
    for (String url in allImageUrls) {
      await precacheImage(NetworkImage(url), context);
    }
  }

  void preloadImageSizes() {
    aspectRatios = List<double?>.filled(activeBanners.length, null);

    for (int i = 0; i < activeBanners.length; i++) {
      final url = activeBanners[i]['file_upload'];
      final image = Image.network(url).image;

      image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          final width = info.image.width.toDouble();
          final height = info.image.height.toDouble();
          setState(() {
            aspectRatios[i] = width / height;
          });
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          isLoadingContent
            ? buildSkeletonHome()
            : buildKontenHome(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadContent();
            },
          ),
        ],
      ),
    ); 
  }

  Widget buildSkeletonHome() {
    return Scaffold(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 40, width: 40, color: Colors.white),
                    Container(height: 40, width: 100, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Carousel shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Section title shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Row(
                  children: [
                    Container(height: 30, width: 30, color: Colors.white),
                    const SizedBox(width: 10),
                    Container(height: 20, width: 180, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal cards shimmer
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 200,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 180,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(height: 14, width: 160, color: Colors.white),
                                    const SizedBox(height: 6),
                                    Container(height: 12, width: 100, color: Colors.white),
                                    const SizedBox(height: 6),
                                    Container(height: 12, width: 80, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 30),

              // Leaderboard shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Container(height: 20, width: 200, color: Colors.white),
                    const SizedBox(height: 20),
                    ...List.generate(3, (index) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get isSvg {
    final p = photo_user;
    if (p == null) return false;
    return p.toLowerCase().endsWith(".svg");
  }

  bool get isHttp {
    final p = photo_user;
    if (p == null) return false;
    return p.toLowerCase().contains("http");
  }

  Widget buildKontenHome() {
    return Scaffold(
      // konten page
      body: RefreshIndicator(
        onRefresh: _loadContent,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            color: Colors.grey[200],
            child: Column(
              children: [
                //top logo dan button
                Container(
                  color: Colors.red,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget> [
                            //logo
                            Image.asset(
                              "assets/images/avata_logo.png",
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                    
                            //button
                            token == null
                              ? Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 180),
                                    child: IntrinsicWidth(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          backgroundColor: const Color(0xFFFFDFE0),
                                        ),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LoginPage(),
                                            ),
                                          );
                                          await _checkToken();
                                        },
                                        child: Text(
                                          login!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : 
                              // Expanded(
                              //     child: Container(
                              //       margin: const EdgeInsets.only(left: 180),
                              //       alignment: Alignment.centerRight,
                              //       child: InkWell(
                              //         borderRadius: BorderRadius.circular(30),
                              //         onTap: () {
                              //         },
                              //         child: Container(
                              //           padding: const EdgeInsets.all(8),
                              //           decoration: BoxDecoration(
                              //             color: Colors.white.withOpacity(0.2),
                              //             shape: BoxShape.circle,
                              //           ),
                              //           child: const Icon(
                              //             Icons.notifications,
                              //             color: Colors.white,
                              //             size: 26,
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ),

                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Profile(),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  child: ClipOval(
                                    child: photo_user != null 
                                      ?
                                        isSvg
                                          ? SvgPicture.network(
                                              '$baseUrl/user/$photo_user',
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.fill,
                                            )
                                          : isHttp
                                            ? Image.network(
                                                photo_user!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.fill,
                                              )
                                            : Image.network(
                                                '$baseUrl/user/$photo_user',
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.fill,
                                              )
                                      : Image.network(
                                          "$baseUrl/noimage_finalis.png",
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.fill,
                                        )
                                  ),
                                ),
                              ),
                            
                          ],
                        ),
                    
                        //text selamat datang
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text( first_name != null
                            ? 'Hi, $first_name'
                            : selamatDatang!,
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    
                        // const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // === Image Slider ===
                AutoPlayCarousel(
                  images: activeBanners.map((e) => e['file_upload'] as String).toList(),
                  data: activeBanners,
                  aspectRatios: aspectRatios,
                  bahasa: bahasa,
                ),

                Container(
                  height: 20,
                  color: Colors.white,
                ),
                

                //icon
                // Container(
                //   color: Colors.white,
                //   child: Padding(
                //     padding: const EdgeInsets.all(30),
                //     child: Container(
                //       child: Column(
                //         children: [
                //           Row(
                //             mainAxisAlignment: MainAxisAlignment.spaceAround,
                //             children: <Widget>[
                //               Column(
                //                 children: [
                //                   GestureDetector(
                //                     onTap: () async {
                //                       await Navigator.push(
                //                         context,
                //                         MaterialPageRoute(builder: (_) => const VotePage()),
                //                       );
                //                     },
                //                     child: Container(
                //                       child: Image.asset(
                //                         "assets/images/vote.png",
                //                         width: 55,
                //                         height: 55,
                //                         fit: BoxFit.contain,
                //                       ),
                //                     ),
                //                   ),

                //                   Container(
                //                     child: Text("Vote",
                //                       style: TextStyle(color: Colors.black),
                //                     ),
                //                   )
                //                 ],
                //               ),

                //               Column(
                //                 children: [
                //                   GestureDetector(
                //                     onTap: () async {
                //                       await Navigator.push(
                //                         context,
                //                         MaterialPageRoute(builder: (_) => const EventPage()),
                //                       );
                //                     },
                //                     child: Container(
                //                       child: Image.asset(
                //                         "assets/images/event.png",
                //                         width: 55,
                //                         height: 55,
                //                         fit: BoxFit.contain,
                //                       ),
                //                     ),
                //                   ),

                //                   Container(
                //                     child: Text("Event",
                //                       style: TextStyle(color: Colors.black),
                //                     ),
                //                   )
                //                 ],
                //               ),

                //               Column(
                //                 children: [
                //                   GestureDetector(
                //                     onTap: () async {
                //                       await Navigator.push(
                //                         context,
                //                         MaterialPageRoute(builder: (_) => const CharityPage()),
                //                       );
                //                     },
                //                     child: Container(
                //                       child: Image.asset(
                //                         "assets/images/charity.png",
                //                         width: 55,
                //                         height: 55,
                //                         fit: BoxFit.contain,
                //                       ),
                //                     ),
                //                   ),
                                  
                //                   Container(
                //                     child: Text("Charity",
                //                       style: TextStyle(color: Colors.black),
                //                     ),
                //                   )
                //                 ],
                //               ),
                //             ],
                //           )
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                //vote populer
                const SizedBox(height: 20),
                //loop data
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // SvgPicture.network(
                            //   '$baseUrl/image/home/vote-populer.png',
                            //   width: 30,
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),

                            Image.network(
                              '$baseUrl/image/home/vote-populer.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/img_broken.jpg',
                                  fit: BoxFit.contain,
                                  width: 30,
                                  height: 30,
                                );
                              },
                            ),

                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vote_title!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // tombol MORE di paling kanan
                            InkWell(
                              onTap: widget.onSeeMoreVote,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        seeMore!,
                                        softWrap: true,
                                        maxLines: 2,
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.red,
                                    ),
                                  ],
                                )
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: votes.map((item) {
                              final title = item['title']?.toString() ?? 'Tanpa Judul';
                              final dateStr = item['date_event']?.toString() ?? '-';
                              final img = item['img']?.toString() ?? '';
                              
                              String formattedDate = '-';

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
                                    if (day % 10 == 1 && day != 11) {
                                      suffix = 'st';
                                    } else if (day % 10 == 2 && day != 12) {
                                      suffix = 'nd';
                                    } else if (day % 10 == 3 && day != 13) {
                                      suffix = 'rd';
                                    }
                                    formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                                  }
                                } catch (e) {
                                  formattedDate = '-';
                                }
                              }

                              final formatter = NumberFormat.decimalPattern("en_US");
                              final hargaFormatted = formatter.format(item['price'] ?? 0);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () async {
                                    if (isChoosed == 0) {
                                      currencyCode = item['currency'];
                                      lastCurrency = item['currency'];
                                      await StorageService.setCurrency(currencyCode!);
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailVotePage(
                                              id_event: item['id_event'].toString(),
                                              currencyCode: currencyCode,
                                            ),
                                      ),
                                    ).then((_) {
                                      if (item['price'] != 0) {
                                        _handleBackFromDetail();
                                      }
                                    });
                                  },
                                  child: SizedBox(
                                    width: 200,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // gambar
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: AspectRatio(
                                              aspectRatio: 4 / 5,
                                              child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Image.asset(
                                                        'assets/images/img_placeholder.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                            ),
                                          ),

                                          // isi teks
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 38,
                                                  child: Text(
                                                    title,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ),
                                                //penyelenggara
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['nama_penyelenggara'],
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //tgl
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //harga
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? bahasa['harga_detail'] //'Gratis'
                                                  : currencyCode == null 
                                                    ? "${item['currency']} $hargaFormatted"
                                                    : "$currencyCode $hargaFormatted",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ) 
                ),

                //leaderboard
                const SizedBox(height: 20),
                Container(
                  color: Colors.red,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Image.network(
                              "$baseUrl/image/home/juara1.png",
                              width: 30,   // atur sesuai kebutuhan
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/img_broken.jpg',
                                  fit: BoxFit.contain,
                                  width: 30,
                                  height: 30,
                                );
                              },
                            ),

                            // SvgPicture.network(
                            //   '$baseUrl/image/home/vote.svg',
                            //   width: 30,
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),

                            const SizedBox(width: 12),
                            //text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    leaderboard_title!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: juara.map((item) {
                              final nama_finalis = item['nama_finalis']?.toString() ?? 'Tanpa Nama';
                              final judul_vote = item['judul_vote']?.toString() ?? '-';
                              final img = item['img']?.toString() ?? '';

                              final dateStr = item['tanggal_buka_payment'];
                              String formattedDate = '-';

                              if (dateStr != null) {
                                try {
                                  // parsing string ke DateTime
                                  final date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
                                  if (langCode == 'id') {
                                    // Bahasa Indonesia
                                    final formatter = DateFormat("$formatDateId HH:mm", "id_ID");
                                    formattedDate = formatter.format(date);
                                  } else {
                                    // Bahasa Inggris
                                    final formatter = DateFormat("$formatDateEn HH:mm", "en_US");
                                    formattedDate = formatter.format(date);

                                    // tambahkan suffix (1st, 2nd, 3rd, 4th...)
                                    final day = date.day;
                                    String suffix = 'th';
                                    if (day % 10 == 1 && day != 11) {
                                      suffix = 'st';
                                    } else if (day % 10 == 2 && day != 12) {
                                      suffix = 'nd';
                                    } else if (day % 10 == 3 && day != 13) {
                                      suffix = 'rd';
                                    }
                                    formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                                  }
                                } catch (e) {
                                  formattedDate = '-';
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () async {
                                    if (isChoosed == 0) {
                                      currencyCode = item['currency'];
                                      lastCurrency = item['currency'];
                                      await StorageService.setCurrency(currencyCode!);
                                    }

                                    if (item['flag_paket'] == '0') { //0
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LeaderboardSingleVote(
                                            id_finalis: item['id_finalis'].toString(), 
                                            count: 0, 
                                            indexWrap: null,
                                            close_payment: item['close_payment'],
                                            tanggal_buka_vote: formattedDate,
                                            flag_hide_nomor_urut: item['flag_hide_nomor_urut'],
                                            currencyCode: currencyCode,
                                          ),
                                        ),
                                      ).then((_) {
                                        _handleBackFromDetail();
                                      });
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LeaderboardSingleVotePaket(
                                            id_finalis: item['id_finalis'].toString(), 
                                            vote: 0, 
                                            index: 0,
                                            total_detail: 0,
                                            id_paket_bw: null,
                                            close_payment: item['close_payment'],
                                            tanggal_buka_vote: formattedDate,
                                            flag_hide_nomor_urut: item['flag_hide_nomor_urut'],
                                            currencyCode: currencyCode,
                                          ),
                                        ),
                                      ).then((_) {
                                        _handleBackFromDetail();
                                      });
                                    }
                                  },
                                  child: SizedBox(
                                    width: 200,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // gambar
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: AspectRatio(
                                              aspectRatio: 4 / 5,
                                              child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Image.asset(
                                                        'assets/images/img_placeholder.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                            ), 
                                          ),

                                          // isi teks
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 38,
                                                  child: Text(
                                                    nama_finalis,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  height: 38,
                                                  child: Text(
                                                    judul_vote,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Tombol Vote
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Container(
                                              width: double.infinity,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                "VOTE",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //event hits
                const SizedBox(height: 20),
                //loop data
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // SvgPicture.network(
                            //   '$baseUrl/image/home/star.svg',
                            //   width: 30,
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),

                            Image.network(
                              '$baseUrl/image/home/hits-event.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/img_broken.jpg',
                                  fit: BoxFit.contain,
                                  width: 30,
                                  height: 30,
                                );
                              },
                            ),

                            const SizedBox(width: 12),
                            //text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event_title!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // tombol MORE di paling kanan
                            InkWell(
                              onTap: widget.onSeeMoreEvent,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        seeMore!,
                                        softWrap: true,
                                        maxLines: 2,
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.red,
                                    ),
                                  ],
                                )
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: hitsevent.map((item) {
                              final title = item['title']?.toString() ?? 'Tanpa Judul';
                              final dateStr = item['date_event']?.toString() ?? '-';
                              final img = item['img']?.toString() ?? '';
                              num price = item['price'] ?? 0;
                              
                              String formattedDate = '-';

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
                                    if (day % 10 == 1 && day != 11) {
                                      suffix = 'st';
                                    } else if (day % 10 == 2 && day != 12) {
                                      suffix = 'nd';
                                    } else if (day % 10 == 3 && day != 13) {
                                      suffix = 'rd';
                                    }
                                    formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                                  }
                                } catch (e) {
                                  formattedDate = '-';
                                }
                              }

                              String hargaFormatted = '-';
                              final formatter = NumberFormat.decimalPattern("en_US");
                              hargaFormatted = formatter.format(item['price'] ?? 0);

                              final type_event = item['type_event'] ?? '-';
                              Color color_type = Colors.blue;
                              if (type_event == 'offline') {
                                color_type = Colors.red;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () async {
                                    if (isChoosed == 0) {
                                      currencyCode = item['currency'];
                                      lastCurrency = item['currency'];
                                      await StorageService.setCurrency(currencyCode!);
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                          DetailEventPage(
                                            id_event: item['id_event'].toString(), 
                                            price: price,
                                            currencyCode: currencyCode
                                          ),
                                      ),
                                    ).then((_) {
                                      if (item['price'] != 0) {
                                        _handleBackFromDetail();
                                      }
                                    });
                                  },
                                  child: SizedBox(
                                    width: 200,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // gambar
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                child: AspectRatio(
                                                  aspectRatio: 4 / 5,
                                                  child: img.isNotEmpty
                                                    ? Image.network(
                                                        img,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return Image.asset(
                                                            'assets/images/img_placeholder.jpg',
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Image.asset(
                                                            'assets/images/img_broken.jpg',
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                      )
                                                    : Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        fit: BoxFit.cover,
                                                      ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    type_event.toString().toUpperCase(),
                                                    style: TextStyle(
                                                      color: color_type,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // isi teks
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 38,
                                                  child: Text(
                                                    title,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                //penyelenggara
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['nama_penyelenggara'],
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //tgl
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //harga
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? '' //"Harga"
                                                  : bahasa['mulai_dari'] //"Mulai dari",
                                                ),
                                                const SizedBox(height: 4,),
                                                Text(
                                                  item['price'] == 0
                                                  ? bahasa['harga_detail'] //'Gratis'
                                                  : currencyCode == null 
                                                    ? "${item['currency']} $hargaFormatted"
                                                    : "$currencyCode $hargaFormatted",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ) 
                ),

                //vote terbaru
                const SizedBox(height: 20),
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // SvgPicture.network(
                            //   '$baseUrl/image/home/vote.svg',
                            //   width: 30,
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),

                            Image.network(
                              '$baseUrl/image/home/vote-terbaru.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/img_broken.jpg',
                                  fit: BoxFit.contain,
                                  width: 30,
                                  height: 30,
                                );
                              },
                            ),

                            const SizedBox(width: 12),
                            //text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    latest_vote!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),

                            // tombol MORE di paling kanan
                            InkWell(
                              onTap: widget.onSeeMoreVote,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        seeMore!,
                                        softWrap: true,
                                        maxLines: 2,
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.red,
                                    ),
                                  ],
                                )
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: latestvotes.map((item) {
                              final title = item['title']?.toString() ?? 'Tanpa Judul';
                              final dateStr = item['date_event']?.toString() ?? '-';
                              final img = item['img']?.toString() ?? '';
                              
                              String formattedDate = '-';

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
                                    if (day % 10 == 1 && day != 11) {
                                      suffix = 'st';
                                    } else if (day % 10 == 2 && day != 12) {
                                      suffix = 'nd';
                                    } else if (day % 10 == 3 && day != 13) {
                                      suffix = 'rd';
                                    }
                                    formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                                  }
                                } catch (e) {
                                  formattedDate = '-';
                                }
                              }

                              final formatter = NumberFormat.decimalPattern("en_US");
                              final hargaFormatted = formatter.format(item['price'] ?? 0);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () async {
                                    if (isChoosed == 0) {
                                      currencyCode = item['currency'];
                                      lastCurrency = item['currency'];
                                      await StorageService.setCurrency(currencyCode!);
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailVotePage(
                                              id_event: item['id_event'].toString(),
                                              currencyCode: currencyCode,
                                            ),
                                      ),
                                    ).then((_) {
                                      if (item['price'] != 0) {
                                        _handleBackFromDetail();
                                      }
                                    });
                                  },
                                  child: SizedBox(
                                    width: 200,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // gambar
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: AspectRatio(
                                              aspectRatio: 4 / 5,
                                              child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Image.asset(
                                                        'assets/images/img_placeholder.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                            ),
                                          ),

                                          // isi teks
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 38,
                                                  child: Text(
                                                    title,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ),
                                                //penyelenggara
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['nama_penyelenggara'],
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //tgl
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //harga
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? bahasa['harga_detail'] //'Gratis'
                                                  : currencyCode == null 
                                                    ? "${item['currency']} $hargaFormatted"
                                                    : "$currencyCode $hargaFormatted",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ) 
                ),

                //event recomended
                const SizedBox(height: 20),
                //loop data
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // SvgPicture.network(
                            //   '$baseUrl/image/home/vote.svg',
                            //   width: 30,
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),

                            Image.network(
                              '$baseUrl/image/home/event-rekom.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/img_broken.jpg',
                                  fit: BoxFit.contain,
                                  width: 30,
                                  height: 30,
                                );
                              },
                            ),

                            const SizedBox(width: 12),
                            //text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event_recomen!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // tombol MORE di paling kanan
                            InkWell(
                              onTap: widget.onSeeMoreEvent,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        seeMore!,
                                        softWrap: true,
                                        maxLines: 2,
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.red,
                                    ),
                                  ],
                                )
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: recomenevent.map((item) {
                              final title = item['title']?.toString() ?? 'Tanpa Judul';
                              final dateStr = item['date_event']?.toString() ?? '-';
                              final img = item['img']?.toString() ?? '';
                              final price = item['price'] ?? 0;
                              
                              String formattedDate = '-';

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
                                    if (day % 10 == 1 && day != 11) {
                                      suffix = 'st';
                                    } else if (day % 10 == 2 && day != 12) {
                                      suffix = 'nd';
                                    } else if (day % 10 == 3 && day != 13) {
                                      suffix = 'rd';
                                    }
                                    formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                                  }
                                } catch (e) {
                                  formattedDate = '-';
                                }
                              }

                              String hargaFormatted = '-';
                              final formatter = NumberFormat.decimalPattern("en_US");
                              hargaFormatted = formatter.format(item['price'] ?? 0);

                              final type_event = item['type_event'] ?? '-';
                              Color color_type = Colors.blue;
                              if (type_event == 'offline') {
                                color_type = Colors.red;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () async {
                                    if (isChoosed == 0) {
                                      currencyCode = item['currency'];
                                      lastCurrency = item['currency'];
                                      await StorageService.setCurrency(currencyCode!);
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                          DetailEventPage(
                                            id_event: item['id_event'].toString(), 
                                            price: price,
                                            currencyCode: currencyCode
                                          ),
                                      ),
                                    ).then((_) {
                                      if (item['price'] != 0) {
                                        _handleBackFromDetail();
                                      }
                                    });
                                  },
                                  child: SizedBox(
                                    width: 200,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // gambar
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                child: AspectRatio(
                                                  aspectRatio: 4 / 5,
                                                  child: img.isNotEmpty
                                                    ? Image.network(
                                                        img,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return Image.asset(
                                                            'assets/images/img_placeholder.jpg',
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Image.asset(
                                                            'assets/images/img_broken.jpg',
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                      )
                                                    : Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        fit: BoxFit.cover,
                                                      ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    type_event.toString().toUpperCase(),
                                                    style: TextStyle(
                                                      color: color_type,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // isi teks
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 38,
                                                  child: Text(
                                                    title,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                //penyelenggara
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['nama_penyelenggara'],
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //tgl
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                //harga
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? '' //"Harga"
                                                  : bahasa['mulai_dari'] //"Mulai dari",
                                                ),
                                                const SizedBox(height: 4,),
                                                Text(
                                                  item['price'] == 0
                                                  ? bahasa['harga_detail'] //'Gratis'
                                                  : currencyCode == null 
                                                    ? "${item['currency']} $hargaFormatted"
                                                    : "$currencyCode $hargaFormatted",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ) 
                ),

                //cari informasi
                const SizedBox(height: 20),
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // SvgPicture.network(
                            //   '$baseUrl/image/home/blog.svg',
                            //   width: 30,
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),

                            Image.network(
                              '$baseUrl/image/home/update.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/img_broken.jpg',
                                  fit: BoxFit.contain,
                                  width: 30,
                                  height: 30,
                                );
                              },
                            ),

                            const SizedBox(width: 12),
                            //text
                            Expanded( 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    news_title!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        //news
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: listArtikel.map((item) {
                              final article_title = item['article_title']?.toString() ?? 'Tanpa Judul';
                              final img = item['img']?.toString() ?? '';
                              final dateStr = item['created_at']?.toString() ?? '-';
                              String formattedDate = '-';

                              if (dateStr.isNotEmpty) {
                                try {
                                  DateTime? date;
                                  
                                  if (!RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
                                    
                                    final bulanIndo = {
                                      'Januari': 'January',
                                      'Februari': 'February',
                                      'Maret': 'March',
                                      'April': 'April',
                                      'Mei': 'May',
                                      'Juni': 'June',
                                      'Juli': 'July',
                                      'Agustus': 'August',
                                      'September': 'September',
                                      'Oktober': 'October',
                                      'November': 'November',
                                      'Desember': 'December',
                                    };
                                    
                                    String englishFormat = dateStr;
                                    bulanIndo.forEach((indo, eng) {
                                      englishFormat = englishFormat.replaceAll(indo, eng);
                                    });
                                    
                                    date = DateFormat(formatDateId, "en_US").parse(englishFormat);
                                  } else {
                                    date = DateTime.parse(dateStr);
                                  }
                                  
                                  if (langCode == 'id') {
                                    formattedDate = DateFormat(formatDateId, "id_ID").format(date);
                                  } else {
                                    final formatter = DateFormat(formatDateEn, "en_US");
                                    formattedDate = formatter.format(date);

                                    // suffix: st, nd, rd, th
                                    final day = date.day;
                                    String suffix = 'th';
                                    if (day % 10 == 1 && day != 11) { suffix = 'st'; }
                                    else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
                                    else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }

                                    formattedDate = formattedDate.replaceFirst('$day', '$day$suffix');
                                  }

                                } catch (e) {
                                  formattedDate = '-';
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WidgetWebView(header: bahasa['artikel'], url: item['link']),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 200,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // gambar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: AspectRatio(
                                              aspectRatio: 4 / 5,
                                              child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Image.asset(
                                                        'assets/images/img_placeholder.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img_broken.jpg',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'assets/images/img_broken.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                            ),
                                          ),

                                          // isi teks
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  article_title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ) 
                ),

                //jadi partner
                // const SizedBox(height: 20),
                // Container(
                //   color: Colors.red,
                //   child: Padding(
                //     padding: kGlobalPadding,
                //     child: Column(
                //       children: [
                //         Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: <Widget>[
                //             Image.asset(
                //               "assets/images/img_onboarding3.png",
                //               width: 150,   // atur sesuai kebutuhan
                //               height: 150,
                //               fit: BoxFit.contain,
                //             ),

                //             const SizedBox(width: 12),
                //             //text
                //             Expanded( // <= ini solusinya
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     partner!,
                //                     style: TextStyle(
                //                       fontSize: 16,
                //                       color: Colors.white,
                //                       fontWeight: FontWeight.bold,
                //                     ),
                //                     softWrap: true,          // biar teks bisa kebungkus
                //                     overflow: TextOverflow.visible, 
                //                   ),
                //                   SizedBox(height: 4),
                //                   //button
                //                   // button
                //                   ElevatedButton(
                //                     style: ElevatedButton.styleFrom(
                //                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                //                       backgroundColor: Colors.white,
                //                       shape: RoundedRectangleBorder(
                //                         borderRadius: BorderRadius.circular(8),
                //                       ),
                //                     ),
                //                     onPressed: () {
                //                       // aksi kalau button diklik
                //                     },
                //                     child: Text(
                //                       "Buat Eventmu",
                //                       style: TextStyle(
                //                         color: Colors.red,
                //                         fontWeight: FontWeight.bold,
                //                       ),
                //                     ),
                //                   ),

                //                   ElevatedButton(
                //                     style: ElevatedButton.styleFrom(
                //                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                //                       backgroundColor: Colors.white,
                //                       shape: RoundedRectangleBorder(
                //                         borderRadius: BorderRadius.circular(8),
                //                       ),
                //                     ),
                //                     onPressed: () {
                //                       // aksi kalau button diklik
                //                     },
                //                     child: Text(
                //                       "Buat Votemu",
                //                       style: TextStyle(
                //                         color: Colors.red,
                //                         fontWeight: FontWeight.bold,
                //                       ),
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
              ],
            ),
          ),
        ),
      ),
    );   
  }

  Future<void> _handleBackFromDetail() async {
    if (isChoosed == 0) {
      currencyCode = lastCurrency;
      isLoadingContent = true;
      await _loadContent();
      setState(() {});
    }
  }
}