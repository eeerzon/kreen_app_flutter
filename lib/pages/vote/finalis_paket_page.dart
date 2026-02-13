// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/modal/paket_vote_modal.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_paket.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class FinalisPaketPage extends StatefulWidget {
  final String id_vote;
  const FinalisPaketPage({super.key, required this.id_vote});

  @override
  State<FinalisPaketPage> createState() => _FinalisPaketPageState();
}

class _FinalisPaketPageState extends State<FinalisPaketPage> {
  String? langCode;
  var get_user;
  DateTime deadline = DateTime(2025, 09, 26, 13, 30, 00, 00, 00);
  late DateTime deadlineUtc;

  Duration remaining = Duration.zero;
  Timer? _timer;

  bool _isLoading = true;
  int counts = 0;
  num? harga_akhir;
  num harga_akhir_asli = 0;
  String id_paket = '';
  String? slctedIdVote, slctedIdFinalis, slctedNamaFinalis;

  List<TextEditingController> controllers = [];

  String? findFinalistText;
  String? notLogin, notLoginDesc, searchHintText, loginText;
  String? totalHargaText, hargaText, hargaDetail, bayarText;
  String? endVote, voteOpen, voteOpenAgain;
  String? countDownText, daysText, hoursText, minutesText, secondsText;
  String? buttonPilihPaketText;
  String? detailfinalisText, cariFinalisText;
  String? noDataText;

  int countData = 0;

  Map<String, dynamic> vote = {};
  List<dynamic> finalis = [];

  List<Map<String, dynamic>> paketTerbaik = [];
  List<Map<String, dynamic>> paketLainnya = [];
  
  bool showErrorBar = false;
  String errorMessage = ''; 

  bool isPaymentClosed = false;

