// ignore_for_file: non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/checking_html.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/video_section.dart';
import 'package:kreen_app_flutter/modal/paket_vote_modal.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_paket.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/helper/download_qr.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DetailFinalisPaketPage extends StatefulWidget {
  final String id_finalis;
  final int vote;
  final int index;
  final total_detail;
  final String? id_paket_bw;
  final Duration? remaining;
  final String? close_payment;
  final String? tanggal_buka_payment;
  final String flag_hide_no_urut;
  const DetailFinalisPaketPage({super.key, required this.id_finalis, required this.vote, required this.index, required this.total_detail, required this.id_paket_bw, this.remaining, this.close_payment, this.tanggal_buka_payment, required this.flag_hide_no_urut});

  @override
  State<DetailFinalisPaketPage> createState() => _DetailFinalisPaketPageState();
}

class _DetailFinalisPaketPageState extends State<DetailFinalisPaketPage> {
  num? harga;
  num? hargaAsli;
  bool isTutup = false;
  bool canDownload = true;

  String buttonText = '';

  bool _isLoading = true;
  int counts = 0;
  num? harga_akhir;
  num harga_akhir_asli = 0;
  late String? id_paket = widget.id_paket_bw;
  int detailIndex = 0;
  Map<String, dynamic> detailFinalis = {};
  TextEditingController? controllers;
  Map<String, dynamic> detailvote = {};
  Map<String, dynamic> bahasa = {};

  String? langCode;
  String? notLogin, notLoginDesc, loginText;
  String? totalHargaText, hargaText, hargaDetail, bayarText;
  String? endVote, voteOpen, voteOpenAgain;
  String? buttonPilihPaketText;
  String? detailfinalisText;
  String? noDataText;
  String? ageText, activityText, biographyText, scanQrText, downloadQrText, tataCaraText, videoProfilText, noValidVideo, socialMediaText;

  int countData = 0;
  num totalHargaPaket = 0;
  
  bool showErrorBar = false;
  String errorMessage = ''; 

