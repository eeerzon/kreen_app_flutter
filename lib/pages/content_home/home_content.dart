// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote.dart';
import 'package:kreen_app_flutter/pages/vote/leaderboard_single_vote_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:kreen_app_flutter/widgets/article_webview.dart';
import 'package:kreen_app_flutter/widgets/auto_play_carousel.dart';
import 'package:shimmer/shimmer.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? login;
  String? token;

  String? selamatDatang, first_name, photo_user;

  String? event_title, event_desc, event_recomen;
  String? vote_title, latest_vote;
  String? comingsoon_title, comingsoon_desc;
  String? partner, partner_btn;
  String? news_title, news_desc;

  bool isLoadingContent = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _loadContent();
    });
  }

  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    if (mounted) {
      setState(() {
        token = storedToken;
      });
    }
  }

  Future<void> _getBahasa() async {
    langCode = await StorageService.getLanguage();

    final homeContent = await LangService.getJsonData(langCode!, "home_content");
    final tempLogin = await LangService.getText(langCode!, 'login');

    setState(() {
      selamatDatang = homeContent['top_nav'];
      login = tempLogin;
      event_title = homeContent['event_title'];
      event_recomen = homeContent['event_recomen'];
      event_desc = homeContent['event_desc'];

      vote_title = homeContent['vote_title'];
      latest_vote = homeContent['latest_vote'];

      comingsoon_title = homeContent['comingsoon_title'];
      comingsoon_desc = homeContent['comingsoon_desc'];

      partner = homeContent['partner'];
      partner_btn = homeContent['partner_btn'];

      news_title = homeContent['news_title'];
      news_desc = homeContent['news_desc'];
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

    _checkToken();

    var get_user = await StorageService.getUser();
    first_name = get_user['first_name'];

    final resultbanner = await ApiService.get("/setting-banner/active");
    final resultVote = await ApiService.get("/vote/popular");
    final resultJuara = await ApiService.get("/vote/juara");
    final resulthitEvent = await ApiService.get("/event/hits");
    final resultlatestVote = await ApiService.get("/vote/latest");
    final resultrecomenEvent = await ApiService.get("/event/recommended");
    final resultArtikel = await ApiService.get("/articles?limit=8");

    if (!mounted) return;

    final now = DateTime.now();
    final allBanners = resultbanner?['data'] as List<dynamic>? ?? [];

    final filtered = allBanners.where((banner) {
      final takedownDateStr = banner['takedown_date']?.toString();
      if (takedownDateStr == null || takedownDateStr.isEmpty) return true;

      final takedownDate = DateTime.tryParse(takedownDateStr);
      if (takedownDate == null) return true;

      return now.isBefore(takedownDate);
    }).toList();

    final tempActiveBanners = filtered;
    final tempVotes = resultVote?['data'] ?? [];
    
    final rawData = resultJuara?['data'];

    List<dynamic> tempJuara = [];

    if (rawData is Map<String, dynamic>) {
      tempJuara = rawData.values.toList();
    } else if (rawData is List) {
      tempJuara = rawData;
    }

    final tempHitsevent = resulthitEvent?['data'] ?? [];
    final tempLatestVotes = resultlatestVote?['data'] ?? [];
    final tempRecomenEvent = resultrecomenEvent?['data'] ?? [];
    final tempListArtikel = resultArtikel?['data'] ?? [];
    
    await _precacheAllImages(context, tempActiveBanners, tempVotes);

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
      body: isLoadingContent
          ? buildSkeletonHome()
          : buildKontenHome()
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
                                          _checkToken();
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
                    
                              CircleAvatar(
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
                  aspectRatios: aspectRatios,
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Image.asset(
                            //   "assets/images/img_event.png",
                            //   width: 30,   // atur sesuai kebutuhan
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),
                            SvgPicture.network(
                              '$baseUrl/image/home/star.svg',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(width: 12),
                            //text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vote_title!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
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
                                    final formatter = DateFormat("EEE, dd MMMM yyyy", "id_ID");
                                    formattedDate = formatter.format(date);
                                  } else {
                                    // Bahasa Inggris
                                    final formatter = DateFormat("EEE, MMMM d yyyy", "en_US");
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

                              final formatter = NumberFormat.decimalPattern("id_ID");
                              final hargaFormatted = formatter.format(item['price'] ?? 0);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailVotePage(id_event: item['id_event'].toString()),
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
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: img.isNotEmpty
                                              ? FadeInImage.assetNetwork(
                                                  placeholder: 'assets/images/placeholder.png',
                                                  image: img,
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  fadeInDuration: const Duration(milliseconds: 300),
                                                  imageErrorBuilder: (context, error, stack) => Container(
                                                    height: 180,
                                                    color: Colors.grey[300],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  height: 180,
                                                  color: Colors.grey[200],
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image_not_supported),
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? 'Gratis'
                                                  : "${item['currency']} $hargaFormatted",
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
                            // Image.asset(
                            //   "assets/images/img_event.png",
                            //   width: 30,   // atur sesuai kebutuhan
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),
                            SvgPicture.network(
                              '$baseUrl/image/home/vote.svg',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(width: 12),
                            //text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dukung Terus Juara 1 Kamu",
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
                                    final formatter = DateFormat("dd MMM yyyy HH:mm", "id_ID");
                                    formattedDate = formatter.format(date);
                                  } else {
                                    // Bahasa Inggris
                                    final formatter = DateFormat("MMM d yyyy HH:mm", "en_US");
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
                                  onTap: () {

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
                                          ),
                                        ),
                                      );
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
                                          ),
                                        ),
                                      );
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
                                            child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    height: 180,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stack) => Container(
                                                      height: 180,
                                                      color: Colors.grey[300],
                                                      alignment: Alignment.center,
                                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                                    ),
                                                  )
                                                : Container(
                                                    height: 180,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.image_not_supported),
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Image.asset(
                            //   "assets/images/img_event.png",
                            //   width: 30,   // atur sesuai kebutuhan
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),
                            SvgPicture.network(
                              '$baseUrl/image/home/star.svg',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
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
                                      color: Colors.red,
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
                            children: hitsevent.map((item) {
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
                                    final formatter = DateFormat("EEE, dd MMMM yyyy", "id_ID");
                                    formattedDate = formatter.format(date);
                                  } else {
                                    // Bahasa Inggris
                                    final formatter = DateFormat("EEE, MMMM d yyyy", "en_US");
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
                              final formatter = NumberFormat.decimalPattern("id_ID");
                              hargaFormatted = formatter.format(item['price'] ?? 0);

                              final type_event = item['type_event'] ?? '-';
                              Color color_type = Colors.blue;
                              if (type_event == 'offline') {
                                color_type = Colors.red;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailEventPage(id_event: item['id_event'].toString(), price: price,),
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
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                child: img.isNotEmpty
                                                  ? Image.network(
                                                      img,
                                                      height: 180,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stack) => Container(
                                                        height: 180,
                                                        color: Colors.grey[300],
                                                        alignment: Alignment.center,
                                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 180,
                                                      color: Colors.grey[200],
                                                      alignment: Alignment.center,
                                                      child: const Icon(Icons.image_not_supported),
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? "Harga"
                                                  : "Mulai dari",
                                                ),
                                                const SizedBox(height: 4,),
                                                Text(
                                                  item['price'] == 0
                                                  ? 'Gratis'
                                                  : "${item['currency']} $hargaFormatted",
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Image.asset(
                            //   "assets/images/img_calender.png",
                            //   width: 30,   // atur sesuai kebutuhan
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),
                            SvgPicture.network(
                              '$baseUrl/image/home/vote.svg',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
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
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    comingsoon_desc!,
                                    style: TextStyle(color: Colors.black),
                                    softWrap: true,          // biar teks bisa kebungkus
                                    overflow: TextOverflow.visible, 
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
                                    final formatter = DateFormat("EEE, dd MMMM yyyy", "id_ID");
                                    formattedDate = formatter.format(date);
                                  } else {
                                    // Bahasa Inggris
                                    final formatter = DateFormat("EEE, MMMM d yyyy", "en_US");
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

                              final formatter = NumberFormat.decimalPattern("id_ID");
                              final hargaFormatted = formatter.format(item['price'] ?? 0);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailVotePage(id_event: item['id_event'].toString()),
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
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    height: 180,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stack) => Container(
                                                      height: 180,
                                                      color: Colors.grey[300],
                                                      alignment: Alignment.center,
                                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                                    ),
                                                  )
                                                : Container(
                                                    height: 180,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.image_not_supported),
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? 'Gratis'
                                                  : "${item['currency']} $hargaFormatted",
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Image.asset(
                            //   "assets/images/img_event.png",
                            //   width: 30,   // atur sesuai kebutuhan
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),
                            SvgPicture.network(
                              '$baseUrl/image/home/vote.svg',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
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
                                      color: Colors.red,
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
                                    final formatter = DateFormat("EEE, dd MMMM yyyy", "id_ID");
                                    formattedDate = formatter.format(date);
                                  } else {
                                    // Bahasa Inggris
                                    final formatter = DateFormat("EEE, MMMM d yyyy", "en_US");
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
                              final formatter = NumberFormat.decimalPattern("id_ID");
                              hargaFormatted = formatter.format(item['price'] ?? 0);

                              final type_event = item['type_event'] ?? '-';
                              Color color_type = Colors.blue;
                              if (type_event == 'offline') {
                                color_type = Colors.red;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 12), // jarak antar card
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailEventPage(id_event: item['id_event'].toString(), price: price,),
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
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                child: img.isNotEmpty
                                                  ? Image.network(
                                                      img,
                                                      height: 180,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stack) => Container(
                                                        height: 180,
                                                        color: Colors.grey[300],
                                                        alignment: Alignment.center,
                                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 180,
                                                      color: Colors.grey[200],
                                                      alignment: Alignment.center,
                                                      child: const Icon(Icons.image_not_supported),
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['price'] == 0
                                                  ? "Harga"
                                                  : "Mulai dari",
                                                ),
                                                const SizedBox(height: 4,),
                                                Text(
                                                  item['price'] == 0
                                                  ? 'Gratis'
                                                  : "${item['currency']} $hargaFormatted",
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Image.asset(
                            //   "assets/images/img_search.png",
                            //   width: 30,   // atur sesuai kebutuhan
                            //   height: 30,
                            //   fit: BoxFit.contain,
                            // ),
                            SvgPicture.network(
                              '$baseUrl/image/home/blog.svg',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
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
                                      color: Colors.red,
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
                                    
                                    date = DateFormat("dd MMMM yyyy", "en_US").parse(englishFormat);
                                  } else {
                                    date = DateTime.parse(dateStr);
                                  }
                                  
                                  if (langCode == 'id') {
                                    formattedDate = DateFormat("dd MMMM yyyy", "id_ID").format(date);
                                  } else {
                                    final formatter = DateFormat("MMMM d yyyy", "en_US");
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
                                            ArticleWebView(url: item['link']),
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
                                            child: img.isNotEmpty
                                              ? Image.network(
                                                  img,
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stack) => Container(
                                                    height: 180,
                                                    color: Colors.grey[300],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  height: 180,
                                                  color: Colors.grey[200],
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.image_not_supported),
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

}