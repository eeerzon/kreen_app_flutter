// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/checking_html.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/video_section.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_manual.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_1_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_2_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_3_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_4_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_5_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_6_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote_lang.dart';
import 'package:kreen_app_flutter/helper/download_qr.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaderboardSingleVote extends StatefulWidget {
  final String id_finalis;
  final int count;
  final int? indexWrap;
  final String? close_payment;
  final String? tanggal_buka_vote;
  final String? flag_hide_nomor_urut;
  const LeaderboardSingleVote({super.key, required this.id_finalis, required this.count, this.indexWrap, this.close_payment, this.tanggal_buka_vote, this.flag_hide_nomor_urut});

  @override
  State<LeaderboardSingleVote> createState() => _LeaderboardSingleVoteState();
}

class _LeaderboardSingleVoteState extends State<LeaderboardSingleVote> {
  num harga = 0;
  num hargaAsli = 0;
  bool isTutup = false;
  bool canDownload = true;

  final prefs = FlutterSecureStorage();
  String? langCode, currencyCode;
  String? flag_paket;

  bool _isLoading = true;
  int counts = 0;
  Map<String, dynamic> detailFinalis = {};
  TextEditingController? controllers;
  Map<String, dynamic> detailvote = {};
  List<dynamic> ranking = [];

  var idVote;
  List<String> ids_finalis = [];
  List<String> names_finalis = [];
  List<int> counts_finalis = [];

  final List<int> voteOptions = [10, 50, 100, 250, 500, 1000];
  int? selectedVotes;

  Map<String, dynamic>? bahasa;

  String? notLogin, notLoginDesc, loginText;
  String? totalHargaText, hargaText, hargaDetail, bayarText;
  String? endVote, voteOpen, voteOpenAgain;
  String? buttonPilihPaketText;
  String? detailfinalisText;
  String? noDataText;
  String? ageText, activityText, biographyText, scanQrText, downloadQrText, tataCaraText, videoProfilText, noValidVideo, socialMediaText;

  int totalQty = 0;
  int countData = 1;

  bool showErrorBar = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadFinalis();
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

      buttonPilihPaketText = tempbahasa['pick_paket'];
      detailfinalisText = tempbahasa['detail_finalis'];

      noDataText = tempbahasa['no_data'];
      ageText = tempbahasa['usia'];
      activityText = tempbahasa['aktivitas'];
      biographyText = tempbahasa['biografi'];
      scanQrText = tempbahasa['scan_vote'];
      downloadQrText = tempbahasa['unduh_qr'];
      tataCaraText = tempbahasa['tatacara_vote'];
      videoProfilText = tempbahasa['profile_video'];
      noValidVideo = tempbahasa['video_no_valid'];
      socialMediaText = tempbahasa['sosial_media'];
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
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
    List<dynamic> tempRanking = [];

    if (idVote != null && idVote.isNotEmpty) {
      final resultDetailVote = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
      tempDetailVote = resultDetailVote?['data'] ?? {};

      final resultLeaderboard = await ApiService.get("/vote/$idVote/leaderboard", xLanguage: langCode);
      tempRanking = resultLeaderboard?['data'] ?? [];
    }

    await _precacheAllImages(context, tempFinalis, tempRanking);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        detailFinalis = tempFinalis;

        controllers = TextEditingController(
          text: widget.count.toString(),
        );

        detailvote = tempDetailVote;
        ranking = tempRanking;
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

        DateTime deadline = DateTime.parse(detailvote['tanggal_tutup_vote']);
        Duration remaining = Duration.zero;
        final now = DateTime.now();
        final difference = deadline.difference(now);

        remaining = difference.isNegative ? Duration.zero : difference;

        if (remaining.inSeconds == 0) {
          isTutup = true;
        }

