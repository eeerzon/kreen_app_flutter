// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreen_app_flutter/helper/date_helper.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/global_widget.dart';
import 'package:kreen_app_flutter/helper/widget_webview.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_2_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_3_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_4_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_5_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/detail_vote_6_widget.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote/running_text.dart';
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
  final String? currencyCode;
  const DetailVotePage({super.key, required this.id_event, this.currencyCode});

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
  
  final Map<int, double> _sectionOffsets = {};

  bool _isLoading = true;

  Map<String, dynamic>? bahasa;
  String? detailVoteLangText;

  Map<String, dynamic> vote = {};
  List<dynamic> maplistOrderVote = [];
  List<dynamic> listOrderVote = [];
  List<dynamic> ranking = [];
  List<dynamic> support = [];
  bool showErrorBar = false;
  String errorMessage = ''; 
  String? currencyCode;

  Map<String, dynamic> articleData = {};
  bool _articlePopupShown = false;

  bool _isStickyRunningText = false;
  double _runningTextThreshold = -1;
  final GlobalKey _runningTextKey = GlobalKey();

  Duration remaining = Duration.zero;
  Timer? _timer;
  bool _boostPopupShown = false;
  Color color = Colors.red;
  int view_api = 0;

  bool _isRankingLoading = true;
  bool _isSupportLoading = true;

  int freeVote = 0;
  // bool _freeVotePopupShown = false;
  String? storedToken;

  bool isTutup = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOffsets();
      _scrollController.addListener(_onScroll);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _getBahasa();
        await _getCurrency();
        await _loadVotes();
        
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
        
        if (vote['multiplier'] != null && vote['multiplier'] > 1) {
          _startCountdown(DateHelper.parseWibToUtc(vote['multiplier_end_date']));
        }
        
        if (vote['multiplier'] != null && vote['multiplier'] > 1 && !_boostPopupShown) {
          _boostPopupShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showBoostPopup(context, langCode!, bahasa!, vote, flag_paket!, color, vote['multiplier'], vote['multiplier_end_date'], remaining, view_api, false);
          });
        }

        // if (vote['free_quota'] > 0 && !_freeVotePopupShown) {
        //   _freeVotePopupShown = true;
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     showFreeVotePopup(context, bahasa!, vote['free_quota']);
        //   });
        // }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _captureRunningTextThreshold();
          });
        });
      });
    });
  }

  Future<void> _loadVotes() async {
    storedToken = await StorageService.getToken();
    final results = await Future.wait([
      ApiService.get("/vote/${widget.id_event}", xLanguage: langCode, xCurrency: currencyCode, token: storedToken),
      ApiService.get("/order/vote?id_vote=${widget.id_event}&status=success&sort_by=terbaru&page_size=5", xLanguage: langCode, token: storedToken),
    ]);

    final resultVote = results[0];
    final resultListOrderVote = results[1];

    if (!mounted) return;
    if (resultVote == null || resultVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultVote?['message'] ?? '';
        _isLoading = false;
      });
      return;
    }

    articleData = (resultVote['data'] ?? {})['article_data'] ?? {};

    _articlePopupShown = await StorageService.getArticlePopupShown(widget.id_event);

    maplistOrderVote = resultListOrderVote?['data'] ?? [];

    final Map<String, dynamic> tempVote = resultVote['data'] ?? {};

    await _precacheVoteImages(context, tempVote);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        vote = tempVote;
        flag_paket = vote['flag_paket'];

        freeVote = vote['free_quota'] ?? 0;

        listOrderVote = maplistOrderVote.map<String>((item) {
          final String rawName = item['nama_finalis'] ?? '';
          final int qty = int.tryParse(item['qty'].toString()) ?? 0;

          final String name = rawName.length > 14
            ? '${rawName.substring(0, 11)}...'
            : rawName;

          return item['qty'] > 1
            ? "$name ${bahasa!["has_been"]} ($qty ${bahasa!["text_votes"]})"
            : "$name ${bahasa!["has_been"]} ($qty ${bahasa!["text_vote"]})";
        }).toList();

        _isLoading = false;
        showErrorBar = false;
      });
    }

    DateTime deadlineUtc = DateHelper.parseWibToUtc(vote['real_tanggal_tutup_vote']);
    Duration remaining = Duration.zero;
    final nowUtc = DateTime.now().toUtc();
    final difference = deadlineUtc.difference(nowUtc);

    remaining = difference.isNegative ? Duration.zero : difference;
    
    final bukaVoteUtc = DateHelper.parseWibToUtc(vote['real_tanggal_buka_vote']);
    bool isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

    if (remaining.inSeconds == 0 || isBeforeOpen) {
      isTutup = true;
    }

    _loadDukungan();
  }

  Future <void> _loadDukungan() async {
    storedToken = await StorageService.getToken();
    final results = await Future.wait([
      ApiService.get("/vote/${widget.id_event}/support", xLanguage: langCode, token: storedToken),
      ApiService.get("/vote/${widget.id_event}/leaderboard", xLanguage: langCode, token: storedToken),
    ]);
    
    final resultSupport = results[0];
    final resultLeaderboard = results[1];

    final tempRanking = resultLeaderboard?['data'] ?? [];

    await _precacheRankingImages(context, tempRanking);

    if (!mounted) return;
    if (mounted) {
      setState(() {
        support = resultSupport?['data'] ?? [];
        ranking = tempRanking;
        _isRankingLoading = false;
        _isSupportLoading = false;
      });
    }
  }

  Future<void> _precacheVoteImages(
    BuildContext context,
    Map<String, dynamic> votes,
  ) async {
    List<String> allImageUrls = [];
    
    final voteData = votes['data'];
    if (voteData is List) {
      for (var item in voteData) {
        final url = item['img']?.toString();
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

  Future<void> _precacheRankingImages(
    BuildContext context,
    List<dynamic> ranking,
  ) async {
    List<String> allImageUrls = [];
    
    for (var item in ranking) {
      final url = item['poster_finalis']?.toString();
      if (url != null && url.isNotEmpty) {
        allImageUrls.add(url);
      }
    }
    
    allImageUrls = allImageUrls.toSet().toList();
    
    for (String url in allImageUrls) {
      await precacheImage(NetworkImage(url), context);
    }
  }



  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
      detailVoteLangText = tempbahasa['button_find_finalist'];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOffsets();
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
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
    
    final listViewPosition = (context.findRenderObject() as RenderBox)
        .localToGlobal(Offset.zero);

    return position.dy - listViewPosition.dy + _scrollController.offset;
  }



  void _onScroll() {
    if ((_sectionOffsets[2] ?? 0) == 0 || (_sectionOffsets[3] ?? 0) == 0) {
      _calculateOffsets();
    }

    final offset = _scrollController.offset;

    if (offset >= (_sectionOffsets[2] ?? double.infinity) - 100) {
      _setCurrentIndex(2);
    } else if (offset >= (_sectionOffsets[1] ?? double.infinity) - 100) {
      _setCurrentIndex(1);
    } else {
      _setCurrentIndex(0);
    }
    
    if (_runningTextThreshold > 0) {
      final shouldStick = offset >= _runningTextThreshold;
      if (shouldStick != _isStickyRunningText) {
        setState(() => _isStickyRunningText = shouldStick);
      }
    } else {
      _captureRunningTextThreshold();
    }
  }

  void _setCurrentIndex(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _captureRunningTextThreshold() {
    final ctx = _runningTextKey.currentContext;
    if (ctx == null) return;

    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) return;

    final scrollRenderBox = scrollable.context.findRenderObject() as RenderBox?;
    if (scrollRenderBox == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPos = box.localToGlobal(Offset.zero, ancestor: scrollRenderBox);
    final threshold = localPos.dy + _scrollController.offset;

    if (threshold > 0 && threshold != _runningTextThreshold) {
      _runningTextThreshold = threshold;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
            ? buildSkeletonHome()
            : isTutup && vote['flag_tutup_view'] == '1' 
              ? VoteTutup()
              : buildKontenVote(),

          GlobalErrorBar(
            visible: showErrorBar,
            message: errorMessage,
            onRetry: () {
              _loadVotes();
            },
          ),
          
          if (!_isLoading && _isStickyRunningText) ...[
            Builder(builder: (context) {

              String themeName = vote['theme_name'] ?? 'Red';
              if (themeName == "Default Kreen") themeName = "Red";
              final color = colorMap[themeName] ?? Colors.red;

              return Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: _buildStickyRunningText(color, vote, langCode!, bahasa!),
              );
            }),
          ],
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

    String themeName = 'Red';
    if (vote['theme_name'] != null) {
      themeName = vote['theme_name'];
    }
    if (themeName == "Default Kreen") {
      themeName = "Red";
    }
    
    color = colorMap[themeName] ?? Colors.red;
  
    if (articleData.isNotEmpty && !_articlePopupShown) {
      _articlePopupShown = true;

      StorageService.setArticlePopupShown(widget.id_event, true);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showArticlePopup(articleData, color);
      });
    }

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
            Navigator.pop(context, currencyCode);
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
                    builder: (_) => FinalisPage(id_vote: vote['id_vote'], view_api: view_api,),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinalisPaketPage(id_vote: vote['id_vote'], view_api: view_api,),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
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
          
          DetailVoteLang(
            values: bahasa!,
            child: Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // === DESKRIPSI ===
                  SizedBox(
                    key: descKey,
                    width: double.infinity,
                    child: _buildDeskripsiSection(view_api, vote, listOrderVote, langCode!, currencyCode, _runningTextKey, storedToken),
                  ),

                  // === LEADERBOARD ===
                  if (vote['leaderboard_limit_tampil'] != -1)
                    Container(
                      color: Colors.white,
                      key: leaderboardKey,
                      padding: kGlobalPadding,
                      child: _buildLeaderboardSection(view_api, ranking, vote, langCode!, isLoading: _isRankingLoading,),
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
                    child: _buildDukunganSection(view_api, vote, support, langCode!, isLoading: _isSupportLoading,),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArticlePopup(Map<String, dynamic> article, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: color,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 10),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bahasa!['artikel_seputar_voting'] ?? 'Artikel Seputar Voting',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            if (article['img'] != null)
              Image.network(
                article['img'],
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SizedBox.shrink(),
              ),
              
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['article_title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['description'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            bahasa!['tutup'] ?? 'Tutup',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WidgetWebView(header: bahasa!['artikel'], url: articleData['link']),
                              ),
                            );
                          },
                          child: Text(
                            bahasa!['baca_sekarang'] ?? 'Baca Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCountdown(DateTime deadlineUtc) {
    _updateRemaining(deadlineUtc);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining(deadlineUtc);
    });
  }

  void _updateRemaining(DateTime deadlineUtc) {
    final nowUtc = DateTime.now().toUtc();
    final difference = deadlineUtc.difference(nowUtc);

    if (difference.isNegative) {
      _timer?.cancel();
    }
    
    setState(() {
      remaining = difference.isNegative ? Duration.zero : difference;
    });
  }
}

