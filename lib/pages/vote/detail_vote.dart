// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_2_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_3_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_4_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_5_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_6_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote_lang.dart';
import 'package:kreen_app_flutter/pages/vote/finalis_page.dart';
import 'package:kreen_app_flutter/pages/vote/finalis_paket_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_1_widget.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class DetailVotePage extends StatefulWidget {
  final String id_event;
  const DetailVotePage({super.key, required this.id_event});

  @override
  State<DetailVotePage> createState() => _DetailVotePageState();
}

class _DetailVotePageState extends State<DetailVotePage> {
  final prefs = FlutterSecureStorage();
  String? langCode;
  String? flag_paket;
  
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  final descKey = GlobalKey();
  final leaderboardKey = GlobalKey();
  final dukunganKey = GlobalKey();
  final reviewKey = GlobalKey();

  // Simpan posisi tiap section
  final Map<int, double> _sectionOffsets = {};

  bool _isLoading = true;

  Map<String, dynamic>? detailVoteLang;
  String? detailVoteLangText;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOffsets();
      _scrollController.addListener(_onScroll);

      _loadVotes();
    });
  }

  Map<String, dynamic> vote = {};
  List<dynamic> ranking = [];
  List<dynamic> support = [];

  Future<void> _loadVotes() async {

    final resultVote = await ApiService.get("/vote/${widget.id_event}");
    final resultLeaderboard = await ApiService.get("/vote/${widget.id_event}/leaderboard");
    final resultSupport = await ApiService.get("/vote/${widget.id_event}/support");

    final Map<String, dynamic> tempVote = resultVote?['data'] ?? {};
    final tempRanking = resultLeaderboard?['data'] ?? [];

    await _precacheAllImages(context, tempVote, tempRanking);

    await _getBahasa();

    if (mounted) {
      setState(() {
        vote = tempVote;
        ranking = tempRanking;
        support = resultSupport?['data'] ?? [];
        _isLoading = false;

        flag_paket = vote['flag_paket'];
      });
    }
  }

  Future<void> _precacheAllImages(
    BuildContext context,
    Map<String, dynamic> votes,
    List<dynamic> ranking,
  ) async {
    List<String> allImageUrls = [];

    // Ambil semua file_upload dari ranking (juara / banner)
    for (var item in ranking) {
      final url = item['poster_finalis']?.toString();
      if (url != null && url.isNotEmpty) {
        allImageUrls.add(url);
      }
    }

    // Ambil semua img dari vote populer
    final voteData = votes['data'];
    if (voteData is List) {
      for (var item in voteData) {
        final url = item['img']?.toString();
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



  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempDetailVoteLang = await LangService.getJsonData(langCode!, "detail_vote");

    setState(() {
      detailVoteLang = tempDetailVoteLang;
      detailVoteLangText = tempDetailVoteLang['button_find_finalist'];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOffsets(); // recalculated setelah rebuild karena bahasa berubah
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateOffsets() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sectionOffsets[0] = _getOffset(descKey);
      _sectionOffsets[1] = _getOffset(leaderboardKey);
      _sectionOffsets[2] = _getOffset(dukunganKey);
      _sectionOffsets[3] = _getOffset(reviewKey);
    });
  }


  double _getOffset(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return 0;
    final box = ctx.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);

    // ambil posisi relatif ke ListView, bukan layar penuh
    final listViewPosition = (context.findRenderObject() as RenderBox)
        .localToGlobal(Offset.zero);

    return position.dy - listViewPosition.dy + _scrollController.offset;
  }



  void _onScroll() {
    if ((_sectionOffsets[2] ?? 0) == 0 || (_sectionOffsets[3] ?? 0) == 0) {
      _calculateOffsets(); // hitung ulang kalau masih 0
    }

    final offset = _scrollController.offset;

    // if (offset >= (_sectionOffsets[3] ?? double.infinity) - 100) {
    //   _setCurrentIndex(3);
    // } else if (offset >= (_sectionOffsets[2] ?? double.infinity) - 100) {
    //   _setCurrentIndex(2);
    // } else if (offset >= (_sectionOffsets[1] ?? double.infinity) - 100) {
    //   _setCurrentIndex(1);
    // } else {
    //   _setCurrentIndex(0);
    // }

    if (offset >= (_sectionOffsets[2] ?? double.infinity) - 100) {
      _setCurrentIndex(2);
    } else if (offset >= (_sectionOffsets[1] ?? double.infinity) - 100) {
      _setCurrentIndex(1);
    } else {
      _setCurrentIndex(0);
    }
  }


  void _setCurrentIndex(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _isLoading
          ? buildSkeletonHome()
          : buildKontenVote()
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
      ),
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

  Widget buildKontenVote() {
    // ambil dari respon api
    int view_api = 0;
    if (vote['leaderboard_tipe'] == 'number') {
      view_api = 2;
    } else if (vote['leaderboard_tipe'] == 'percent') {
      view_api = 3;
    } else if (vote['leaderboard_tipe'] == 'hidden') {
      view_api = 4;
    } else if (vote['leaderboard_tipe'] == 'bar-percent') {
      view_api = 5;
    } else if (vote['leaderboard_tipe'] == 'bar-number') {
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

    String themeName = 'Red';
    if (vote['theme_name'] != null) {
      themeName = vote['theme_name'];
    }
    
    Color color = colorMap[themeName] ?? Colors.red;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(vote['judul_vote']),
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
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: InkWell(
            onTap: () {
              if (flag_paket == '0') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinalisPage(id_vote: vote['id_vote']),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinalisPaketPage(id_vote: vote['id_vote']),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, color: Colors.white),
                  SizedBox(width: 8),
                  Text( 
                    detailVoteLangText!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          //tab bar
          // Container(
          //   color: Colors.white,
          //   child: Row(
          //     children: [
                // _buildTab("Deskripsi", 0, () => _scrollTo(descKey, 0), color),
                // _buildTab("Leaderboard", 1, () => _scrollTo(leaderboardKey, 1), color),

                // if (view_api != 1)
                //   _buildTab("Dukungan", 2, () => _scrollTo(dukunganKey, 2), color),

                // _buildTab("Kata Mereka", 3, () => _scrollTo(reviewKey, 3), color),
          //     ],
          //   ),  
          // ),
          // const Divider(height: 1),

          //konten
          DetailVoteLang(
            values: detailVoteLang!,
            child: Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // === DESKRIPSI ===
                  SizedBox(
                    key: descKey,
                    width: double.infinity,
                    child: _buildDeskripsiSection(view_api, vote, langCode!)
                  ),


                  // === LEADERBOARD ===
                  if (vote['leaderboard_limit_tampil'] != -1)
                    Container(
                      color: Colors.white,
                      key: leaderboardKey,
                      padding: kGlobalPadding,
                      child: _buildLeaderboardSection(view_api, ranking, vote, langCode!),
                    ),

                  // === INFO (hanya ada kalau view_api == 1) ===
                  if (view_api == 1)
                    Container(
                      key: dukunganKey,
                      padding: kGlobalPadding,
                      child: _buildInfoSection(view_api, vote, langCode!),
                    ),

                  // === REVIEW ===
                  Container(
                    color: Colors.white,
                    key: reviewKey,
                    padding: kGlobalPadding,
                    child: _buildDukunganSection(view_api, vote, support, langCode!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper builder untuk pilih Section berdasarkan view_api
Widget _buildDeskripsiSection(int api, Map<String, dynamic> vote, String langCode) {
  switch (api) {
    case 2:
      return DeskripsiSection_2(data: vote, langCode: langCode,);
    case 3:
      return DeskripsiSection_3(data: vote, langCode: langCode,);
    case 4:
      return DeskripsiSection_4(data: vote, langCode: langCode,);
    case 5:
      return DeskripsiSection_5(data: vote, langCode: langCode,);
    case 6:
      return DeskripsiSection_6(data: vote, langCode: langCode,);
    default:
      return DeskripsiSection(data: vote, langCode: langCode,);
  }
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

Widget _buildInfoSection(int api, Map<String, dynamic> vote, String langCode) {
  switch (api) {
    default:
      return InfoSection(data: vote, langCode: langCode,);
  }
}

Widget _buildDukunganSection(int api, Map<String, dynamic> vote, List<dynamic> reviews, String langCode) {
  switch (api) {
    case 2:
      return DukunganSection_2(data: vote, support: reviews, langCode: langCode,);
    case 3:
      return DukunganSection_3(data: vote, support: reviews, langCode: langCode,);
    case 4:
      return DukunganSection_4(data: vote, support: reviews, langCode: langCode,);
    case 5:
      return DukunganSection_5(data: vote, support: reviews, langCode: langCode,);
    case 6:
      return DukunganSection_6(data: vote, support: reviews, langCode: langCode,);
    default:
      return DukunganSection(data: vote, support: reviews, langCode: langCode,);
  }
}