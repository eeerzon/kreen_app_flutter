// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

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
import 'package:kreen_app_flutter/helper/yt_section_player.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_manual.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/helper/download_qr.dart';
import 'package:kreen_app_flutter/pages/backup_temp.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DetailFinalisPage extends StatefulWidget {
  final String id_finalis;
  final int count;
  final int? indexWrap;
  final String? close_payment;
  final String? tanggal_buka_payment;
  final String flag_hide_no_urut;
  const DetailFinalisPage({super.key, required this.id_finalis, required this.count, this.indexWrap, this.close_payment, this.tanggal_buka_payment, required this.flag_hide_no_urut});

  @override
  State<DetailFinalisPage> createState() => _DetailFinalisPageState();
}

class _DetailFinalisPageState extends State<DetailFinalisPage> {
  num harga = 0;
  num hargaAsli = 0;
  bool isTutup = false;
  bool canDownload = true;

  String buttonText = '';

  bool _isLoading = true;
  int counts = 0;
  Map<String, dynamic> detailFinalis = {};
  TextEditingController? controllers;
  Map<String, dynamic> detailvote = {};
  Map<String, dynamic> bahasa = {};

  var idVote;
  List<String> ids_finalis = [];
  List<String> names_finalis = [];
  List<int> counts_finalis = [];

  final List<int> voteOptions = [10, 50, 100, 250, 500, 1000];
  int? selectedVotes;

  String? langCode;
  String? notLogin, notLoginDesc, loginText;
  String? totalHargaText, hargaText, hargaDetail, bayarText;
  String? endVote, voteOpen, voteOpenAgain;
  String? detailfinalisText;
  String? noDataText;
  String? ageText, activityText, biographyText, scanQrText, downloadQrText, tataCaraText, videoProfilText, noValidText, socialMediaText;

  int totalQty = 0;
  int countData = 1;
  
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

  Future<void> _loadFinalis() async {
    final idFinalis = widget.id_finalis;
    
    final resultFinalis = await ApiService.get("/finalis/$idFinalis", xLanguage: langCode);
    if (resultFinalis == null || resultFinalis['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultFinalis?['message'];
      });
      return;
    }

    final tempFinalis = resultFinalis['data'] ?? {};

    idVote = tempFinalis['id_vote']?.toString();
    Map<String, dynamic> tempDetailVote = {};

    if (idVote != null && idVote.isNotEmpty) {
      final resultDetailVote = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
      tempDetailVote = resultDetailVote?['data'] ?? {};
    }
    
    await _precacheAllImages(context, tempFinalis);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        detailFinalis = tempFinalis;

        controllers = TextEditingController(
          text: widget.count.toString(),
        );

        detailvote = tempDetailVote;
        harga = tempDetailVote['harga'] ?? 0;
        hargaAsli = tempDetailVote['harga_asli'] ?? 0;

        controllers!.text = widget.count.toString();
        counts = widget.count;

        if (widget.indexWrap != null && widget.indexWrap! >= 0 && widget.indexWrap! < voteOptions.length) {
          selectedVotes = voteOptions[widget.indexWrap!];
          counts = selectedVotes!;
          controllers!.text = counts.toString();
        } else {
          selectedVotes = null;
          counts = widget.count;
          controllers!.text = counts.toString();
        }


        ids_finalis.add(widget.id_finalis);
        names_finalis.add(detailFinalis['nama_finalis']);
        counts_finalis.add(counts);
        
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
      totalHargaText = tempbahasa['total_harga'];
      hargaText = tempbahasa['harga'];
      hargaDetail = tempbahasa['harga_detail'];
      bayarText = tempbahasa['bayar'];

      endVote = tempbahasa['end_vote'];
      voteOpen = tempbahasa['vote_open'];
      voteOpenAgain = tempbahasa['vote_open_again'];
      
      notLogin = tempbahasa['notLogin'];
      notLoginDesc = tempbahasa['notLoginDesc'];
      loginText = tempbahasa['login'];
      
