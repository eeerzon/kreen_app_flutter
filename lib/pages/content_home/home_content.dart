// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/global_widget.dart';
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
  
  bool isLoadingDataAtas = true;
  bool isLoadingDataBawah = true;

  bool showErrorBar = false;
  String errorMessage = '';
  String? currencyCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      
      await _getBahasa();
      await _getCurrency();
      await _loadDataAtas();
    });
  }
  
  Future<void> _checkToken() async {
    final storedToken = await StorageService.getToken();
    if (!mounted) return;
    setState(() => token = storedToken);
  }
  
  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() => langCode = code);

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
    final code = await StorageService.getCurrency();
    setState(() => currencyCode = code);
  }
  
  List<dynamic> activeBanners = [];
  List<double?> aspectRatios = [];
  List<dynamic> votes = [];
  
  List<dynamic> juara = [];
  List<dynamic> hitsevent = [];
  List<dynamic> latestvotes = [];
  List<dynamic> recomenevent = [];
  List<dynamic> listArtikel = [];
  
  Future<void> _loadDataAtas() async {
    await _checkToken();

    final get_user = await StorageService.getUser();
    first_name = get_user['first_name'];
    
    final results = await Future.wait([
      ApiService.get("/setting-banner/active", xLanguage: langCode, token: token),
      ApiService.get("/vote/popular", xCurrency: currencyCode, xLanguage: langCode, token: token),
    ]);

    final resultBanner = results[0];
    final resultVote = results[1];

    if (!mounted) return;

    if (resultBanner == null || resultBanner['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultBanner?['message'] ?? 'Error loading banner';
        isLoadingDataAtas = false;
      });
      return;
    }
    
    if (resultVote == null || resultVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultVote?['message'] ?? 'Error loading votes';
        isLoadingDataAtas = false;
      });
      return;
    }
    
    final now = DateTime.now();
    final allBanners = resultBanner['data'] as List<dynamic>? ?? [];
    final filtered = allBanners.where((banner) {
      final takedownDateStr = banner['takedown_date']?.toString();
      if (takedownDateStr == null || takedownDateStr.isEmpty) return true;
      final takedownDate = DateTime.tryParse(takedownDateStr);
      if (takedownDate == null) return true;
      return now.isBefore(takedownDate);
    }).toList();

    final tempVotes = resultVote['data'] ?? [];
    final tempBanners = filtered;
    
    _precacheAllImages(context, tempBanners, tempVotes).ignore();

    final tempChoosed = await StorageService.getIsChoosed();

    if (!mounted) return;

    setState(() {
      photo_user = get_user['photo'];
      activeBanners = tempBanners;
      votes = tempVotes;
      isChoosed = tempChoosed ?? 0;
      isLoadingDataAtas = false;
      showErrorBar = false;
    });
    
    preloadImageSizes();
    _loadDataBawah();
  }
  
  Future<void> _loadDataBawah() async {
    final results = await Future.wait([
      ApiService.get("/vote/juara", xLanguage: langCode, token: token),
      ApiService.get("/event/hits", xCurrency: currencyCode, xLanguage: langCode, token: token),
      ApiService.get("/vote/latest", xCurrency: currencyCode, xLanguage: langCode, token: token),
      ApiService.get("/event/recommended", xCurrency: currencyCode, xLanguage: langCode, token: token),
      ApiService.get("/articles?limit=8", xLanguage: langCode),
    ]);

    if (!mounted) return;
    
    for (final r in results) {
      if (r == null || r['rc'] != 200) {
        setState(() {
          showErrorBar = true;
          errorMessage = r?['message'] ?? 'Error loading content';
        });
      }
    }

    final resultJuara = results[0];
    final resultHit = results[1];
    final resultLatest = results[2];
    final resultRecom = results[3];
    final resultArtikel = results[4];
    
    List<dynamic> tempJuara = [];
    if (resultJuara != null && resultJuara['rc'] == 200) {
      final rawData = resultJuara['data'];
      if (rawData is Map<String, dynamic>) {
        tempJuara = rawData.values.toList();
      } else if (rawData is List) {
        tempJuara = rawData;
      }
    }

    setState(() {
      juara = tempJuara;
      hitsevent = (resultHit    != null && resultHit['rc']    == 200) ? resultHit['data']    ?? [] : hitsevent;
      latestvotes = (resultLatest != null && resultLatest['rc'] == 200) ? resultLatest['data']  ?? [] : latestvotes;
      recomenevent = (resultRecom  != null && resultRecom['rc']  == 200) ? resultRecom['data']   ?? [] : recomenevent;
      listArtikel = (resultArtikel != null && resultArtikel['rc'] == 200) ? resultArtikel['data'] ?? [] : listArtikel;
      isLoadingDataBawah = false;
    });
  }
  
  Future<void> _loadContent() async {
    setState(() {
      isLoadingDataAtas = true;
      isLoadingDataBawah = true;
    });
    await _loadDataAtas();
  }
  
  Future<void> _precacheAllImages(
    BuildContext context,
    List<dynamic> banners,
    List<dynamic> votes,
  ) async {
    final urls = <String>{};
    for (final b in banners) {
      final url = b['file_upload']?.toString();
      if (url != null && url.isNotEmpty && url.startsWith('http')) urls.add(url);
    }
    for (final v in votes) {
      final url = v['img']?.toString();
      if (url != null && url.isNotEmpty && url.startsWith('http')) urls.add(url);
    }
    for (final url in urls) {
      if (!mounted) return;
      await precacheImage(NetworkImage(url), context);
    }
  }

  void preloadImageSizes() {
    aspectRatios = List<double?>.filled(activeBanners.length, null);
    for (int i = 0; i < activeBanners.length; i++) {
      final url   = activeBanners[i]['file_upload'];
      final image = Image.network(url).image;
      image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          if (mounted) setState(() => aspectRatios[i] = w / h);
        }),
      );
    }
  }
  
  Widget _shimmerBox({double width = double.infinity, double height = 20, double radius = 6}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          isLoadingDataAtas
              ? buildSkeletonHome()
              : buildKontenHome(),
          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () => _loadContent(),
          ),
        ],
      ),
    );
  }
  
  Widget buildSkeletonHome() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[200],
        padding: kGlobalPadding,
        child: Column(
          children: [
            
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
            _shimmerBox(height: 180, radius: 8),
            const SizedBox(height: 30),
            
            Row(
              children: [
                _shimmerBox(width: 30, height: 30),
                const SizedBox(width: 10),
                _shimmerBox(width: 180, height: 20),
              ],
            ),

            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 200,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(height: 14, width: 160, color: Colors.white),
                                const SizedBox(height: 6),
                                Container(height: 12, width: 100, color: Colors.white),
                                const SizedBox(height: 6),
                                Container(height: 12, width: 80,  color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkeletonSection() {
    return Padding(
      padding: kGlobalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 30, height: 30),
              const SizedBox(width: 10),
              _shimmerBox(width: 140, height: 18),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.only(right: 12),
                width: 200,
                child: _shimmerBox(height: 250, radius: 8),
              )),
            ),
          ),
        ],
      ),
    );
  }
  
  bool get isSvg => photo_user?.toLowerCase().endsWith(".svg") ?? false;
  bool get isHttp => photo_user?.toLowerCase().contains("http") ?? false;
  
  String _formatDate(String? dateStr, {bool includeTime = false}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      if (langCode == 'id') {
        final pattern = includeTime ? "$formatDateId HH:mm" : "$formatDay, $formatDateId";
        return DateFormat(pattern, "id_ID").format(date);
      } else {
        final pattern = includeTime ? "$formatDateEn HH:mm" : "$formatDay, $formatDateEn";
        String formatted = DateFormat(pattern, "en_US").format(date);
        final day = date.day;
        String suffix = 'th';
        if (day % 10 == 1 && day != 11) {
          suffix = 'st';
        } else if (day % 10 == 2 && day != 12) {
          suffix = 'nd';
        } else if (day % 10 == 3 && day != 13) {
          suffix = 'rd';
        }
        return formatted.replaceFirst('$day', '$day$suffix');
      }
    } catch (_) {
      return '-';
    }
  }

  String _formatPrice(dynamic price) {
    return NumberFormat.decimalPattern("en_US").format(price ?? 0);
  }
  
  Widget buildKontenHome() {
    return RefreshIndicator(
      onRefresh: _loadContent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          color: Colors.grey[200],
          child: Column(
            children: [
              _buildHeader(),
              
              AutoPlayCarousel(
                images: activeBanners.map((e) => e['file_upload'] as String).toList(),
                data: activeBanners,
                aspectRatios: aspectRatios,
                bahasa: bahasa,
              ),
              Container(height: 20, color: Colors.white),
              
              const SizedBox(height: 20),
              _buildVoteSection(
                title: vote_title ?? '',
                imgUrl: '$baseUrl/image/home/vote-populer.png',
                items: votes,
                onSeeMore: widget.onSeeMoreVote,
                type: _CardType.vote,
              ),
              
              const SizedBox(height: 20),
              isLoadingDataBawah
                  ? Column(children: [
                      Container(color: Colors.red, child: _buildSkeletonSection()),
                      const SizedBox(height: 20),
                      Container(color: Colors.white, child: _buildSkeletonSection()),
                      const SizedBox(height: 20),
                      Container(color: Colors.white, child: _buildSkeletonSection()),
                      const SizedBox(height: 20),
                      Container(color: Colors.white, child: _buildSkeletonSection()),
                      const SizedBox(height: 20),
                      Container(color: Colors.white, child: _buildSkeletonSection()),
                    ])
                  : Column(children: [
                    
                      _buildLeaderboardSection(),
                      
                      const SizedBox(height: 20),
                      _buildEventSection(
                        title: event_title ?? '',
                        imgUrl: '$baseUrl/image/home/hits-event.png',
                        items: hitsevent,
                        onSeeMore: widget.onSeeMoreEvent,
                      ),
                      
                      const SizedBox(height: 20),
                      _buildVoteSection(
                        title: latest_vote ?? '',
                        imgUrl: '$baseUrl/image/home/vote-terbaru.png',
                        items: latestvotes,
                        onSeeMore: widget.onSeeMoreVote,
                        type: _CardType.vote,
                      ),
                      
                      const SizedBox(height: 20),
                      _buildEventSection(
                        title: event_recomen ?? '',
                        imgUrl: '$baseUrl/image/home/event-rekom.png',
                        items: recomenevent,
                        onSeeMore: widget.onSeeMoreEvent,
                      ),
                      
                      if (listArtikel.isNotEmpty) ... [
                        const SizedBox(height: 20),
                        _buildArtikelSection(),
                      ]
                    ]),
            ],
          ),
        ),
      ),
    );
  }
  

  Widget _buildHeader() {
    return Container(
      color: Colors.red,
      child: Padding(
        padding: kGlobalPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  "assets/images/avata_logo.png",
                  width: 40, height: 40, fit: BoxFit.contain,
                ),
                token == null
                    ? Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 180),
                          child: IntrinsicWidth(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: const Color(0xFFFFDFE0),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                                if (result == true) {
                                  await _getBahasa();
                                  await _loadContent();
                                }
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
                    : InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Profile()),
                          );
                          if (result == true) await _loadContent();
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
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        "$baseUrl/noimage_finalis.png",
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.fill,
                                      );
                                    },
                                  )
                                : isHttp
                                  ? Image.network(
                                      photo_user!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.fill,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.network(
                                          "$baseUrl/noimage_finalis.png",
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.fill,
                                        );
                                      },
                                    )
                                  : Image.network(
                                      '$baseUrl/user/$photo_user',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.fill,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.network(
                                          "$baseUrl/noimage_finalis.png",
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.fill,
                                        );
                                      },
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                first_name != null ? 'Hi, $first_name' : selamatDatang!,
                style: const TextStyle(
                  fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader({
    required String title,
    required String imgUrl,
    Color textColor = Colors.black,
    VoidCallback? onSeeMore,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.network(
          imgUrl, width: 30, height: 30, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/images/img_broken.jpg', width: 30, height: 30, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        if (onSeeMore != null)
          InkWell(
            onTap: onSeeMore,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      seeMore ?? 'More',
                      softWrap: true, maxLines: 2,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor == Colors.black ? Colors.red : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: textColor == Colors.black ? Colors.red : Colors.white,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVoteSection({
    required String title,
    required String imgUrl,
    required List<dynamic> items,
    required VoidCallback onSeeMore,
    required _CardType type,
  }) {
    final isOpenedLink = List<bool>.filled(items.length, false);

    return Container(
      color: Colors.white,
      child: Padding(
        padding: kGlobalPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title: title, imgUrl: imgUrl, onSeeMore: onSeeMore),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final title = item['title']?.toString() ?? 'Tanpa Judul';
                  final dateStr = item['date_event']?.toString();
                  final img = item['img']?.toString() ?? '';
                  final hargaFmt = _formatPrice(item['price']);
                  final formattedDate = _formatDate(dateStr);
                  final url_partner = item['url_partner'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () async {
                        if (isChoosed == 0) {
                          currencyCode = item['currency'];
                          lastCurrency = item['currency'];
                          await StorageService.setCurrency(currencyCode!);
                        }

                        if (url_partner != null && url_partner.isNotEmpty) {
                          if (isOpenedLink[index]) return;

                          isOpenedLink[index] = true;

                          try {
                            await openDeepLink(
                              url_partner,
                            );
                          } finally {
                            if (mounted) setState(() => isOpenedLink[index] = false);
                          }
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailVotePage(
                                id_event: item['id_event'].toString(),
                                // id_event: '684f8222cbe92', //pake untuk testing modal boost vote
                                
                                currencyCode: currencyCode,
                              ),
                            ),
                          ).then((_) {
                            if (item['price'] != 0 || isChoosed == 1) _handleBackFromDetail();
                          });
                        }
                      },
                      child: _buildVoteCard(
                        img: img,
                        title: title,
                        organizer: item['nama_penyelenggara'] ?? '',
                        date: formattedDate,
                        price: item['price'],
                        hargaFmt: hargaFmt,
                        currency: item['currency'],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteCard({
    required String img,
    required String title,
    required String organizer,
    required String date,
    required dynamic price,
    required String hargaFmt,
    String? currency,
  }) {
    return SizedBox(
      width: 200,
      child: Card(
        color: Colors.white, elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardImage(img),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle(title),
                  const SizedBox(height: 4),
                  Text(
                    organizer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, color: Colors.grey
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    price == 0
                        ? bahasa['harga_detail'] ?? 'Gratis'
                        : currencyCode == null ? "$currency $hargaFmt" : "$currencyCode $hargaFmt",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventSection({
    required String title,
    required String imgUrl,
    required List<dynamic> items,
    required VoidCallback onSeeMore,
  }) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: kGlobalPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title: title, imgUrl: imgUrl, onSeeMore: onSeeMore),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.map((item) {
                  final title = item['title']?.toString() ?? 'Tanpa Judul';
                  final dateStr = item['date_event']?.toString();
                  final img = item['img']?.toString() ?? '';
                  final price = item['price'] ?? 0;
                  final hargaFmt = _formatPrice(price);
                  final formattedDate = _formatDate(dateStr);
                  final typeEvent = item['type_event'] ?? '-';
                  final colorType = typeEvent == 'offline' ? Colors.red : Colors.blue;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
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
                            builder: (_) => DetailEventPage(
                              id_event: item['id_event'].toString(),
                              price: price,
                              currencyCode: currencyCode,
                            ),
                          ),
                        ).then((_) {
                          if (price != 0 || isChoosed == 1) _handleBackFromDetail();
                        });
                      },
                      child: _buildEventCard(
                        img: img, title: title,
                        organizer: item['nama_penyelenggara'] ?? '',
                        date: formattedDate,
                        price: price, hargaFmt: hargaFmt,
                        currency: item['currency'],
                        typeEvent: typeEvent, colorType: colorType,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required String img, required String title,
    required String organizer, required String date,
    required dynamic price, required String hargaFmt,
    String? currency, required String typeEvent, required Color colorType,
  }) {
    return SizedBox(
      width: 200,
      child: Card(
        color: Colors.white, elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildCardImage(img),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeEvent.toString().toUpperCase(),
                      style: TextStyle(color: colorType, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle(title),
                  const SizedBox(height: 4),
                  Text(
                    organizer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, color: Colors.grey
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(price == 0 ? '' : bahasa['mulai_dari'] ?? 'Mulai dari'),
                  const SizedBox(height: 4),
                  Text(
                    price == 0
                        ? bahasa['harga_detail'] ?? 'Gratis'
                        : currencyCode == null ? "$currency $hargaFmt" : "$currencyCode $hargaFmt",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLeaderboardSection() {
    return Container(
      color: Colors.red,
      child: Padding(
        padding: kGlobalPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: leaderboard_title ?? '',
              imgUrl: "$baseUrl/image/home/juara1.png",
              textColor: Colors.white,
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: juara.map((item) {
                  final namaFinalis = item['nama_finalis']?.toString() ?? 'Tanpa Nama';
                  final judulVote = item['judul_vote']?.toString() ?? '-';
                  final img = item['img']?.toString() ?? '';
                  final tanggal = _formatDate(item['tanggal_buka_payment']?.toString(), includeTime: true);

                  int viewApi = 0;
                  if (item['leaderboard_tipe'] == "percent")     viewApi = 3;
                  if (item['leaderboard_tipe'] == "bar-percent") viewApi = 5;

                  final idVote = item['id_vote']?.toString() ?? '';
                  final idFinalis = item['id_finalis']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () async {
                        if (isChoosed == 0) {
                          currencyCode = item['currency'];
                          lastCurrency = item['currency'];
                          await StorageService.setCurrency(currencyCode!);
                        }
                        
                        final storedToken = await StorageService.getToken(); 
                        final resultVote = await ApiService.get("/vote/$idVote", xCurrency: currencyCode, xLanguage: langCode, token: storedToken);
                        var detailVote = resultVote?['data'] ?? {};

                        if (detailVote['partner_url_web'] != null && detailVote['partner_url_web'].isNotEmpty) {
                          final partnerUrl = normalizePartnerUrl(detailVote['partner_url_web'].toString());
                          await openDeepLink('$partnerUrl/$idFinalis');
                          return;
                        } else {
                          if (item['flag_paket'] == '0') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LeaderboardSingleVote(
                                  id_finalis: item['id_finalis'].toString(),
                                  count: 0, indexWrap: null,
                                  close_payment: item['close_payment'],
                                  tanggal_buka_vote: tanggal,
                                  flag_hide_nomor_urut: item['flag_hide_nomor_urut'],
                                  currencyCode: currencyCode,
                                  view_api: viewApi,
                                ),
                              ),
                            ).then((_) => _handleBackFromDetail());
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LeaderboardSingleVotePaket(
                                  id_finalis: item['id_finalis'].toString(),
                                  vote: 0, index: 0, total_detail: 0, id_paket_bw: null,
                                  close_payment: item['close_payment'],
                                  tanggal_buka_vote: tanggal,
                                  flag_hide_nomor_urut: item['flag_hide_nomor_urut'],
                                  currencyCode: currencyCode,
                                  view_api: viewApi,
                                ),
                              ),
                            ).then((_) => _handleBackFromDetail());
                          }
                        }
                      },
                      child: SizedBox(
                        width: 200,
                        child: Card(
                          color: Colors.white, elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardImage(img),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCardTitle(namaFinalis),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 38,
                                      child: Text(
                                        judulVote,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
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
      ),
    );
  }
  
  Widget _buildArtikelSection() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: kGlobalPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: news_title ?? '',
              imgUrl: '$baseUrl/image/home/update.png',
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: listArtikel.map((item) {
                  final articleTitle = item['article_title']?.toString() ?? 'Tanpa Judul';
                  final img = item['img']?.toString() ?? '';
                  final dateStr = item['created_at']?.toString() ?? '';
                  String formattedDate = '-';
                  DateTime? date;
                  
                  if (dateStr.isNotEmpty) {
                    try {
                      if (!RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
                        const bulanIndo = {
                          'Januari': 'January', 'Februari': 'February', 'Maret': 'March',
                          'April': 'April', 'Mei': 'May', 'Juni': 'June', 'Juli': 'July',
                          'Agustus': 'August', 'September': 'September', 'Oktober': 'October',
                          'November': 'November', 'Desember': 'December',
                        };
                        String en = dateStr;
                        bulanIndo.forEach((id, eng) => en = en.replaceAll(id, eng));
                        date = DateFormat('dd MMMM yyyy', "en_US").parse(en);
                      } else {
                        date = DateTime.parse(dateStr);
                      }
                      formattedDate = langCode == 'id'
                          ? DateFormat('dd MMMM yyyy', "id_ID").format(date)
                          : _formatDate(date.toIso8601String());
                    } catch (_) {}
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WidgetWebView(
                            header: bahasa['artikel'] ?? 'Artikel',
                            url: item['link'],
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: 200,
                        child: Card(
                          color: Colors.white, elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildCardImage(img),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      articleTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
      ),
    );
  }


  Widget _buildCardImage(String img) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: img.isNotEmpty
            ? Image.network(
                img,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : Image.asset('assets/images/img_placeholder.jpg', fit: BoxFit.cover),
                errorBuilder: (_, __, ___) =>
                    Image.asset('assets/images/img_broken.jpg', fit: BoxFit.cover),
              )
            : Image.asset('assets/images/img_broken.jpg', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildCardTitle(String title) {
    return SizedBox(
      height: 38,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
      ),
    );
  }
  
  Future<void> _handleBackFromDetail() async {
    if (isChoosed == 0) {
      currencyCode = lastCurrency;
      setState(() => isLoadingDataAtas = true);
      await _loadContent();
    }
  }
}

enum _CardType { vote }