        _isLoading = false;
        showErrorBar = false;
      });
    }
  }

  Future<void> _precacheAllImages(
    BuildContext context,
    Map<String, dynamic> finalis,
    List<dynamic> ranking,
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

    for (var item in ranking) {
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
    int view_api = 0;
    if (detailvote['leaderboard_tipe'] == 'number') {
      view_api = 2;
    } else if (detailvote['leaderboard_tipe'] == 'percent') {
      view_api = 3;
    } else if (detailvote['leaderboard_tipe'] == 'hidden') {
      view_api = 4;
    } else if (detailvote['leaderboard_tipe'] == 'bar-percent') {
      view_api = 5;
    } else if (detailvote['leaderboard_tipe'] == 'bar-number') {
      view_api = 6;
    }

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

    final dateStr = detailvote['tanggal_grandfinal_mulai']?.toString() ?? '-';
    
    String formattedDate = '-';
    
    if (dateStr.isNotEmpty) {
      try {
        // parsing string ke DateTime
        final date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
        if (langCode == 'id') {
          // Bahasa Indonesia
          final formatter = DateFormat("EEEE, dd MMMM yyyy", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          // Bahasa Inggris
          final formatter = DateFormat("EEEE, MMMM d yyyy", "en_US");
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

    final formatter = NumberFormat.decimalPattern("en_US");

    DateTime mulai = DateTime.parse("${detailvote['tanggal_grandfinal_mulai']} ${detailvote['waktu_mulai']}");
    DateTime selesai = DateTime.parse("${detailvote['tanggal_grandfinal_mulai']} ${detailvote['waktu_selesai']}");

    String jamMulai = "${mulai.hour.toString().padLeft(2, '0')}:${mulai.minute.toString().padLeft(2, '0')}";
    String jamSelesai = "${selesai.hour.toString().padLeft(2, '0')}:${selesai.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
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
                        child: detailFinalis['poster_finalis'] != null
                          ? Image.network(
                              detailFinalis['poster_finalis'],
                              width: double.infinity,
                              fit: BoxFit.cover, 
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  "$baseUrl/noimage_finalis.png",
                                  width: double.infinity,
                                  fit: BoxFit.cover, 
                                );
                              },
                            )
                          : Image.network(
                              "$baseUrl/noimage_finalis.png",
                              width: double.infinity,
                              fit: BoxFit.cover, 
                            ),
                      ),
                  
                      const SizedBox(height: 15,),
                      Container(
                        padding: kGlobalPadding,
                        color: Colors.white,
                        child: Column(
                          children: [

                            const SizedBox(height: 10,),
                            Text(
                              detailFinalis['nama_finalis'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            if (detailFinalis['nama_tambahan'] != null && detailFinalis['nama_tambahan'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 10,),
                              Text(detailFinalis['nama_tambahan'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                  
                            if (widget.flag_hide_nomor_urut == "0") ...[
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
                  
                            if (widget.close_payment == '1') ... [
                              SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                                decoration: BoxDecoration(
                                  color: widget.close_payment == '1' ? Colors.grey : color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$voteOpenAgain ${widget.tanggal_buka_vote}',
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
                                    onTap: (isTutup)
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
                                        color: isTutup ? Colors.grey : color,
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300,),
                                    ),
                                    child: TextField(
                                      controller: controllers,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      enabled: !isTutup,
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
                                    onTap: (isTutup)
                                      ? null
                                      : () {
                                          setState(() {

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
                                        color: isTutup ? Colors.grey : color,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(FontAwesomeIcons.plus, size: 15, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                  
                            const SizedBox(height: 15,),
                            if (counts > 0)
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                alignment: WrapAlignment.center,
                                children: voteOptions.asMap().entries.map((entry) {
                                  final voteCount = entry.value;
                                  final isSelected = selectedVotes == voteCount && counts > 0;
                  
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
                      ],
                      
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
                                            bahasa!['download_scan_gagal'],
                                            bahasa!['download_scan_berhasil'],
                                            bahasa!['kesalahan_simpan_scan'],
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
                                      await TutorModal.show(context, detailvote['tutorial_vote'], bahasa!['tutorial_vote_text']);
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
                                VideoSection(link: detailFinalis['video_profile'], headerText: videoProfilText!, noValidText: noValidVideo!),
                              ],
                            ),
                          ),
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
                                borderRadius: BorderRadius.circular(8),
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
                                          color:  Color(0xFF1877F2),
                                          link: detailFinalis['facebook'],
                                          platform: "facebook",
                                        ),

                                      if (detailFinalis['twitter'] != null && detailFinalis['twitter'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.twitter,
                                          color:  Color(0xFF1DA1F2),
                                          link: detailFinalis['twitter'],
                                          platform: "twitter",
                                        ),

                                      if (detailFinalis['linkedin'] != null && detailFinalis['linkedin'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.linkedin,
                                          color:  Color(0xFF0077B5),
                                          link: detailFinalis['linkedin'],
                                          platform: "linkedin",
                                        ),

                                      if (detailFinalis['instagram'] != null && detailFinalis['instagram'].toString().trim().isNotEmpty)
                                        _buildSocialButton(
                                          icon: FontAwesomeIcons.instagram,
                                          color:  Color(0xFFE1306C),
                                          link: detailFinalis['instagram'],
                                          platform: "instagram",
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      ],

                      // DESKRIPSI
                      const SizedBox(height: 12,),
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Padding(
                          padding: kGlobalPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detailvote['judul_vote'] ?? '-',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

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
                                          Image.network(
                                            detailvote['icon_penyelenggara'],
                                            width: 80,   // atur sesuai kebutuhan
                                            height: 80,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/img_broken.jpg',
                                                height: 80,
                                                width: 80,
                                                fit: BoxFit.contain,
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
                                                  bahasa!['penyelenggara'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  detailvote['nama_penyelenggara'],
                                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                                  softWrap: true,          // biar teks bisa kebungkus
                                                  overflow: TextOverflow.visible, 
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // const SizedBox(height: 40,),
                                      // Text(
                                      //   "Deskripsi",
                                      //   style: TextStyle(fontWeight: FontWeight.bold),
                                      // ),

                                      // const SizedBox(height: 12,),
                                      // Container(
                                      //   color: Colors.white,
                                      //   child: Padding(
                                      //     padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                                      //     child: Column(
                                      //       children: [
                                      //         Column(
                                      //           crossAxisAlignment: CrossAxisAlignment.start,
                                      //           mainAxisAlignment: MainAxisAlignment.center,
                                      //           children: [
                                      //             if (detailvote['merchant_description'] != null) ... [
                                      //               Html(
                                      //                 data: detailvote['merchant_description'],
                                      //                 style: {
                                      //                   "p": Style(
                                      //                     margin: Margins.zero,
                                      //                     padding: HtmlPaddings.zero,
                                      //                   ),
                                      //                   "body": Style(
                                      //                     margin: Margins.zero,
                                      //                     padding: HtmlPaddings.zero,
                                      //                   ),
                                      //                 },
                                      //               ),
                                      //               SizedBox(height: 12,)
                                      //             ],
                                      //             Html(
                                      //               data: detailvote['deskripsi'],
                                      //                 style: {
                                      //                   "p": Style(
                                      //                     margin: Margins.zero,
                                      //                     padding: HtmlPaddings.zero,
                                      //                   ),
                                      //                   "body": Style(
                                      //                     margin: Margins.zero,
                                      //                     padding: HtmlPaddings.zero,
                                      //                   ),
                                      //                 },
                                      //             )
                                      //           ],
                                      //         ),
                                      //       ],
                                      //     ),
                                      //   ) 
                                      // ),

                                      const SizedBox(height: 20,),
                                      Text(
                                        bahasa!['grandfinal_detail'],
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
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  SvgPicture.network(
                                                    "$baseUrl/image/icon-vote/$themeName/Calendar.svg",
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
                                                          formattedDate,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12,),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  SvgPicture.network(
                                                    "$baseUrl/image/icon-vote/$themeName/Time.svg",
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.contain,
                                                  ),

                                                  const SizedBox(width: 12),
                                                  //text
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text: "$jamMulai - $jamSelesai",
                                                            style: const TextStyle(
                                                              color: Colors.black,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text: detailvote['code_timezone'] == 'WIB'
                                                              ? " (GMT+7)"
                                                              : detailvote['code_timezone'] == 'WITA'
                                                                ? " (GMT+8)"
                                                                : detailvote['code_timezone'] == 'WIT'
                                                                  ? " (GMT+9)"
                                                                  : "",
                                                            style: TextStyle(
                                                              color: color,
                                                              fontWeight: FontWeight.bold,
                                                              fontStyle: FontStyle.italic,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ) 
                                      ),

                                      // const SizedBox(height: 20,),
                                      // Text(
                                      //   "Lokasi",
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
                                      //           crossAxisAlignment: CrossAxisAlignment.center,
                                      //           children: <Widget>[
                                      //             SvgPicture.network(
                                      //               "$baseUrl/image/icon-vote/$themeName/Locations.svg",
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
                                      //                     detailvote['lokasi_alamat'] ?? '-',
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

                                      // const SizedBox(height: 20,),
                                      // Text(
                                      //   "Venue",
                                      //   style: TextStyle(fontWeight: FontWeight.bold),
                                      // ),

                                      // const SizedBox(height: 12,),
                                      // Container(
                                      //   color: Colors.white,
                                      //   child: Padding(
                                      //     padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
                                      //     child: Column(
                                      //       children: [
                                      //         Row(
                                      //           crossAxisAlignment: CrossAxisAlignment.center,
                                      //           children: <Widget>[
                                      //             SvgPicture.network(
                                      //               "$baseUrl/image/icon-vote/$themeName/Locations.svg",
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
                                      //                     detailvote['lokasi_nama_tempat'],
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
                                    ],
                                  ),
                                ) 
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12,),
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsetsGeometry.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                            // === LEADERBOARD ===
                            if (detailvote['leaderboard_limit_tampil'] != -1)
                              DetailVoteLang(
                                values: bahasa!,
                                child: Container(
                                  color: Colors.white,
                                  padding: kGlobalPadding,
                                  child: _buildLeaderboardSection(view_api, ranking, detailvote, langCode!),
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                      ),
                  
                      const SizedBox(height: 12),
                  
                    ],
                  )
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // kiri
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // penting biar nggak overflow
                children: [
                  Text(totalHargaText!),
                  Text(
                    harga == 0
                    ? hargaDetail!
                    : currencyCode == null
                      ? "${detailvote['currency']} ${formatter.format(totalHarga)}"
                      : "$currencyCode ${formatter.format(totalHarga)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    "Qty $totalQty ${bahasa!['text_vote']}\n$countData ${bahasa!['finalis']}(s)",
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

                    if (detailvote['flag_login'] == '1') {
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
                                notLogin!,
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
                                  backgroundColor: color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                  elevation: 2,
                                ),
                                child: Text(
                                  loginText!,
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ).show();
                      } else {
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
                              price: hargaAsli,
                              fromDetail: true,
                              idUser: idUser,
                              flag_login: detailvote['flag_login'],
                              rateCurrency: detailvote['rate_currency_vote'],
                              rateCurrencyUser: detailvote['rate_currency_user'],
                            ),
                          ),
                        );
                      }
                    } else {
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
                            price: hargaAsli,
                            fromDetail: true,
                            idUser: idUser,
                            flag_login: detailvote['flag_login'],
                            rateCurrency: detailvote['rate_currency_vote'],
                            rateCurrencyUser: detailvote['rate_currency_user'],
                          ),
                        ),
                      );
                    }
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

  Widget _buildLeaderboardSection(int api, List<dynamic> ranking, Map<String, dynamic> vote, String langCode) {
    switch (api) {
      case 2:
        return LeaderboardSection_2(ranking: ranking, data: vote, langCode: langCode,);
      case 3:
        return LeaderboardSection_3(ranking: ranking, data: vote, langCode: langCode,);
      case 4:
        return LeaderboardSection_4(ranking: ranking, data: vote, langCode: langCode,);
      case 5:
        return LeaderboardSection_5(ranking: ranking, data: vote, langCode: langCode,);
      case 6:
        return LeaderboardSection_6(ranking: ranking, data: vote, langCode: langCode,);
      default:
        return LeaderboardSection(ranking: ranking, data: vote, langCode: langCode,);
    }
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
          borderRadius: BorderRadius.circular(8),
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
}