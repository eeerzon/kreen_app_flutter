// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_manual.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class FinalisPage extends StatefulWidget {
  final String id_vote;
  const FinalisPage({super.key, required this.id_vote});

  @override
  State<FinalisPage> createState() => _FinalisPageState();
}

class _FinalisPageState extends State<FinalisPage> {
  String langCode = 'id';
  DateTime deadline = DateTime(2025, 09, 26, 13, 30, 00, 00, 00);

  Duration remaining = Duration.zero;
  Timer? _timer;

  bool _isLoading = true;
  List<int> counts = [];
  List<String> ids_finalis = [];
  List<String> names_finalis = [];
  List<int> counts_finalis = [];
  int totalCount = 0;
  List<int?> selectedVotes = [];
  List<int?> selectedIndexes = [];

  List<TextEditingController> controllers = [];


  String? slctedIdVote, slctedIdFinalis, slctedNamaFinalis;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
      _loadVotes();
    });
  }

  Map<String, dynamic> vote = {};
  List<dynamic> finalis = [];
  Future<void> _loadVotes() async {

    final resultVote = await ApiService.get("/vote/${widget.id_vote}");
    final resultFinalis = await ApiService.get("/vote/${widget.id_vote}/finalis");

    final tempVote = resultVote?['data'] ?? {};
    final tempFinalis = resultFinalis?['data'] ?? [];

    await _precacheAllImages(context, tempFinalis);

    if (mounted) {
      setState(() {
        vote = tempVote;
        finalis = tempFinalis;
        _isLoading = false;

        deadline = DateTime.parse(vote['real_tanggal_tutup_vote']);
        counts = List<int>.filled(finalis.length, 0);
        selectedVotes = List.filled(finalis.length, null);
        selectedIndexes = List.filled(finalis.length, null);

        controllers = List.generate(vote.length, (i) {
          return TextEditingController(text: "0");
        });
      });
    }
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
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        debugPrint("Gagal pre-cache $url: $e");
      }
    }
  }
  
  final formatter = NumberFormat.decimalPattern("id_ID");
  int get totalHarga {
    int total = 0;
    for (int i = 0; i < counts.length; i++) {
      final hargaItem = int.tryParse(vote['harga'].toString()) ?? 0;
      total += counts[i] * hargaItem;
    }
    return total;
  }

  void _updateCountFromInput(int index, String value) {
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      counts[index] = parsed;
    });
  }

  void _startCountdown() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final difference = deadline.difference(now);

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
    try {
      final result = await ApiService.get('/vote/${widget.id_vote}/finalis?search=$keyword');
      if (mounted) {
        setState(() {
          finalis = result?['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Gagal search finalis: $e');
    }
  }

  void _resetFinalis() {
    _loadVotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? buildSkeletonHome()
          : buildKontenFinalis()
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

    // if (_isLoading) {
    //   return Scaffold(
    //     body: Center(
    //       child: CircularProgressIndicator(color: Colors.red),
    //     ),
    //   );
    // }

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
        title: Text("Temukan Finalis"),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                    vote['harga'] == 0
                    ? 'Gratis'
                    : "${vote['currency']} ${formatter.format(totalHarga)}",
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
                onPressed: (vote['harga'] != 0 && totalHarga == 0) || totalCount == 0 
                  ? null 
                  : () async {
                    final getUser = await StorageService.getUser();

                    String? idUser = getUser['id'];

                    if (vote['flag_login'] == '1') {
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
                            builder: (_) => StatePaymentManual(
                              id_vote: slctedIdVote!,
                              ids_finalis: ids_finalis,
                              names_finalis: names_finalis,
                              counts_finalis: counts_finalis,
                              totalHarga: totalHarga,
                              price: vote['harga'],
                              fromDetail: false,
                              idUser: idUser,
                            ),
                          ),
                        );
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatePaymentManual(
                            id_vote: slctedIdVote!,
                            ids_finalis: ids_finalis,
                            names_finalis: names_finalis,
                            counts_finalis: counts_finalis,
                            totalHarga: totalHarga,
                            price: vote['harga'],
                            fromDetail: false,
                            idUser: idUser,
                          ),
                        ),
                      );
                    }
                },
                child: Text(
                  remaining.inSeconds == 0
                  ? "Vote telah berakhir"
                  : "Lanjut Pembayaran",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),


      body: CustomScrollView(
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
                      const Text("Hitung Mundur hingga Vote ditutup"),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _timeBox("$days", "Hari", color),
                          const SizedBox(width: 20),
                          _timeBox("$hours".padLeft(2, "0"), "Jam", color),
                          const SizedBox(width: 10),
                          _separator(color),
                          const SizedBox(width: 10),
                          _timeBox("$minutes".padLeft(2, "0"), "Menit", color),
                          const SizedBox(width: 10),
                          _separator(color),
                          const SizedBox(width: 10),
                          _timeBox("$seconds".padLeft(2, "0"), "Detik", color),
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
            ),
          ),

          // grid view
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: buildGridView(vote, finalis, color, bgColor, themeName),
            ),
          ),
        ],
      ),
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

  Widget buildGridView(Map<String, dynamic> vote, List<dynamic> listFinalis, Color color, Color bgColor, String theme_name) {

    final formatter = NumberFormat.decimalPattern("id_ID");
    final hargaFormatted = formatter.format(vote['harga'] ?? 0);

    final voteOptions = [10, 50, 100, 250, 500, 1000];

    final dateStr = vote['tanggal_buka_payment']?.toString() ?? '-';
    String formattedDate = '-';

    if (dateStr.isNotEmpty) {
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
          if (day % 10 == 1 && day != 11) { suffix = 'st'; }
          else if (day % 10 == 2 && day != 12) { suffix = 'nd'; }
          else if (day % 10 == 3 && day != 13) { suffix = 'rd'; }
          formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
        }
      } catch (e) {
        formattedDate = '-';
      }
    }

    DateTime bukaVote = DateTime.parse(vote['real_tanggal_buka_vote']);
    bool isBeforeOpen = DateTime.now().isBefore(bukaVote);

    String formattedBukaVote = DateFormat("dd MMM yyyy HH:mm").format(bukaVote);

    String buttonText = '';
    
    if (isBeforeOpen) {
      buttonText = 'Vote akan dibuka pada $formattedBukaVote';
    } else if (vote['close_payment'] == '1') {
      buttonText = 'Vote akan dibuka Kembali pada $formattedDate';
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
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: ishas ?
                      FadeInImage.assetNetwork(
                        placeholder: 'assets/images/img_placeholder.jpg',
                        image: item['poster_finalis'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
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
                          fadeInDuration: const Duration(milliseconds: 300),
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/img_broken.jpg',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    item['nama_finalis'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),
                  (item['nama_tambahan'] == null || item['nama_tambahan'].toString().trim().isEmpty)
                    ? Text(
                        "Tidak ada data",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(item['nama_tambahan'],
                      style: const TextStyle(color: Colors.grey),
                    ),

                  const SizedBox(height: 10),
                  Text(item['nomor_urut'].toString()),

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
                              Text("Harga"),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            vote['harga'] == 0
                              ? 'Gratis'
                              : "${vote['currency']} $hargaFormatted",
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
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailFinalisPage(
                              id_finalis: item['id_finalis'], 
                              count: counts[index], 
                              indexWrap: selectedIndexes[index],
                              close_payment: vote['close_payment'],
                              tanggal_buka_payment: formattedDate,
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
                        "Detail Finalis",
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  if (vote['close_payment'] == '1' || isBeforeOpen) ... [
                    SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                      decoration: BoxDecoration(
                        color: (vote['close_payment'] == '1' || isBeforeOpen)
                          ? Colors.grey
                          : color,
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
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // button minus
                        InkWell(
                          onTap: (remaining.inSeconds == 0)
                              ? null
                              : () {
                                  if (counts[index] > 0) {
                                    setState(() {
                                      counts[index]--;
                                      controllers[index].text = counts[index].toString();

                                      totalCount = counts.reduce((a, b) => a + b);

                                      final idFinalis = item['id_finalis'];
                                      final namaFinalis = item['nama_finalis'];

                                      final existingIndex = ids_finalis.indexOf(idFinalis);

                                      if (counts[index] == 0) {
                                        selectedVotes[index] = null;
                                        if (existingIndex != -1) {
                                          ids_finalis.removeAt(existingIndex);
                                          names_finalis.removeAt(existingIndex);
                                          counts_finalis.removeAt(existingIndex);
                                        }
                                      } else {
                                        if (existingIndex != -1) {
                                          counts_finalis[existingIndex] = counts[index];
                                          names_finalis[existingIndex] = namaFinalis;
                                        }
                                      }

                                      slctedIdVote = item['id_vote'];
                                    });
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (remaining.inSeconds == 0)
                                  ? Colors.grey
                                  : color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              FontAwesomeIcons.minus,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // text field
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
                            controller: controllers[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            enabled: remaining.inSeconds != 0,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.all(8),
                            ),
                            onChanged: (value) => _updateCountFromInput(index, value),
                            onTap: () {
                              controllers[index].selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: controllers[index].text.length,
                              );
                            },
                          ),
                        ),

                        // button plus
                        const SizedBox(width: 15),
                        InkWell(
                          onTap: (remaining.inSeconds == 0)
                              ? null
                              : () {
                                  setState(() {
                                    counts[index]++;
                                    controllers[index].text = counts[index].toString();

                                    totalCount = counts.reduce((a, b) => a + b);

                                    final idFinalis = item['id_finalis'];
                                    final namaFinalis = item['nama_finalis'];

                                    final existingIndex = ids_finalis.indexOf(idFinalis);

                                    if (counts[index] > 0) {
                                      if (existingIndex == -1) {
                                        ids_finalis.add(idFinalis);
                                        names_finalis.add(namaFinalis);
                                        counts_finalis.add(counts[index]);
                                      } else {
                                        counts_finalis[existingIndex] = counts[index];
                                        names_finalis[existingIndex] = namaFinalis;
                                      }
                                    }

                                    if (counts[index] == 0 && existingIndex != -1) {
                                      ids_finalis.removeAt(existingIndex);
                                      names_finalis.removeAt(existingIndex);
                                      counts_finalis.removeAt(existingIndex);
                                    }

                                    slctedIdVote = item['id_vote'];
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (remaining.inSeconds == 0)
                                  ? Colors.grey
                                  : color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              FontAwesomeIcons.plus,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 15,),
                  if (counts[index] > 0)
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: voteOptions.asMap().entries.map((entry) {
                        final optionIndex = entry.key;
                        final voteCount = entry.value;

                        final isSelected = selectedVotes[index] == voteCount && counts[index] > 0;

                        return IgnorePointer(
                          ignoring: counts[index] == 0,
                          child: Opacity(
                            opacity: counts[index] == 0 ? 0.4 : 1,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedVotes[index] = voteCount;
                                  selectedIndexes[index] = optionIndex;
                                  counts[index] = voteCount;
                                  controllers[index].text = counts[index].toString();

                                  totalCount = counts.reduce((a, b) => a + b);

                                  final idFinalis = item['id_finalis'];
                                  final namaFinalis = item['nama_finalis'];
                                  final existingIndex = ids_finalis.indexOf(idFinalis);

                                  if (counts[index] > 0) {
                                    if (existingIndex == -1) {
                                      ids_finalis.add(idFinalis);
                                      names_finalis.add(namaFinalis);
                                      counts_finalis.add(counts[index]);
                                    } else {
                                      counts_finalis[existingIndex] = counts[index];
                                      names_finalis[existingIndex] = namaFinalis;
                                    }
                                  } else if (counts[index] == 0 && existingIndex != -1) {
                                    ids_finalis.removeAt(existingIndex);
                                    names_finalis.removeAt(existingIndex);
                                    counts_finalis.removeAt(existingIndex);
                                  }

                                  slctedIdVote = item['id_vote'];
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
                                    Text(
                                      "vote",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white : Colors.black,
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
                ],
              ),
            ),
          ),
        );
      },
    );

    
    // return GridView.builder(
    //   physics: const NeverScrollableScrollPhysics(),
    //   shrinkWrap: true,
    //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: 1,
    //     mainAxisSpacing: 10,
    //     mainAxisExtent: 670
    //   ),
    //   itemCount: listFinalis.length,
    //   itemBuilder: (context, index) {
    //     final item = listFinalis[index];
    //     return Card(
    //       color: Colors.white,
    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //       child: Padding(
    //         padding: kGlobalPadding,
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             ClipRRect(
    //               borderRadius: const BorderRadius.all(Radius.circular(20)),
    //               child: Image.network(
    //                 item['poster_finalis'],
    //                 width: double.maxFinite,
    //               ),
    //             ),

    //             const SizedBox(height: 10,),
    //             Text(
    //               item['nama_finalis'],
    //               style: TextStyle(fontWeight: FontWeight.bold),
    //             ),

    //             const SizedBox(height: 10,),
    //             Text(
    //               item['nama_tambahan'],
    //               style: TextStyle(color: Colors.grey),
    //             ),

    //             const SizedBox(height: 10,),
    //             Text(
    //               item['nomor_urut'].toString(),
    //             ),

    //             const SizedBox(height: 15,),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 Column(
    //                   mainAxisAlignment: MainAxisAlignment.end,
    //                   crossAxisAlignment: CrossAxisAlignment.end,
    //                   children: [
    //                     Row(
    //                       mainAxisAlignment: MainAxisAlignment.end,
    //                       crossAxisAlignment: CrossAxisAlignment.end,
    //                       children: [
    //                         Icon(FontAwesomeIcons.dollarSign, size: 15, color: color,),
    //                         Text(
    //                           "Harga",
    //                         )
    //                       ],
    //                     ),

    //                     SizedBox(height: 10,),
    //                     Text(
    //                       "Rp. $hargaFormatted",
    //                       style: TextStyle(fontWeight: FontWeight.bold),
    //                     )
    //                   ],
    //                 ),

    //                 const SizedBox(width: 30,),
    //                 Column(
    //                   mainAxisAlignment: MainAxisAlignment.start,
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     Row(
    //                       mainAxisAlignment: MainAxisAlignment.start,
    //                       children: [
    //                         Icon(Icons.stacked_bar_chart, size: 15, color: color,),
    //                         Text(
    //                           "vote",
    //                         )
    //                       ],
    //                     ),

    //                     const SizedBox(height: 10,),
    //                     Text(
    //                       item['total_voters'].toString(),
    //                       style: TextStyle(fontWeight: FontWeight.bold),
    //                     )
    //                   ],
    //                 )
    //               ],
    //             ),

    //             const SizedBox(height: 15,),
    //             Container(
    //               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 60),
    //               decoration: BoxDecoration(
    //                 color: bgColor,
    //                 borderRadius: BorderRadius.circular(8),
    //               ),
    //               child: InkWell(
    //                 onTap: () {
    //                   showModalBottomSheet(
    //                     context: context,
    //                     isScrollControlled: true, // biar tinggi penuh
    //                     backgroundColor: Colors.transparent,
    //                     builder: (BuildContext context) {
    //                       return FractionallySizedBox(
    //                         heightFactor: 0.9, // popup tinggi 90% layar
    //                         child: Container(
    //                           decoration: const BoxDecoration(
    //                             color: Colors.white,
    //                             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    //                           ),
    //                           child: DetailFinalisPage(id_finalis: item['id_finalis']),
    //                         ),
    //                       );
    //                     },
    //                   );
    //                 },
    //                 child: Text(
    //                     "Detail Finalis",
    //                     style: TextStyle(color: color, fontWeight: FontWeight.bold),
    //                   ),
    //               )
    //             ),

    //             const SizedBox(height: 15,),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 Container(
    //                   padding: EdgeInsets.all(10),
    //                   decoration: BoxDecoration(
    //                     color: color,
    //                     borderRadius: BorderRadius.circular(8),
    //                   ),
    //                   child: InkWell(
    //                     onTap: () {
    //                       if (counts[index] > 0) {
    //                         setState(() {
    //                           counts[index]--;
    //                         });
    //                       }
    //                     },
    //                     child: Icon(
    //                       FontAwesomeIcons.minus,size: 15, color: Colors.white,
    //                     )
    //                   )
    //                 ),

    //                 const SizedBox(width: 15,),
    //                 Container(
    //                   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
    //                   decoration: BoxDecoration(
    //                     color: Colors.grey[200],
    //                     borderRadius: BorderRadius.circular(8),
    //                   ),
    //                   child: Text(
    //                     "${counts[index]}",
    //                     style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    //                   ),
    //                 ),

    //                 const SizedBox(width: 15,),
    //                 Container(
    //                   padding: EdgeInsets.all(10),
    //                   decoration: BoxDecoration(
    //                     color: color,
    //                     borderRadius: BorderRadius.circular(8),
    //                   ),
    //                   child: InkWell(
    //                     onTap: () {
    //                       setState(() {
    //                         counts[index]++;
    //                       });
    //                     },
    //                     child: Icon(
    //                       FontAwesomeIcons.plus,size: 15, color: Colors.white,
    //                     )
    //                   )
    //                 ),

    //                 if (counts[index] > 0)
    //                   Row(
    //                     children: [
    //                       InkWell(
    //                       )
    //                     ],
    //                   )
    //               ],
    //             )
    //           ],
    //         ),
    //       )
    //     );
    //   },
    // );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Color color;
  final ValueChanged<String> onSearchChanged;

  _StickySearchBarDelegate({
    required this.color,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20,),
      child: TextField(
        autofocus: false,
        decoration: InputDecoration(
          hintText: "Cari Finalis...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }

  @override
  double get maxExtent => 80;
  @override
  double get minExtent => 80;
  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) => false;
}