      detailfinalisText = tempbahasa['detail_finalis'];

      noDataText = tempbahasa['no_data'];
      ageText = tempbahasa['usia'];
      activityText = tempbahasa['aktivitas'];
      biographyText = tempbahasa['biografi'];
      scanQrText = tempbahasa['scan_vote'];
      downloadQrText = tempbahasa['unduh_qr'];
      tataCaraText = tempbahasa['tatacara_vote'];
      videoProfilText = tempbahasa['profile_video'];
      noValidText = tempbahasa['video_no_valid'];
      socialMediaText = tempbahasa['sosial_media'];

      bahasa = tempbahasa;
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
  num totalHargaAsli = 0;
  num get totalHarga {
    num hargaItem = 0;
    if (currencyCode != null) {
      hargaItem = hargaAsli * counts;
      totalHargaAsli = hargaItem;
      hargaItem = hargaItem * (detailvote['rate_currency_user'] / detailvote['rate_currency_vote']);
      if (currencyCode == "IDR") {
        hargaItem = hargaItem.ceil();
      } else {
        hargaItem = (hargaItem * 100).ceil() / 100;
      }
    } else {
      hargaItem = harga * counts;
    }
    return hargaItem;
  }

  void _updateCountFromInput(String value, Map item, Map vote) {
    final int batas = int.tryParse(
      vote['batas_qty']?.toString() ?? '0'
    ) ?? 0;
    
    int input = int.tryParse(value) ?? 0;

    if (batas > 0 && input > batas) {
      input = batas;
    }

    if (controllers!.text != input.toString()) {
      controllers!.text = input.toString();
      controllers!.selection = TextSelection.fromPosition(
        TextPosition(offset: controllers!.text.length),
      );
    }

    setState(() {

      counts = input;
      // controllers!.text = parsed.toString();

      final idFinalis = item['id_finalis'];
      final namaFinalis = item['nama_finalis'];

      final existingIndex = ids_finalis.indexOf(idFinalis);

      if (input > 0) {
        if (existingIndex == -1) {
          ids_finalis.add(idFinalis);
          names_finalis.add(namaFinalis);
          counts_finalis.add(input);
        } else {
          counts_finalis[existingIndex] = input;
          names_finalis[existingIndex] = namaFinalis;
        }
      } else {
        if (existingIndex != -1) {
          ids_finalis.removeAt(existingIndex);
          names_finalis.removeAt(existingIndex);
          counts_finalis.removeAt(existingIndex);
        }
      }

      totalQty = counts_finalis.fold<int>(0, (sum, item) => sum + item);
    });
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

    String themeName = 'default';
    if (detailvote.containsKey('theme_name') && detailvote['theme_name'] != null) {
      themeName = detailvote['theme_name'].toString();
    }
    
    Color color = colorMap[themeName] ?? Colors.red;

    final filteredOptions = detailvote['batas_qty'] > 0
      ? voteOptions.where((v) => v <= detailvote['batas_qty']).toList()
      : voteOptions;

    final text = bahasa['batas']
      .replaceAll('{qty}', detailvote['batas_qty'].toString());

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

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
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
                                            child: 
                                            // VideoSection(
                                              // link: detailFinalis['video_profile'],
                                              // headerText: videoProfilText!, 
                                              // noValidText: noValidText!,
                                              // onFullscreenChanged: onFullscreenChanged,
                                              // controller: _ytController,
                                            // ),
                                            buildVideo()
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
                    
                        const SizedBox(height: 15,),
                        Container(
                          padding: kGlobalPadding,
                          color: Colors.white,
                          child: Column(
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

                              if (widget.flag_hide_no_urut == "0") ... [
                                const SizedBox(height: 10,),
                                Text(
                                  detailFinalis['nomor_urut'].toString(),
                                ),
                              ],
                    
                              const SizedBox(height: 30,),
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
                                        hargaAsli == 0
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
                    
                              if (isPaymentClosed) ... [
                                SizedBox(height: 30),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                                  decoration: BoxDecoration(
                                    color: isPaymentClosed ? Colors.grey : color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$voteOpenAgain ${widget.tanggal_buka_payment}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                              else ... [
                                const SizedBox(height: 30,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    //button minus
                                    InkWell(
                                      onTap: (isTutup || isPaymentClosed)
                                        ? null
                                        : () {
                                          if (counts > 0) {
                                            setState(() {
                                              counts--;
                                              controllers!.text = counts.toString();
                    
                                              final namaFinalis = detailFinalis['nama_finalis']; 
                                              final existingIndex = ids_finalis.indexOf(widget.id_finalis);
                    
                                              if (counts == 0) {
                                                selectedVotes = null;
                                                if (existingIndex != -1) {
                                                  ids_finalis.removeAt(existingIndex);
                                                  names_finalis.removeAt(existingIndex);
                                                  counts_finalis.removeAt(existingIndex);
                                                }
                                              } else {
                                                if (existingIndex != -1) {
                                                  counts_finalis[existingIndex] = counts;
                                                  names_finalis[existingIndex] = namaFinalis;
                                                }
                                              }

                                              totalQty = counts_finalis.fold<int>(0, (sum, item) => sum + item);
                                            });
                                          }
                                        },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isTutup || isPaymentClosed ? Colors.grey : color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(FontAwesomeIcons.minus, size: 15, color: Colors.white),
                                      ),
                                    ),
                    
                                    //text field
                                    const SizedBox(width: 15),
                                    Container(
                                      height: 40,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: controllers,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        enabled: !isTutup || !isPaymentClosed,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isCollapsed: true, // hilangkan padding bawaan
                                          contentPadding: EdgeInsets.all(8),
                                        ),
                                        onChanged: (value) => _updateCountFromInput(value, detailFinalis, detailvote),
                                        onTap: () {
                                          // langsung block semua teks ketika diklik
                                          controllers!.selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: controllers!.text.length,
                                          );
                                        },
                                      ),
                                    ),
                    
                                    //button plus
                                    const SizedBox(width: 15),
                                    InkWell(
                                      onTap: (isTutup || isPaymentClosed)
                                        ? null
                                        : () {
                                            setState(() {
                                              // Jika batas > 0 dan sudah mencapai batas -> stop
                                              if (detailvote['batas_qty'] > 0 && counts >= detailvote['batas_qty']) {
                                                return; // tidak menambah lagi
                                              }
                                              
                                              counts++;
                                              controllers!.text = counts.toString();
                    
                                              final namaFinalis = detailFinalis['nama_finalis']; 
                                              final existingIndex = ids_finalis.indexOf(widget.id_finalis);
                    
                                              if (counts > 0) {
                                                if (existingIndex == -1) {
                                                  ids_finalis.add(widget.id_finalis);
                                                  names_finalis.add(namaFinalis);
                                                  counts_finalis.add(counts);
                                                } else {
                                                  counts_finalis[existingIndex] = counts;
                                                  names_finalis[existingIndex] = namaFinalis;
                                                }
                                              }
                                              
                                              if (counts == 0 && existingIndex != -1) {
                                                ids_finalis.removeAt(existingIndex);
                                                names_finalis.removeAt(existingIndex);
                                                counts_finalis.removeAt(existingIndex);
                                              }

                                              totalQty = counts_finalis.fold<int>(0, (sum, item) => sum + item);
                                            });
                                          },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isTutup || isPaymentClosed ? Colors.grey : color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(FontAwesomeIcons.plus, size: 15, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (counts == detailvote['batas_qty'] && detailvote['batas_qty'] > 0) ...[
                                SizedBox(height: 8,),
                                Text(
                                  "* $text",
                                  style: const TextStyle(color: Colors.red),
                                )
                              ],
                              
                              if (counts >= 1) ...[
                                if (filteredOptions.isNotEmpty) ...[
                                  const SizedBox(height: 15,),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    alignment: WrapAlignment.center,
                                    children: filteredOptions.asMap().entries.map((entry) {
                                      final voteCount = entry.value;
                                      final isSelected = counts == voteCount;
                      
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedVotes = voteCount;
                                            counts = voteCount;
                                            controllers!.text = counts.toString();
                                            
                                            final namaFinalis = detailFinalis['nama_finalis'];
                                            final existingIndex = ids_finalis.indexOf(widget.id_finalis);
                      
                      
                                            if (counts > 0) {
                                              if (existingIndex == -1) {
                                                ids_finalis.add(widget.id_finalis);
                                                names_finalis.add(namaFinalis);
                                                counts_finalis.add(counts);
                                              } else {
                                                counts_finalis[existingIndex] = counts;
                                                names_finalis[existingIndex] = namaFinalis;
                                              }
                                            } else if (counts == 0 && existingIndex != -1) {
                                              ids_finalis.removeAt(existingIndex);
                                              names_finalis.removeAt(existingIndex);
                                              counts_finalis.removeAt(existingIndex);
                                            }
                                          });
                                        },
                      
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? color : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: color),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                NumberFormat.decimalPattern("en_US").format(voteCount),
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text("vote", 
                                                style: TextStyle(fontSize: 12,
                                                color: isSelected ? Colors.white : Colors.black,)
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ]
                            ],
                          ),
                        ),

                        if (detailFinalis['usia'] != 0 ||
                            (detailFinalis['profesi'] != null && detailFinalis['profesi'] != '') ||
                            (!isHtmlEmpty(detailFinalis['deskripsi']))) ... [
                          const SizedBox(height: 12,),
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            child: Padding(
                              padding: kGlobalPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                      
                                  if (detailFinalis['usia'] != null && detailFinalis['usia'] != 0) ...[
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
                      
                                  if (detailFinalis['profesi'].toString().isNotEmpty) ... [
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
                      
                                  const SizedBox(height: 12,),
                                ],
                              ),
                            ),
                          ),
                          
                          if (detailFinalis['id_qrcode'] != null) ... [
                            const SizedBox(height: 12,),
                            Container(
                              width: double.infinity,
                              color: Colors.white,
                              child: Padding(
                                padding: kGlobalPadding,
                                child: Column(
                                  children: [
                      
                                    const SizedBox(height: 12,),
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
                      
                                    const SizedBox(height: 12,),
                                    Text(
                                      scanQrText!,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                      
                                    const SizedBox(height: 12,),
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
                      
                                    const SizedBox(height: 12,),
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
                                            const SizedBox(width: 10,),
                                            Icon(
                                              Icons.info, color: Colors.blue, size: 15,
                                            )
                                          ],
                                        )
                                      )
                                    ),
                                    const SizedBox(height: 12,),
                                  ],
                                ),
                              )
                            ),
                      
                            if (detailFinalis['video_profile'] != null && detailFinalis['video_profile'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
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
                          ],
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
                    
                        const SizedBox(height: 12),
                    
                      ],
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _isFullscreen ? null : SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                      ? bahasa['harga_detail']
                      : currencyCode == null 
                        ? "${detailvote['currency']} ${formatter.format(totalHarga)}"
                        : "$currencyCode ${formatter.format(totalHarga)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      "Qty $counts ${bahasa['text_vote']}\n$countData ${bahasa['finalis']}(s)",
                      style: TextStyle(fontSize: 12,),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
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
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
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
                        builder: (_) => StatePaymentManual(
                          id_vote: idVote!,
                          ids_finalis: ids_finalis,
                          names_finalis: names_finalis,
                          counts_finalis: counts_finalis,
                          totalHarga: totalHarga,
                          totalHargaAsli: totalHargaAsli,
                          price: detailvote['harga_asli'],
                          fromDetail: false,
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
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