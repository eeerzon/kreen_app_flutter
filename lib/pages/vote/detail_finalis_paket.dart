// ignore_for_file: non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/date_helper.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/global_widget.dart';
import 'package:kreen_app_flutter/helper/video_section.dart';
import 'package:kreen_app_flutter/modal/email_verif_modal.dart';
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
  final bool persen;
  final void Function(String? idPaket, int counts, num hargaAkhir, num hargaAkhirAsli, int countData)? onPaketSelected;
  final num? harga_akhir_asli;
  final num? harga_akhir;

  const DetailFinalisPaketPage({
    super.key, 
    required this.id_finalis, 
    required this.vote, 
    required this.index, 
    required this.total_detail, 
    required this.id_paket_bw, 
    this.remaining, 
    this.close_payment, 
    this.tanggal_buka_payment, 
    required this.flag_hide_no_urut, 
    required this.persen,
    this.onPaketSelected,
    this.harga_akhir_asli,
    this.harga_akhir
  });

  @override
  State<DetailFinalisPaketPage> createState() => _DetailFinalisPaketPageState();
}

class _DetailFinalisPaketPageState extends State<DetailFinalisPaketPage> {
  num? harga;
  num? hargaAsli;
  bool isTutup = false;
  Duration remaining = Duration.zero;
  DateTime deadlineUtc = DateTime.now();
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
  Timer? _countdownTimer;
  bool isPaymentClosed = false;
  bool isBeforeOpen = false;
  final GlobalKey _shareKey = GlobalKey();
  String? currencyCode;

  bool isButtonClicked = false;

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

  YoutubePlayerController? _ytTopController, _ytBottomController;
  bool _isFullscreen = false;

  void onFullscreenChanged(bool value) {
    setState(() {
      _isFullscreen = value;
    });
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadToken();
      await _loadFinalis();
      _startCountdown();

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => checkPaymentStatus(),
      );

      final rawUrl = detailFinalis['video_profile'] ?? "";
      final cleanedUrl = cleanYoutubeUrl(rawUrl);

      final videoId = YoutubePlayer.convertUrlToId(cleanedUrl);

      if (videoId != null && mounted) {
        setState(() {
          if (videoId != "" && videoId.isNotEmpty) {
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
          }
        });
      }