  final PageController _pageController = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);

  Timer? _timer;
  bool isPaymentClosed = false;

  Future<void> checkPaymentStatus() async {
    if (widget.close_payment != '1') {
      isPaymentClosed = false;
      return;
    }

    try {
      final reopenTime = DateTime.parse(widget.tanggal_buka_payment!);
      final now = DateTime.now().toUtc();

      final closed = now.isBefore(reopenTime);

      if (closed != isPaymentClosed) {
        setState(() {
          isPaymentClosed = closed;
        });
      }
    } catch (e) {
      isPaymentClosed = false;
    }
  }

  late YoutubePlayerController _ytTopController, _ytBottomController;
  bool _isFullscreen = false;
  bool _videoReady = false;
  bool _isTopVideo = true;

  void onFullscreenChanged(bool value) {
    setState(() {
      _isFullscreen = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _getBahasa();
    await _getCurrency();
    await _loadFinalis();
    await checkPaymentStatus();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => checkPaymentStatus(),
    );

    final videoId =
        YoutubePlayer.convertUrlToId(detailFinalis['video_profile'] ?? "");

    if (videoId != null && mounted) {
      setState(() {
        _ytTopController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            forceHD: false,
          ),
        );

        _ytBottomController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            forceHD: false,
          ),
        );
        _videoReady = true;
      });
    }
  }

  List<Map<String, dynamic>> paketTerbaik = [];
  List<Map<String, dynamic>> paketLainnya = [];

  Future<void> _loadFinalis() async {
    
    final resultFinalis = await ApiService.get("/finalis/${widget.id_finalis}", xLanguage: langCode,);
    if (resultFinalis == null || resultFinalis['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultFinalis?['message'];
      });
      return;
    }

    final tempFinalis = resultFinalis['data'] ?? {};

    final resultDetailVote = await ApiService.get("/vote/${tempFinalis['id_vote']}", xLanguage: langCode, xCurrency: currencyCode);
    if (resultDetailVote == null || resultDetailVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultDetailVote?['message'];
      });
      return;
    }

    final tempDetailVote = resultDetailVote['data'] ?? {};

    final tempPaket = tempDetailVote['vote_paket'];

    await _precacheAllImages(context, tempFinalis);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        detailFinalis = tempFinalis;

        counts = widget.vote;
        detailIndex = widget.index;

        controllers = TextEditingController(
          text: widget.vote.toString(),
        );

        detailvote = tempDetailVote;
        harga = tempDetailVote['harga'];
        hargaAsli = tempDetailVote['harga_asli'];

        if (tempPaket is List) {
          paketTerbaik = tempPaket
              .where((p) {
                if (p is Map<String, dynamic>) {
                  final diskon = int.tryParse(p['diskon_persen']?.toString() ?? '0') ?? 0;
                  return diskon > 0;
                }
                return false;
              })
              .cast<Map<String, dynamic>>()
              .toList();

          paketLainnya = tempPaket
              .where((p) {
                if (p is Map<String, dynamic>) {
                  final diskon = int.tryParse(p['diskon_persen']?.toString() ?? '0') ?? 0;
                  return diskon == 0;
                }
                return false;
              })
              .cast<Map<String, dynamic>>()
              .toList();
        }
        
        DateTime deadlineUtc = DateTime.parse(detailvote['real_tanggal_tutup_vote']);
        Duration remaining = Duration.zero;
        final nowUtc = DateTime.now().toUtc();
        final difference = deadlineUtc.difference(nowUtc);

        remaining = difference.isNegative ? Duration.zero : difference;
        
        final bukaVoteUtc = DateTime.parse(detailvote['real_tanggal_buka_vote']);
        bool isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

        String formattedBukaVote = DateFormat("$formatDateId HH:mm").format(bukaVoteUtc);
        
        if (isBeforeOpen) {
          buttonText = '$voteOpen $formattedBukaVote';
        } else if (detailvote['close_payment'] == '1') {
          buttonText = '$voteOpenAgain ${widget.tanggal_buka_payment}';
        } else {
          buttonText = buttonPilihPaketText!;
        }

        if (remaining.inSeconds == 0 || isBeforeOpen) {
          isTutup = true;
        }

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

    final tempbahasa = await LangService.getJsonData(langCode!, 'bahasa');

    setState(() {
      bahasa = tempbahasa;
      totalHargaText = bahasa['total_harga'];
      hargaText = bahasa['harga'];
      hargaDetail = bahasa['harga_detail'];
      bayarText = bahasa['bayar'];

      endVote = bahasa['end_vote'];
      voteOpen = bahasa['vote_open'];
      voteOpenAgain = bahasa['vote_open_again'];
      
      notLogin = bahasa['notLogin'];
      notLoginDesc = bahasa['notLoginDesc'];
      loginText = bahasa['login'];

      buttonPilihPaketText = bahasa['pick_paket'];
      detailfinalisText = bahasa['detail_finalis'];

      noDataText = bahasa['no_data'];
      ageText = bahasa['usia'];
      activityText = bahasa['aktivitas'];
      biographyText = bahasa['biografi'];
      scanQrText = bahasa['scan_vote'];
      downloadQrText = bahasa['unduh_qr'];
      tataCaraText = bahasa['tatacara_vote'];
      videoProfilText = bahasa['profile_video'];
      noValidVideo = bahasa['video_no_valid'];
      socialMediaText = bahasa['sosial_media'];
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
    Map<String, dynamic> finalis
  ) async {
    List<String> allImageUrls = [];

    // Ambil semua file_upload dari ranking (juara / banner)
    final finalisData = finalis['data'];
    if (finalisData is List) {
      for (var item in finalisData) {
        final url = item['poster_finalis']?.toString();
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

  final formatter = NumberFormat.decimalPattern("en_US");
  num get totalHarga {
    if (widget.total_detail != null && widget.total_detail != 0) {
      return widget.total_detail;
    }

    final hargaItem = harga_akhir;
    if (hargaItem == null) return 0;

    return hargaItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
            ? buildSkeletonHome()
            : buildKontenDetail(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadFinalis();
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
            padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

              SizedBox(height: 20),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  Widget buildKontenDetail() {

    Map<String, Color> colorMap = {
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Purple': Colors.purple,
      'Orange': Colors.orange,
      'Pink': Colors.pink,
      'Grey': Colors.grey,
      'Turqoise': Colors.teal,
    };

    String themeName = 'Red';
    if (detailvote['theme_name'] != null) {
      themeName = detailvote['theme_name'];
    }

    Color color = colorMap[themeName] ?? Colors.red;
    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade50;
    } else {
      bgColor = color.withOpacity(0.1);
    }

    final bool hasVideo =
      detailFinalis['video_profile'] != null &&
      detailFinalis['video_profile'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: _isFullscreen ? null : AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(detailfinalisText!), 
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          InkWell(
            onTap: () {
              Share.share(
                "$baseUrl/voting/${detailvote['vote_slug']}/${detailFinalis['id_finalis']}",
                subject: detailvote['judul_vote'],
              );
            },
            child: SvgPicture.network(
              '$baseUrl/image/icon-vote/$themeName/share-red.svg',
              height: 30,
              width: 30,
            ),
          ),
          SizedBox(width: 10,),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: hasVideo
                          ? Stack(
                              children: [
                                PageView(
                                  controller: _pageController,
                                  physics: const PageScrollPhysics(), // user gesture only
                                  onPageChanged: (index) {
                                    _pageIndex.value = index;
                                  },
                                  children: [
                                    // POSTER
                                    Image.network(
                                      detailFinalis['poster_finalis'] ?? "$baseUrl/noimage_finalis.png",
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) {
                                        return Image.network(
                                          "$baseUrl/noimage_finalis.png",
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),

                                    // VIDEO
                                    Container(
                                      color: Colors.white,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          color: Colors.white,
                                          child: buildVideo(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // // BUTTON PREV
                                // Positioned(
                                //   left: 8,
                                //   top: 0,
                                //   bottom: 0,
                                //   child: IconButton(
                                //     icon: const Icon(Icons.chevron_left, size: 36, color: Colors.grey),
                                //     onPressed: () {
                                //       _pageController.previousPage(
                                //         duration: const Duration(milliseconds: 300),
                                //         curve: Curves.easeOut,
                                //       );
                                //     },
                                //   ),
                                // ),

                                // // BUTTON NEXT
                                // Positioned(
                                //   right: 8,
                                //   top: 0,
                                //   bottom: 0,
                                //   child: IconButton(
                                //     icon: const Icon(Icons.chevron_right, size: 36, color: Colors.grey),
                                //     onPressed: () {
                                //       _pageController.nextPage(
                                //         duration: const Duration(milliseconds: 300),
                                //         curve: Curves.easeOut,
                                //       );
                                //     },
                                //   ),
                                // ),
                              ],
                            )
                          : Image.network(
                              detailFinalis['poster_finalis'] ?? "$baseUrl/noimage_finalis.png",
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                      ),

                      SizedBox(height: 8, child: Container(color: Colors.white,),),
                      ValueListenableBuilder<int>(
                        valueListenable: _pageIndex,
                        builder: (context, index, _) {
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                hasVideo ? 2 : 1,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: index == i ? 14 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index == i ? color.withOpacity(0.5) : color.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            )
                          );
                        },
                      ),
                  
                      SizedBox(height: 15,),
                      Container(
                        padding: kGlobalPadding,
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              detailFinalis['nama_finalis'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                  
                            if (detailFinalis['nama_tambahan'] != null && detailFinalis['nama_tambahan'].toString().trim().isNotEmpty) ...[
                              SizedBox(height: 10,),
                              Text(detailFinalis['nama_tambahan'],
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                  
                            if (widget.flag_hide_no_urut == "0") ...[
                              SizedBox(height: 10,),
                              Text(
                                detailFinalis['nomor_urut'].toString(),
                              ),
                            ],
                            
                  
                            SizedBox(height: 30,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        SvgPicture.network(
                                          "$baseUrl/image/icon-vote/$themeName/dollar-coin.svg",
                                          width: 25,
                                          height: 25,
                                          fit: BoxFit.contain,
                                        ),
                  
                                        SizedBox(width: 4),
                                        //text
                                        Text(hargaText!),
                                      ],
                                    ),
                  
                                    const SizedBox(height: 10,),
                                    Text(
                                      harga == 0
                                      ? hargaDetail!
                                      : currencyCode == null
                                        ? "${detailvote['currency']} ${formatter.format(harga)}"
                                        : "$currencyCode ${formatter.format(harga)}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        SvgPicture.network(
                                          "$baseUrl/image/icon-vote/$themeName/chart.svg",
                                          width: 25,
                                          height: 25,
                                          fit: BoxFit.contain,
                                        ),
                  
                                        SizedBox(width: 4),
                                        //text
                                        Text("Vote"),
                                      ],
                                    ),
                  
                                    const SizedBox(height: 10,),
                                    Text(
                                      formatter.format(detailFinalis['total_voters'] ?? 0),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ],
                            ),
                  
                            SizedBox(height: 30,),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isTutup || isPaymentClosed
                                  ? null
                                  : () async {
                                      final selectedQty = await PaketVoteModal.show(
                                        context,
                                        detailIndex,
                                        paketTerbaik,
                                        paketLainnya,
                                        color,
                                        bgColor,
                                        id_paket,
                                        currencyCode ?? detailvote['currency']
                                      );
                      
                                      if (selectedQty != null) {
                                        setState(() {
                                          counts = selectedQty['counts'];
                                          harga_akhir = selectedQty['harga_akhir'];
                                          if (currencyCode != null) {
                                            harga_akhir_asli = selectedQty['harga_akhir_asli'];
                                          } else {
                                            harga_akhir_asli = selectedQty['harga_akhir'];
                                          }
                                          id_paket = selectedQty['id_paket'];
                                          totalHargaPaket = harga_akhir as num;
                                          countData = selectedQty['count_data'];
                                        });
                                      }
                                    },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                                  decoration: BoxDecoration(
                                    color: isTutup || isPaymentClosed  ? Colors.grey : color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          buttonText,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      if (!isPaymentClosed) ...[
                                        // SizedBox(width: 10),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (detailFinalis['usia'] != 0 ||
                          (detailFinalis['profesi'] != null && detailFinalis['profesi'] != '') ||
                          (!isHtmlEmpty(detailFinalis['deskripsi']))) ... [
                  
                        SizedBox(height: 12,),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Padding(
                            padding: kGlobalPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                if (detailFinalis['usia'] != 0) ... [
                                  SizedBox(height: 12,),
                                  Text(
                                    ageText!,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                    
                                  (detailFinalis['usia'] == 0)
                                    ? Text(
                                        noDataText!,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : Text(detailFinalis['usia'].toString(),
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                ],
                    
                                if (detailFinalis['profesi'] != null && detailFinalis['profesi'] != '') ... [
                                  SizedBox(height: 12,),
                                  Text(
                                    activityText!,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    detailFinalis['profesi']
                                  ),
                                ],
                    
                                if (!isHtmlEmpty(detailFinalis['deskripsi'])) ... [
                                  SizedBox(height: 12,),
                                  Text(
                                    biographyText!,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Html(
                                    data: detailFinalis['deskripsi'],
                                    style: {
                                      '*': Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                      ),
                                      'p': Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                      )
                                    },
                                  ),
                                ],
                    
                                SizedBox(height: 12,),
                              ],
                            ),
                          ),
                        )
                      ],
                  
                      if (detailFinalis['id_qrcode'] != null) ... [
                        SizedBox(height: 12,),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Padding(
                            padding: kGlobalPadding,
                            child: Column(
                              children: [
                  
                                SizedBox(height: 12,),
                                Image.network(
                                  'https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${detailFinalis['id_qrcode']}',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/img_broken.jpg',
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                  
                                SizedBox(height: 12,),
                                Text(
                                  scanQrText!,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                  
                                SizedBox(height: 12,),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: canDownload 
                                      ? () async {
                                          await downloadQrImage(
                                            context, 
                                            detailFinalis['id_qrcode'],
                                            bahasa['download_scan_gagal'],
                                            bahasa['download_scan_berhasil'],
                                            bahasa['kesalahan_simpan_scan'],
                                          );
                                        }
                                      : null,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: canDownload ? color : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            downloadQrText!,
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          SizedBox(width: 10,),
                                          Icon(
                                            Icons.download, color: Colors.white, size: 15,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                  
                                SizedBox(height: 12,),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      await TutorModal.show(context, detailvote['tutorial_vote'], bahasa['tutorial_vote_text']);
                                    },
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          tataCaraText!,
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                         SizedBox(width: 10,),
                                        Icon(
                                          Icons.info, color: Colors.blue, size: 15,
                                        )
                                      ],
                                    )
                                  )
                                ),
                                SizedBox(height: 12,),
                              ],
                            ),
                          )
                        ),
                      ],
                  
                      if (detailFinalis['video_profile'] != null &&
                            detailFinalis['video_profile'].toString().trim().isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          color: Colors.white,
                          width: double.infinity,
                          padding: kGlobalPadding,
                          child: Column(
                            children: [
                              Text(
                                videoProfilText!,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),

                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  child: 
                                  // VideoSection(
                                  //   // link: detailFinalis['video_profile'],
                                  //   // headerText: videoProfilText!, 
                                  //   // noValidText: noValidText!,
                                  //   // onFullscreenChanged: onFullscreenChanged,
                                  //   controller: _ytController,
                                  // ),
                                  buildVideo()
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  
                      if (detailFinalis['facebook'] != null && detailFinalis['facebook'].toString().trim().isNotEmpty
                          || detailFinalis['twitter'] != null && detailFinalis['twitter'].toString().trim().isNotEmpty
                          || detailFinalis['linkedin'] != null && detailFinalis['linkedin'].toString().trim().isNotEmpty
                          || detailFinalis['instagram'] != null && detailFinalis['instagram'].toString().trim().isNotEmpty) ...[

                            SizedBox(height: 12),
                            // Media Social Section
                            Container(
                              width: double.infinity,
                              padding: kGlobalPadding,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300,),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                  socialMediaText!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (detailFinalis['facebook'] != null && detailFinalis['facebook'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.facebook,
                                          color: color,
                                          link: detailFinalis['facebook'],
                                          platform: "facebook",
                                        ),

                                      if (detailFinalis['twitter'] != null && detailFinalis['twitter'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.xTwitter,
                                          color: color,
                                          link: detailFinalis['twitter'],
                                          platform: "twitter",
                                        ),

                                      if (detailFinalis['linkedin'] != null && detailFinalis['linkedin'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.linkedin,
                                          color: color,
                                          link: detailFinalis['linkedin'],
                                          platform: "linkedin",
                                        ),

                                      if (detailFinalis['instagram'] != null && detailFinalis['instagram'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.instagram,
                                          color: color,
                                          link: detailFinalis['instagram'],
                                          platform: "instagram",
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      ],
                  
                      SizedBox(height: 12),
                  
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: _isFullscreen ? null : SafeArea(
        child: Container(
          color: Colors.white,
          padding:  EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // kiri
              isTutup || widget.close_payment == '1'
              ? SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // penting biar nggak overflow
                  children: [
                    Text(totalHargaText!),
                    Text(
                      harga == 0
                      ? hargaDetail!
                      : currencyCode == null
                        ? "${detailvote['currency']} ${formatter.format(totalHargaPaket)}"
                        : "$currencyCode ${formatter.format(totalHargaPaket)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      "${bahasa['paket']} $counts ${bahasa['text_vote']}\n$countData ${bahasa['finalis']}(s)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),

              // kanan
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey;
                      }
                      return color;
                    },
                  ),
                  padding: MaterialStateProperty.all(
                     EdgeInsets.symmetric(vertical: 8, horizontal: 22),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                onPressed: (harga != 0 && totalHarga == 0) || counts == 0 
                ? null 
                : () async {
                  final getUser = await StorageService.getUser();

                  String? idUser = getUser['id'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatePaymentPaket(
                        id_vote: detailFinalis['id_vote'],
                        id_finalis: detailFinalis['id_finalis'],
                        nama_finalis: detailFinalis['nama_finalis'],
                        counts: counts,
                        totalHarga: totalHarga,
                        totalHargaAsli: harga_akhir_asli,
                        id_paket: id_paket!,
                        fromDetail: true,
                        idUser: idUser,
                        flag_login: detailvote['flag_login'],
                        rateCurrency: detailvote['rate_currency_vote'],
                        rateCurrencyUser: detailvote['rate_currency_user'],
                      ),
                    ),
                  );

                  
                },
                child: Text(
                  isTutup
                  ? endVote!
                  : bayarText!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageIndex.dispose();
    _timer?.cancel();
    _ytTopController.dispose();
    _ytBottomController.dispose();
    super.dispose();
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String? link,
    required String platform,
  }) {
    final bool isEmpty = link == null || link.trim().isEmpty;

    return GestureDetector(
      onTap: isEmpty
          ? null
          : () async {
              final Uri url = _buildSocialUri(platform, link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                // fallback ke browser
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
      child: AnimatedContainer(
        duration:  Duration(milliseconds: 200),
        padding:  EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: isEmpty ? Colors.grey[400] : color,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Uri _buildSocialUri(String platform, String username) {
    switch (platform) {
      case "facebook":
        return Uri.parse("https://facebook.com/$username");
      case "twitter":
        return Uri.parse("https://twitter.com/$username");
      case "linkedin":
        return Uri.parse("https://linkedin.com/in/$username");
      case "instagram":
        return Uri.parse("https://instagram.com/$username");
      default:
        return Uri.parse(username);
    }
  }

  Widget buildVideo() {
    if (!_videoReady || _ytTopController == null || _ytBottomController == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_isTopVideo) {
      return VideoSection(controller: _ytTopController);
    } else {
      return VideoSection(controller: _ytBottomController);
    }
  }
}