Widget _buildDeskripsiSection(
  int api, 
  Map<String, dynamic> vote, 
  List<dynamic> listOrderVote, 
  String langCode, 
  String? currencyCode, 
  GlobalKey? runningTextKey,
  String? token
) {
  switch (api) {
    case 2:
      return DeskripsiSection_2(
        data: vote, 
        dataNotif: listOrderVote, 
        langCode: langCode, 
        currencyCode: currencyCode,
        runningTextKey: runningTextKey,
        token: token,
      );
    case 3:
      return DeskripsiSection_3(
        data: vote, 
        dataNotif: listOrderVote, 
        langCode: langCode, 
        currencyCode: currencyCode,
        runningTextKey: runningTextKey,
        token: token,
      );
    case 4:
      return DeskripsiSection_4(
        data: vote, 
        dataNotif: listOrderVote, 
        langCode: langCode, 
        currencyCode: currencyCode,
        runningTextKey: runningTextKey,
        token: token,
      );
    case 5:
      return DeskripsiSection_5(
        data: vote, 
        dataNotif: listOrderVote, 
        langCode: langCode, 
        currencyCode: currencyCode,
        runningTextKey: runningTextKey,
        token: token,
      );
    case 6:
      return DeskripsiSection_6(
        data: vote, 
        dataNotif: listOrderVote, 
        langCode: langCode, 
        currencyCode: currencyCode,
        runningTextKey: runningTextKey,
        token: token,
      );
    default:
      return DeskripsiSection(
        data: vote, 
        dataNotif: listOrderVote, 
        langCode: langCode, 
        currencyCode: currencyCode,
        runningTextKey: runningTextKey,
        token: token,
      );
  }
}