      if (currencyCode != null) {
        harga_akhir_asli = widget.harga_akhir_asli ?? 0;
      } else {
        harga_akhir_asli = widget.harga_akhir ?? 0;
      }
    });
  }

  // ignore: unused_field
  String _storedToken = '';
  Future<void> _loadToken() async {
    final token = await StorageService.getToken() ?? '';
    if (mounted) setState(() => _storedToken = token);
  }
  
  Future<void> _onAfterLogin() async {
    await _loadToken();
  }

  List<Map<String, dynamic>> paketTerbaik = [];
  List<Map<String, dynamic>> paketLainnya = [];

  Future<void> _loadFinalis() async {

    final storedToken = await StorageService.getToken();
    
    final resultFinalis = await ApiService.get("/finalis/${widget.id_finalis}", xLanguage: langCode, xCurrency: currencyCode, token: storedToken);
    if (resultFinalis == null || resultFinalis['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultFinalis?['message'];
      });
      return;
    }

    final tempFinalis = resultFinalis['data'] ?? {};
    final resultDetailVote = await ApiService.get("/vote/${tempFinalis['id_vote']}", xLanguage: langCode, xCurrency: currencyCode, token: storedToken);
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
        
        final dateStr = detailvote['real_tanggal_buka_payment']?.toString() ?? '-';
        
        String formattedDate = '-';

        if (dateStr.isNotEmpty) {
          try {
            final localDate = DateHelper.parseWibToLocal(dateStr);
            if (langCode == 'id') {
              final formatter = DateFormat("$formatDateId HH:mm", "id_ID");
              formattedDate = formatter.format(localDate);
            } else {
              final formatter = DateFormat("$formatDateEn HH:mm", "en_US");
              formattedDate = formatter.format(localDate);
              
              final day = localDate.day;
              String suffix = 'th';
              if (day % 10 == 1 && day != 11) { suffix = 'st'; }
              else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
              else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
              formattedDate = formatter.format(localDate).replaceFirst('$day', '$day$suffix');
            }
          } catch (e) {
            formattedDate = '-';
          }
        }
        
        deadlineUtc = DateHelper.parseWibToUtc(detailvote['real_tanggal_tutup_vote']);
        final nowUtc = DateTime.now().toUtc();
        final difference = deadlineUtc.difference(nowUtc);

        remaining = difference.isNegative ? Duration.zero : difference;
        
        final bukaVoteUtc = DateHelper.parseWibToUtc(detailvote['real_tanggal_buka_vote']);
        final bukaVote = DateHelper.parseWibToLocal(detailvote['real_tanggal_buka_vote']);
        isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

        String formattedBukaVote = DateFormat("$formatDateId HH:mm").format(bukaVote);
        
        if (isBeforeOpen) {
          buttonText = '$voteOpen $formattedBukaVote';
        } else if (detailvote['close_payment'] == '1') {
          buttonText = '$voteOpenAgain $formattedDate';
        } else {
          buttonText = buttonPilihPaketText!;
        }

        if (remaining.inSeconds == 0 || isBeforeOpen) {
          isTutup = true;
        }

        if (widget.total_detail != null && widget.total_detail != 0) {
          harga_akhir = widget.total_detail;
          totalHargaPaket = widget.total_detail;
        }
        
        counts = widget.vote;

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
    
    final finalisData = finalis['data'];
    if (finalisData is List) {
      for (var item in finalisData) {
        final url = item['poster_finalis']?.toString();
        if (url != null && url.isNotEmpty) {
          allImageUrls.add(url);
        }
      }
    }
    
    allImageUrls = allImageUrls.toSet().toList();
    
    for (String url in allImageUrls) {
      await precacheImage(NetworkImage(url), context);
    }
  }

  final formatter = NumberFormat.decimalPattern("en_US");
  num get totalHarga {
    if (harga_akhir != null && harga_akhir != 0) {
      return harga_akhir!;
    }
    
    if (widget.total_detail != null && widget.total_detail != 0) {
      return widget.total_detail;
    }
    return 0;
  }

  void _startCountdown() {
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final nowUtc = DateTime.now().toUtc();
    final difference = deadlineUtc.difference(nowUtc);

    final bukaVoteUtc = DateHelper.parseWibToUtc(detailvote['real_tanggal_buka_vote']);
    final newIsBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

    String newButtonText = buttonText;
    if (difference.isNegative || difference.inSeconds == 0) {
      newButtonText = endVote ?? '';
    } else if (newIsBeforeOpen) {
      final bukaVote = DateHelper.parseWibToLocal(detailvote['real_tanggal_buka_vote']);
      final formattedBukaVote = DateFormat("$formatDateId HH:mm").format(bukaVote);
      newButtonText = '$voteOpen $formattedBukaVote';
    } else if (detailvote['close_payment'] == '1') {
      newButtonText = '$voteOpenAgain ${_getFormattedPaymentDate()}';
    } else {
      newButtonText = buttonPilihPaketText ?? '';
    }

    if (difference.isNegative) {
      _countdownTimer?.cancel();
    }

    setState(() {
      remaining = difference.isNegative ? Duration.zero : difference;
      isBeforeOpen = newIsBeforeOpen;

      isTutup = remaining.inSeconds == 0 || isBeforeOpen;

      buttonText = newButtonText;
    });
  }

  String _getFormattedPaymentDate() {
    final dateStr = detailvote['real_tanggal_buka_payment']?.toString() ?? '-';
    if (dateStr.isEmpty) return '-';
    try {
      final localDate = DateHelper.parseWibToLocal(dateStr);
      if (langCode == 'id') {
        return DateFormat("$formatDateId HH:mm", "id_ID").format(localDate);
      } else {
        final formatter = DateFormat("$formatDateEn HH:mm", "en_US");
        final day = localDate.day;
        String suffix = 'th';
        if (day % 10 == 1 && day != 11) { suffix = 'st'; }
        else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
        else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
        return formatter.format(localDate).replaceFirst('$day', '$day$suffix');
      }
    } catch (e) {
      return '-';
    }
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

    String themeName = 'Red';
    if (detailvote['theme_name'] != null) {
      themeName = detailvote['theme_name'];
    }

    if (themeName == "Default Kreen") {
      themeName = "default";
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

    final isFreeVotePaket = id_paket == 'free_vote';
    final belumPilihPaket = counts == 0;
    final paketBerbayarTapiHargaNol = !isFreeVotePaket && totalHarga == 0;

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
            key: _shareKey,
            onTap: () {
              final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
              final rect = box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : Rect.fromLTWH(0, 0, 100, 100);
              
              Share.share(
                "$baseUrl/voting/${detailvote['vote_slug']}/${detailFinalis['id_finalis']}",
                subject: detailvote['judul_vote'],
                sharePositionOrigin: rect,
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
                                  physics: const PageScrollPhysics(),
                                  onPageChanged: (index) {
                                    _pageIndex.value = index;
                                  },
                                  children: [
                                    
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
                                    
                                    Container(
                                      color: Colors.white,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          color: Colors.white,
                                          child: buildTopVideo(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
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

                      if (hasVideo) ...[
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
                      ],
                  
                      SizedBox(height: 15,),
                      Container(
                        padding: kGlobalPadding,
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const namaFinalisStyle = TextStyle(fontWeight: FontWeight.bold);

                                final textPainter = TextPainter(
                                  text: TextSpan(text: detailFinalis['nama_finalis'], style: namaFinalisStyle),
                                  textDirection: Directionality.of(context),
                                )..layout(maxWidth: constraints.maxWidth);

                                final isMultiline = textPainter.computeLineMetrics().length > 1;

                                return Text(
                                  detailFinalis['nama_finalis'],
                                  textAlign: isMultiline ? TextAlign.center : TextAlign.start,
                                  style: namaFinalisStyle,
                                );
                              },
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

                                if (detailvote['leaderboard_tipe'] != 'hidden') ...[
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
                                          Text(
                                            (widget.persen
                                              ? (detailFinalis['percent'] ?? 0) > 1
                                              : (detailFinalis['total_voters'] ?? 0) > 1)
                                                ? bahasa['text_votes']
                                                : bahasa['text_vote'],
                                          ),
                                        ],
                                      ),
                    
                                      const SizedBox(height: 10,),
                                      Text(
                                        widget.persen 
                                          ? "${detailFinalis['percent'] ?? 0}%"
                                          : formatter.format(detailFinalis['total_voters'] ?? 0),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                ],
                              ],
                            ),
                  
                            SizedBox(height: 30,),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: (isPaymentClosed || isBeforeOpen)
                                  ? null
                                  : () async {
                                    if (remaining.inSeconds == 0) {
                                        return;
                                      }
                                      
                                      final selectedQty = await PaketVoteModal.show(
                                        context,
                                        detailIndex,
                                        paketTerbaik,
                                        paketLainnya,
                                        color,
                                        bgColor,
                                        id_paket,
                                        currencyCode!,
                                        selectedIdPaket: id_paket,
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
                                    color: (remaining.inSeconds == 0 || isPaymentClosed || isBeforeOpen) 
                                      ? Colors.grey 
                                      : color,
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
                                      if (!isPaymentClosed && !isBeforeOpen && remaining.inSeconds != 0) ...[
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

                      if ((detailFinalis['usia'] != null && detailFinalis['usia'] != 0) ||
                          (detailFinalis['profesi'] != null && detailFinalis['profesi'] != '') ||
                          (!isHtmlEmpty(detailFinalis['deskripsi']))) ...[

                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Padding(
                            padding: kGlobalPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                if (detailFinalis['usia'] != null && detailFinalis['usia'] != 0) ...[
                                  SizedBox(height: 12),
                                  Text(ageText!, style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    detailFinalis['usia'].toString(),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],

                                if (detailFinalis['profesi'] != null && detailFinalis['profesi'] != '') ...[
                                  SizedBox(height: 12),
                                  Text(activityText!, style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(detailFinalis['profesi']),
                                ],

                                if (!isHtmlEmpty(detailFinalis['deskripsi'])) ...[
                                  SizedBox(height: 12),
                                  Text(biographyText!, style: TextStyle(fontWeight: FontWeight.bold)),
                                  Html(
                                    data: detailFinalis['deskripsi'],
                                    style: {
                                      '*': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                                      'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                                    },
                                  ),
                                ],

                                SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
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
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: buildBottomVideo(),
                                )
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
              
              isTutup || isBeforeOpen || widget.close_payment == '1' || remaining.inSeconds == 0
              ? SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      "${bahasa['paket']} $counts ${counts > 1 ? bahasa['text_votes'] : bahasa['text_vote']} ${detailvote['multiplier'] > 1 ? 'x${detailvote['multiplier']}' : ''} \n1 ${bahasa['finalis']}${countData > 1 ? 's' : ''}",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                
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
                onPressed: (belumPilihPaket ||
                    paketBerbayarTapiHargaNol ||
                    widget.close_payment == '1' ||
                    remaining.inSeconds == 0)
                ? null
                : () async {
                  if (isButtonClicked) return;

                  isButtonClicked = true;

                  try {
                    final storedToken = await StorageService.getToken() ?? '';
                    var getUser = await StorageService.getUser();
                    String? idUser = getUser['id'];

                    await refreshAfterVerification(storedToken, getUser['email'] ?? '', langCode!);

                    getUser = await StorageService.getUser();

                    if (detailvote['flag_login'] == '1' && storedToken.isEmpty) {
                      await EmailVerifModal.showLogin(context, bahasa, color, onLoginSuccess: _onAfterLogin);
                      return;
                    }

                    if (detailvote['flag_login'] == '0' && detailvote['flag_verify_email'] == '1' && storedToken.isEmpty) {
                      await EmailVerifModal.showLogin(context, bahasa, color, onLoginSuccess: _onAfterLogin);
                      return;
                    }

                    if (detailvote['flag_verify_email'] == '1' && getUser['verifEmail'] == '0') {
                      await EmailVerifModal.show(context, storedToken, langCode!, bahasa, getUser['email'] ?? '', color);
                      return;
                    }

                    if (mounted) {
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
                    }
                  } finally {
                    if (mounted) setState(() => isButtonClicked = false);
                  }
                },
                child: Text(
                  remaining.inSeconds == 0
                    ? endVote!
                    : isBeforeOpen
                        ? bahasa['segera']
                        : detailvote['close_payment'] == '1'
                            ? bahasa['tutup_sementara']
                            : detailvote['harga'] != 0
                                ? bayarText!
                                : bahasa['lanjutkan'],
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
    _countdownTimer?.cancel();
    controllers?.dispose();
    _ytTopController?.dispose();
    _ytBottomController?.dispose();
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

  Widget buildTopVideo() {
    if (_ytTopController == null) return const SizedBox.shrink();

    return VideoSection(
      key: const ValueKey("top_video"),
      controller: _ytTopController!,
    );
  }

  Widget buildBottomVideo() {
    if (_ytBottomController == null) return const SizedBox.shrink();

    return VideoSection(
      key: const ValueKey("bottom_video"),
      controller: _ytBottomController!,
    );
  }
}