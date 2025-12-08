// ignore_for_file: non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/helper/video_section.dart';
import 'package:kreen_app_flutter/modal/paket_vote_modal.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_paket.dart';
import 'package:kreen_app_flutter/modal/tutor_modal.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailFinalisPaketPage extends StatefulWidget {
  final String id_finalis;
  final int vote;
  final int index;
  final total_detail;
  final String? id_paket_bw;
  final Duration? remaining;
  final String? close_payment;
  final String? tanggal_buka_payment;

  const DetailFinalisPaketPage({super.key, required this.id_finalis, required this.vote, required this.index, required this.total_detail, required this.id_paket_bw, this.remaining, this.close_payment, this.tanggal_buka_payment});

  @override
  State<DetailFinalisPaketPage> createState() => _DetailFinalisPaketPageState();
}

class _DetailFinalisPaketPageState extends State<DetailFinalisPaketPage> {
  num? harga;
  bool isTutup = false;
  bool canDownload = false;

  String buttonText = '';

  bool _isLoading = true;
  int counts = 0;
  num? harga_akhir;
  late String? id_paket = widget.id_paket_bw;
  int detailIndex = 0;
  Map<String, dynamic> detailFinalis = {};
  TextEditingController? controllers;
  Map<String, dynamic> detailvote = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinalis();
    });
  }

  List<Map<String, dynamic>> paketTerbaik = [];
  List<Map<String, dynamic>> paketLainnya = [];

  Future<void> _loadFinalis() async {
    
    final resultFinalis = await ApiService.get("/finalis/${widget.id_finalis}");
    final tempFinalis = resultFinalis?['data'] ?? {};

    final resultDetailVote = await ApiService.get("/vote/${tempFinalis['id_vote']}");
    final tempDetailVote = resultDetailVote?['data'] ?? {};

    final tempPaket = tempDetailVote['vote_paket'];

    await _precacheAllImages(context, tempFinalis);

    if (mounted) {
      setState(() {
        detailFinalis = tempFinalis;
        _isLoading = false;

        counts = widget.vote;
        detailIndex = widget.index;

        controllers = TextEditingController(
          text: widget.vote.toString(),
        );

        detailvote = tempDetailVote;
        harga = tempDetailVote['harga'];

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

        DateTime deadline = DateTime.parse(detailvote['tanggal_tutup_vote']);
        Duration remaining = Duration.zero;
        final now = DateTime.now();
        final difference = deadline.difference(now);

        remaining = difference.isNegative ? Duration.zero : difference;

        DateTime bukaVote = DateTime.parse(detailvote['real_tanggal_buka_vote']);
        bool isBeforeOpen = DateTime.now().isBefore(bukaVote);

        String formattedBukaVote = DateFormat("dd MMM yyyy HH:mm").format(bukaVote);
        
        if (isBeforeOpen) {
          buttonText = 'Vote akan dibuka pada $formattedBukaVote';
        } else if (detailvote['close_payment'] == '1') {
          buttonText = 'Vote akan dibuka Kembali pada ${widget.tanggal_buka_payment}';
        } else {
          buttonText = 'Pilih Paket Vote';
        }

        if (remaining.inSeconds == 0 || isBeforeOpen) {
          isTutup = true;
        }
      });
    }
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
  num get totalHarga {
    final hargaItem = harga_akhir;
    if (hargaItem == null) return 0;
    return hargaItem;
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

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text("Detail Finalis"), 
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
              height: 40,
              width: 40,
            ),
          )
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
                      detailFinalis['poster_finalis'] != null
                      ? 
                        Image.network(
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
                  
                            SizedBox(height: 10,),
                            (detailFinalis['nama_tambahan'] == null || detailFinalis['nama_tambahan'].toString().trim().isEmpty)
                              ? Text(
                                  "Tidak ada data",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(detailFinalis['nama_tambahan'],
                                style: TextStyle(color: Colors.grey),
                              ),
                  
                            SizedBox(height: 10,),
                            Text(
                              detailFinalis['nomor_urut'].toString(),
                            ),
                  
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
                                        Text("Harga"),
                                      ],
                                    ),
                  
                                    const SizedBox(height: 10,),
                                    Text(
                                      harga == 0
                                      ? 'Gratis'
                                      : "${detailvote['currency']} ${formatter.format(harga)}",
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
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                              decoration: BoxDecoration(
                                color: isTutup || widget.close_payment == '1'  ? Colors.grey : color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: (isTutup || widget.close_payment == '1')
                                ? null
                                : () async {
                  
                                  final selectedQty = await PaketVoteModal.show(
                                    context,
                                    detailIndex,
                                    paketTerbaik,
                                    paketLainnya,
                                    color,
                                    bgColor,
                                    id_paket!,
                                    detailvote['currency']
                                  );
                  
                                  if (selectedQty != null) {
                                    setState(() {
                                      counts = selectedQty['counts'];
                                      harga_akhir = selectedQty['harga'];
                                      id_paket = selectedQty['id_paket'];
                                    });
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        buttonText,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    if (widget.close_payment != '1') ...[
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            ),
                          ],
                        ),
                      ),
                  
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
                                  "Usia",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                  
                                (detailFinalis['usia'] == 0)
                                  ? Text(
                                      "Tidak ada data",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : Text(detailFinalis['usia'].toString(),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                  
                              if (detailFinalis['profesi'] != null) ... [
                                SizedBox(height: 12,),
                                Text(
                                  "Aktifitas",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  detailFinalis['profesi']
                                ),
                              ],
                  
                              if (detailFinalis['deskripsi'] != null) ... [
                                SizedBox(height: 12,),
                                Text(
                                  "Deskripsi",
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
                      ),
                  
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
                                ),
                  
                                SizedBox(height: 12,),
                                Text(
                                  "Scan QR untuk Vote",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                  
                                SizedBox(height: 12,),
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
                                          "Save QR",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        SizedBox(width: 10,),
                                        Icon(
                                          Icons.download, color: Colors.white, size: 15,
                                        )
                                      ],
                                    )
                                  )
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
                                      await TutorModal.show(context, 'id');
                                    },
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Tata Cara Vote",
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
                              VideoSection(link: detailFinalis['video_profile'])
                            ],
                          ),
                        ),
                      ],
                  
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
                              "Media Social",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                             SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.facebook,
                                  color:  Color(0xFF1877F2),
                                  link: detailFinalis['facebook'],
                                  platform: "facebook",
                                ),
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.twitter,
                                  color:  Color(0xFF1DA1F2),
                                  link: detailFinalis['twitter'],
                                  platform: "twitter",
                                ),
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.linkedin,
                                  color:  Color(0xFF0077B5),
                                  link: detailFinalis['linkedin'],
                                  platform: "linkedin",
                                ),
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
                  
                      SizedBox(height: 12),
                  
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding:  EdgeInsets.all(8),
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
                    : "${detailvote['currency']} ${formatter.format(totalHarga == 0 ? widget.total_detail : totalHarga)}",
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
                              const Text(
                                "Ayo... Login terlebih Dahulu",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 12),
                              const Text(
                                "Klik tombol dibawah ini untuk menuju halaman Login",
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
                                child: const Text(
                                  "Login Sekarang",
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
                            builder: (_) => StatePaymentPaket(
                              id_vote: detailFinalis['id_vote'],
                              id_finalis: detailFinalis['id_finalis'],
                              nama_finalis: detailFinalis['nama_finalis'],
                              counts: counts,
                              totalHarga: totalHarga,
                              id_paket: id_paket!,
                              fromDetail: true,
                              idUser: idUser,
                            ),
                          ),
                        );
                      }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatePaymentPaket(
                          id_vote: detailFinalis['id_vote'],
                          id_finalis: detailFinalis['id_finalis'],
                          nama_finalis: detailFinalis['nama_finalis'],
                          counts: counts,
                          totalHarga: totalHarga,
                          id_paket: id_paket!,
                          fromDetail: true,
                          idUser: idUser,
                        ),
                      ),
                    );
                  }

                  
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
        duration:  Duration(milliseconds: 200),
        padding:  EdgeInsets.all(12),
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