Widget _buildLeaderboardSection(int api, List<dynamic> ranking, Map<String, dynamic> vote, String langCode, {bool isLoading = false,}) {
  switch (api) {
    case 2:
      return LeaderboardSection_2(ranking: ranking, data: vote, langCode: langCode, isLoading: isLoading,);
    case 3:
      return LeaderboardSection_3(ranking: ranking, data: vote, langCode: langCode, isLoading: isLoading,);
    case 4:
      return LeaderboardSection_4(ranking: ranking, data: vote, langCode: langCode, isLoading: isLoading,);
    case 5:
      return LeaderboardSection_5(ranking: ranking, data: vote, langCode: langCode, isLoading: isLoading,);
    case 6:
      return LeaderboardSection_6(ranking: ranking, data: vote, langCode: langCode, isLoading: isLoading,);
    default:
      return LeaderboardSection(ranking: ranking, data: vote, langCode: langCode, isLoading: isLoading,);
  }
}

Widget _buildInfoSection(int api, Map<String, dynamic> vote, String langCode) {
  switch (api) {
    default:
      return InfoSection(data: vote, langCode: langCode,);
  }
}

Widget _buildDukunganSection(int api, Map<String, dynamic> vote, List<dynamic> reviews, String langCode, {bool isLoading = false,}) {
  switch (api) {
    case 2:
      return DukunganSection_2(data: vote, support: reviews, langCode: langCode, isLoading: isLoading,);
    case 3:
      return DukunganSection_3(data: vote, support: reviews, langCode: langCode, isLoading: isLoading,);
    case 4:
      return DukunganSection_4(data: vote, support: reviews, langCode: langCode, isLoading: isLoading,);
    case 5:
      return DukunganSection_5(data: vote, support: reviews, langCode: langCode, isLoading: isLoading,);
    case 6:
      return DukunganSection_6(data: vote, support: reviews, langCode: langCode, isLoading: isLoading,);
    default:
      return DukunganSection(data: vote, support: reviews, langCode: langCode, isLoading: isLoading,);
  }
}

Widget _buildStickyRunningText(Color color, Map<String, dynamic> vote, String langCode, Map<String, dynamic> bahasa) {
  Color textColor = color;
  final rawColor = (vote['running_text_color'] ?? '').toString().trim();
  if (rawColor.isNotEmpty) {
    try {
      final hex = rawColor.replaceAll('#', '');
      textColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
  }

  final rawText = (vote['running_text'] ?? '').toString().trim();
  final displayText = rawText.isNotEmpty
      ? rawText
      : 'Kreen Vote - Your Trusted Voting Partner - ${bahasa['running_text_def']} ${vote['judul_vote'] ?? ''}';

  return Container(
    padding: const EdgeInsets.all(8),
    color: textColor,
    child: RunningText(text: displayText, textColor: Colors.white),
  );
}