// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/helper/video_section.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_manual.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool canDownload = false;

  String buttonText = '';

  bool _isLoading = true;
  int counts = 0;
  Map<String, dynamic> detailFinalis = {};
  TextEditingController? controllers;
  Map<String, dynamic> detailvote = {};
  Map<String, dynamic> voteLang = {};

  var idVote;
  List<String> ids_finalis = [];
  List<String> names_finalis = [];
  List<int> counts_finalis = [];

  final List<int> voteOptions = [10, 50, 100, 250, 500, 1000];
  int? selectedVotes;

  String? langCode, currencyCode;
  String? notLogin, notLoginDesc, loginText;
  String? totalHargaText, hargaText, hargaDetail, bayarText;
  String? endVote, voteOpen, voteOpenAgain;
  String? detailfinalisText;
  String? noDataText;
  String? ageText, activityText, biographyText, scanQrText, downloadQrText, tataCaraText, videoProfilText, noValidText, socialMediaText;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadFinalis();
    });
  }

  Future<void> _loadFinalis() async {
    final idFinalis = widget.id_finalis;
    if (idFinalis.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    final resultFinalis = await ApiService.get("/finalis/$idFinalis", xLanguage: langCode);
    final tempFinalis = resultFinalis?['data'] ?? {};

    idVote = tempFinalis['id_vote']?.toString();
    Map<String, dynamic> tempDetailVote = {};

    if (idVote != null && idVote.isNotEmpty) {
      final resultDetailVote = await ApiService.get("/vote/$idVote", xLanguage: langCode, xCurrency: currencyCode);
      tempDetailVote = resultDetailVote?['data'] ?? {};
    }
    
    await _precacheAllImages(context, tempFinalis);

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

        DateTime deadline = DateTime.parse(detailvote['tanggal_tutup_vote']);
        Duration remaining = Duration.zero;
        final now = DateTime.now();
        final difference = deadline.difference(now);

        remaining = difference.isNegative ? Duration.zero : difference;

        DateTime bukaVote = DateTime.parse(detailvote['real_tanggal_buka_vote']);
        bool isBeforeOpen = DateTime.now().isBefore(bukaVote);

        String formattedBukaVote = DateFormat("dd MMM yyyy HH:mm").format(bukaVote);
        
        if (isBeforeOpen) {
          buttonText = '$voteOpen $formattedBukaVote';
        } else if (detailvote['close_payment'] == '1') {
          buttonText = '$voteOpenAgain ${widget.tanggal_buka_payment}';
        }

        if (remaining.inSeconds == 0 || isBeforeOpen) {
          isTutup = true;
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempdetailFinalis = await LangService.getJsonData(langCode!, 'detail_finalis');
    final tempvoteLang = await LangService.getJsonData(langCode!, 'detail_vote');
    final tempnotLoginText = await LangService.getText(langCode!, "notLogin");
    final tempnotLoginDesc = await LangService.getText(langCode!, "notLoginDesc");
    final templogin = await LangService.getText(langCode!, "login");

    setState(() {
      totalHargaText = tempdetailFinalis['total_harga'];
      hargaText = tempdetailFinalis['harga'];
      hargaDetail = tempdetailFinalis['harga_detail'];
      bayarText = tempdetailFinalis['bayar'];

      endVote = tempdetailFinalis['end_vote'];
      voteOpen = tempdetailFinalis['vote_open'];
      voteOpenAgain = tempdetailFinalis['vote_open_again'];
      
      notLogin = tempnotLoginText;
      notLoginDesc = tempnotLoginDesc;
      loginText = templogin;
      
      detailfinalisText = tempdetailFinalis['detail_finalis'];

      noDataText = tempdetailFinalis['no_data'];
      ageText = tempdetailFinalis['age'];
      activityText = tempdetailFinalis['aktivitas'];
      biographyText = tempdetailFinalis['biografi'];
      scanQrText = tempdetailFinalis['scan_vote'];
      downloadQrText = tempdetailFinalis['unduh_qr'];
      tataCaraText = tempdetailFinalis['tatacara_vote'];
      videoProfilText = tempdetailFinalis['profile_video'];
      noValidText = tempdetailFinalis['video_no_valid'];
      socialMediaText = tempdetailFinalis['sosial_media'];

      voteLang = tempvoteLang;
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

  final formatter = NumberFormat.decimalPattern("id_ID");
  num totalHargaAsli = 0;
  num get totalHarga {
    num hargaItem = 0;
    if (currencyCode != null) {
      hargaItem = hargaAsli * counts;
      totalHargaAsli = hargaItem;
      hargaItem = hargaItem * (detailvote['rate_currency_user'] / detailvote['rate_currency_vote']);
      hargaItem = (hargaItem * 100).ceil() / 100;
    } else {
      hargaItem = harga * counts;
    }
    return hargaItem;
  }

  void _updateCountFromInput(String value) {
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      counts = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? buildSkeletonHome()
          : buildKontenDetail()
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

    String themeName = 'Red';
    if (detailvote.containsKey('theme_name') && detailvote['theme_name'] != null) {
      themeName = detailvote['theme_name'].toString();
    }

    
    Color color = colorMap[themeName] ?? Colors.red;

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
                            Text(
                              detailFinalis['nama_finalis'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                  
                            const SizedBox(height: 10,),
                            (detailFinalis['nama_tambahan'] == null || detailFinalis['nama_tambahan'].toString().trim().isEmpty)
                              ? Text(
                                  noDataText!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(detailFinalis['nama_tambahan'],
                                style: const TextStyle(color: Colors.grey),
                              ),

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
                                      '$voteOpenAgain ${widget.tanggal_buka_payment}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white),
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ]
                            else if (isTutup) ... [
                              SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                                decoration: BoxDecoration(
                                  color: isTutup ? Colors.grey : color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      buttonText,
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
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
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
                                      onChanged: (value) => _updateCountFromInput(value),
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
                                            NumberFormat.decimalPattern("id_ID").format(voteCount),
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
                  
                              if (detailFinalis['deskripsi'] != null && detailFinalis['deskripsi'].toString().isNotEmpty) ... [
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
                                ),
                  
                                const SizedBox(height: 12,),
                                Text(
                                  scanQrText!,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                  
                                const SizedBox(height: 12,),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: canDownload ? color : Colors.grey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: canDownload ? () {
                                      
                                    }
                                    : null,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          downloadQrText!,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        const SizedBox(width: 10,),
                                        Icon(
                                          Icons.download, color: Colors.white, size: 15,
                                        )
                                      ],
                                    )
                                  )
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
                                      await TutorModal.show(context, detailvote['tutorial_vote'], voteLang['tutorial_vote_text']);
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
                                VideoSection(link: detailFinalis['video_profile'], headerText: videoProfilText!, noValidText: noValidText!,),
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
                  
                      const SizedBox(height: 12),
                  
                    ],
                  )
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // kiri
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // penting biar nggak overflow
                children: [
                  Text("Total Harga"),
                  Text(
                    harga == 0
                    ? 'Gratis'
                    : currencyCode == null 
                      ? "${detailvote['currency']} ${formatter.format(totalHarga)}"
                      : "$currencyCode ${formatter.format(totalHarga)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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
                },
                child: Text(
                  isTutup
                  ? "Vote telah Berakhir"
                  : "Lanjut Pembayaran",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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