  Future<void> checkPaymentStatus(String? close_payment, String? tanggal_buka_payment) async {
    if (close_payment != '1') {
      isPaymentClosed = false;
      return;
    }

    try {
      final reopenTime = DateTime.parse(tanggal_buka_payment!);
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadVotes();
      _startCountdown();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        await checkPaymentStatus(vote['close_payment'], vote['tanggal_buka_payment']);
      });
    });
  }

  Future<void> _loadVotes() async {

    final resultVote = await ApiService.get("/vote/${widget.id_vote}", xLanguage: langCode, xCurrency: currencyCode);
    if (resultVote == null || resultVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultVote?['message'];
      });
      return;
    }
    final resultFinalis = await ApiService.get("/vote/${widget.id_vote}/finalis?page_size=100", xLanguage: langCode);
    if (resultFinalis == null || resultFinalis['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultFinalis?['message'];
      });
      return;
    }

    final tempVote = resultVote['data'] ?? {};
    final tempFinalis = resultFinalis['data'] ?? [];

    final tempPaket = tempVote['vote_paket'];
    
    await _precacheAllImages(context, tempFinalis);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        vote = tempVote;
        finalis = tempFinalis;

        deadline = DateTime.parse(vote['real_tanggal_tutup_vote']);
        // deadlineUtc = DateTime.parse(vote['real_tanggal_tutup_vote']);
        deadlineUtc = parseWib(vote['real_tanggal_tutup_vote']);
        deadlineUtc = deadlineUtc.toLocal();
      
        controllers = List.generate(vote.length, (i) {
          return TextEditingController(text: "0");
        });

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
        _isLoading = false;
        showErrorBar = false;
      });
    }
  }

  Map<String, dynamic> bahasa = {};
  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, 'bahasa');

    setState(() {
      bahasa = tempbahasa;

      totalHargaText = tempbahasa['total_harga'];
      hargaText = tempbahasa['harga'];
      hargaDetail = tempbahasa['harga_detail'];
      bayarText = tempbahasa['bayar'];

      endVote = tempbahasa['end_vote'];
      voteOpen = tempbahasa['vote_open'];
      voteOpenAgain = tempbahasa['vote_open_again'];

      countDownText = tempbahasa['countdown_vote'];
      daysText = tempbahasa['day'];
      hoursText = tempbahasa['hour'];
      minutesText = tempbahasa['minute'];
      secondsText = tempbahasa['second'];

      findFinalistText = tempbahasa['button_find_finalist'];
      notLogin = tempbahasa['notLogin'];
      notLoginDesc = tempbahasa['notLoginDesc'];
      loginText = tempbahasa['login'];
      searchHintText = tempbahasa['search'];

      buttonPilihPaketText = tempbahasa['pick_paket'];
      detailfinalisText = tempbahasa['detail_finalis'];
      cariFinalisText = tempbahasa['search_finalis'];

      noDataText = tempbahasa['no_data'];
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
    List<dynamic> finalis
  ) async {
    List<String> allImageUrls = [];

    // Ambil semua file_upload dari ranking (juara / banner)
    for (var item in finalis) {
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
  num get totalHarga {
    final hargaItem = harga_akhir;
    if (hargaItem == null) return 0;
    return hargaItem;
  }

  void _startCountdown() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final nowUtc = DateTime.now().toUtc();
    final difference = deadlineUtc.difference(nowUtc);

    setState(() {
      remaining = difference.isNegative ? Duration.zero : difference;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.length >= 3) {
        _searchFinalis(value);
      } else if (value.isEmpty) {
        _resetFinalis();
      }
    });
  }

  Future<void> _searchFinalis(String keyword) async {
    final result = await ApiService.get('/vote/${widget.id_vote}/finalis?search=$keyword', xLanguage: langCode);
    // if (result == null || result['rc'] != 200) {
    //   setState(() {
    //     showErrorBar = true;
    //     errorMessage = result?['message'];
    //   });
    //   return;
    // }

    if (!mounted) return;
    if (mounted) {
      setState(() {
        finalis = result?['data'] ?? [];
        showErrorBar = false;
      });
    }
  }

  void _resetFinalis() {
    _loadVotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
            ? buildSkeletonHome()
            : buildKontenFinalis(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadVotes();
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

  Widget buildKontenFinalis(){
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
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
    if (vote['theme_name'] != null) {
      themeName = vote['theme_name'];
    }
    
    Color color = colorMap[themeName] ?? Colors.red;
    Color bgColor;
    if (color is MaterialColor) {
      bgColor = color.shade50;
    } else {
      bgColor = color.withOpacity(0.1);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(findFinalistText!),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                    vote['harga'] == 0
                    ? hargaDetail!
                    : currencyCode == null
                      ? "${vote['currency']} ${formatter.format(totalHarga)}"
                      : "$currencyCode ${formatter.format(totalHarga)}",
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
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                onPressed: (vote['harga'] != 0 && totalHarga == 0) || counts == 0
                    ? null
                    : () async {
                      final getUser = await StorageService.getUser();

                      String? idUser = getUser['id'];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatePaymentPaket(
                            id_vote: slctedIdVote!,
                            id_finalis: slctedIdFinalis!,
                            nama_finalis: slctedNamaFinalis!,
                            counts: counts,
                            totalHarga: totalHarga,
                            totalHargaAsli: harga_akhir_asli,
                            id_paket: id_paket,
                            fromDetail: false,
                            idUser: idUser,
                            flag_login: vote['flag_login'],
                            rateCurrency: vote['rate_currency_vote'],
                            rateCurrencyUser: vote['rate_currency_user'],
                            ),
                        ),
                      );
                    },
                child: Text(
                  remaining.inSeconds == 0
                  ? endVote!
                  : bayarText!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),


      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: CustomScrollView(
          slivers: [
            // konten atas (countdown)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: color, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: kGlobalPadding,
                    child: Column(
                      children: [
                        Text(countDownText!),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _timeBox("$days", daysText!, color),
                            const SizedBox(width: 20),
                            _timeBox("$hours".padLeft(2, "0"), hoursText!, color),
                            const SizedBox(width: 10),
                            _separator(color),
                            const SizedBox(width: 10),
                            _timeBox("$minutes".padLeft(2, "0"), minutesText!, color),
                            const SizedBox(width: 10),
                            _separator(color),
                            const SizedBox(width: 10),
                            _timeBox("$seconds".padLeft(2, "0"), secondsText!, color),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            //sticky search bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchBarDelegate(
                color: color,
                onSearchChanged: _onSearchChanged,
                searchHintText: cariFinalisText!,
              ),
            ),

            // grid view
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: buildGridView(vote, finalis, color, bgColor, themeName, noDataText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGridView(Map<String, dynamic> vote, List<dynamic> listFinalis, Color color, Color bgColor, String theme_name, String? noDataText) {

    final formatter = NumberFormat.decimalPattern("en_US");
    final hargaFormatted = formatter.format(vote['harga'] ?? 0);


    final dateStr = vote['tanggal_buka_payment']?.toString() ?? '-';
    
    String formattedDate = '-';

    if (dateStr.isNotEmpty) {
      try {
        final wibDate = parseWib(dateStr);
        // parsing string ke DateTime
        var date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
        date = wibDate.toLocal();
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
          if (day % 10 == 1 && day != 11) { suffix = 'st'; }
          else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
          else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
          formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
        }
      } catch (e) {
        formattedDate = '-';
      }
    }

    final bukaVoteUtc = DateTime.parse(vote['real_tanggal_buka_vote']);

    final nowUtc = DateTime.now().toUtc();

    bool isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

    String formattedBukaVote = DateFormat("$formatDateId HH:mm").format(bukaVoteUtc);

    String buttonText = '';
    
    if (isBeforeOpen) {
      buttonText = '$voteOpen $formattedBukaVote';
    } else if (vote['close_payment'] == '1') {
      buttonText = '$voteOpenAgain $formattedDate';
    } else {
      buttonText = buttonPilihPaketText!;
    }

    if (listFinalis.isEmpty) {
      return Column(
        children: [
          Image.asset(
            'assets/images/placeholder.png',
            width: 200,
            height: 200,
          ),

          SizedBox(height: 12,),

          Text(
            bahasa['no_data'] ?? 'No Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: listFinalis.length,
      itemBuilder: (context, index) {
        final item = listFinalis[index];
        bool ishas = true;
        if (item['poster_finalis'] == null) {
          ishas = false;
        }
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: ishas 
                      ? FadeInImage.assetNetwork(
                          placeholder: 'assets/images/img_placeholder.jpg',
                          image: item['poster_finalis'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              "$baseUrl/noimage_finalis.png",
                              width: double.infinity,
                              fit: BoxFit.cover, 
                            );
                          },
                        )
                      : FadeInImage.assetNetwork(
                          placeholder: 'assets/images/img_placeholder.jpg',
                          image: "$baseUrl/noimage_finalis.png",
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
                ),

                const SizedBox(height: 10),
                Text(
                  item['nama_finalis'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                
                if (item['nama_tambahan'] != null && item['nama_tambahan'] != "") ... [
                  SizedBox(height: 10),
                  Text(item['nama_tambahan'],
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
                
                if (vote['flag_hide_nomor_urut'] == "0") ... [
                  const SizedBox(height: 10),
                  Text(item['nomor_urut'].toString()),
                ],

                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SvgPicture.network(
                              "$baseUrl/image/icon-vote/$theme_name/dollar-coin.svg",
                              width: 25,
                              height: 25,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(width: 4),
                            //text
                            Text(hargaText!),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          vote['harga'] == 0
                            ? hargaDetail!
                            : currencyCode == null
                              ? "${vote['currency']} $hargaFormatted"
                              : "$currencyCode $hargaFormatted",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                              "$baseUrl/image/icon-vote/$theme_name/chart.svg",
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
                          formatter.format(item['total_voters'] ?? 0),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailFinalisPaketPage(
                            id_finalis: item['id_finalis'],
                            vote: counts, 
                            index: index, 
                            total_detail: totalHarga, 
                            id_paket_bw: id_paket,
                            remaining: remaining,
                            close_payment: vote['close_payment'],
                            tanggal_buka_payment: formattedDate,
                            flag_hide_no_urut: vote['flag_hide_nomor_urut'],
                            ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        detailfinalisText!,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
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
                            index,
                            paketTerbaik,
                            paketLainnya,
                            color,
                            bgColor,
                            id_paket,
                            currencyCode ?? vote['currency']
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
                              countData = selectedQty['count_data'];
                            });
                          }

                          slctedIdVote = item['id_vote'];
                          slctedIdFinalis = item['id_finalis'];
                          slctedNamaFinalis = item['nama_finalis'];
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
        );
      },
    );
  }

  Widget _timeBox(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _separator(Color color) {
    return Column(
      children: [
        Text(
          ":",
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20), // biar sejajar dengan label bawah
      ],
    );
  }
}



class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Color color;
  final ValueChanged<String> onSearchChanged;
  final String? searchHintText;

  _StickySearchBarDelegate({
    required this.color,
    required this.onSearchChanged,
    required this.searchHintText,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20,),
      child: SizedBox(
        height: 48,
        child: TextField(
          autofocus: false,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: searchHintText,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400,),
            ),
          ),
          onChanged: onSearchChanged,
        ),
      )
    );
  }

  @override
  double get maxExtent => 80;
  @override
  double get minExtent => 80;
  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) => false;
}