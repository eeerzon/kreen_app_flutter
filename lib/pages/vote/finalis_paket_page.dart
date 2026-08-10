// ignore_for_file: non_constant_identifier_names, prefer_typing_uninitialized_variables, use_build_context_synchronously, deprecated_member_use, unused_local_variable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/date_helper.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/global_widget.dart';
import 'package:kreen_app_flutter/modal/email_verif_modal.dart';
import 'package:kreen_app_flutter/modal/paket_vote_modal.dart';
import 'package:kreen_app_flutter/modal/payment/state_payment_paket.dart';
import 'package:kreen_app_flutter/pages/vote/detail_finalis_paket.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class FinalisPaketPage extends StatefulWidget {
  final String id_vote;
  final int view_api;
  const FinalisPaketPage({super.key, required this.id_vote, required this.view_api});

  @override
  State<FinalisPaketPage> createState() => _FinalisPaketPageState();
}

class _FinalisPaketPageState extends State<FinalisPaketPage> {
  String? langCode;
  var get_user;
  DateTime deadline = DateTime(2025, 09, 26, 13, 30, 00, 00, 00);
  DateTime deadlineUtc = DateTime.now().toUtc();

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
  String? endVote, voteOpen, voteOpenAgain, voteBelumOpen;
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
  bool isBeforeOpen = false;
  bool _isSearching = false;
  bool persen = false;
  String? currencyCode;

  bool isButtonClicked = false;
        
  String formattedDate = '-';

  final Map<String, String?> _idPaketPerFinalis = {};
  final Map<String, int> _countsPerFinalis = {};
  final Map<String, num> _hargaPerFinalis = {};
  final Map<String, num> _hargaAsliPerFinalis = {};
  final Map<String, int> _countDataPerFinalis = {};

  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool isFirstLoad = true;
  ScrollController _scrollController = ScrollController();

  Future<void> checkPaymentStatus(String? close_payment, String? tanggal_buka_payment) async {
    if (close_payment != '1') {
      isPaymentClosed = false;
      return;
    }

    try {
      final reopenUtc = DateHelper.parseWibToUtc(tanggal_buka_payment!);
      final nowUtc = DateTime.now().toUtc();

      final closed = nowUtc.isBefore(reopenUtc);

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

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadToken();
      await _loadVotes();
      _startCountdown();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        await checkPaymentStatus(vote['close_payment'], vote['tanggal_buka_payment']);
      });
    });
  }

  // ignore: unused_field
  String? _storedToken;
  Future<void> _loadToken() async {
    final token = await StorageService.getToken() ?? '';
    if (mounted) setState(() => _storedToken = token);
  }
  
  Future<void> _onAfterLogin() async {
    await _loadToken();
  }

  Future<void> _loadVotes() async {

    if (widget.view_api == 3 || widget.view_api == 5) {
      persen = true;
    }
    
    final resultVote = await ApiService.get("/vote/${widget.id_vote}", xLanguage: langCode, xCurrency: currencyCode, token: _storedToken);
    if (resultVote == null || resultVote['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultVote?['message'];
      });
      return;
    }

    final resultFinalis = await ApiService.get(
      "/vote/${widget.id_vote}/finalis?"
      "page_size=6"
      "&current_page=1", 
      xLanguage: langCode);
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

        deadlineUtc = DateHelper.parseWibToUtc(vote['real_tanggal_tutup_vote'],);
      
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

        currentPage = 1;
        hasMore = tempFinalis.length >= 6;
        isFirstLoad = false;
        
        _isLoading = false;
        showErrorBar = false;
      });
    }
  }
  
  String get buttonText {
    if (remaining.inSeconds == 0) return endVote ?? '';

    final dateStr = vote['real_tanggal_buka_payment']?.toString() ?? '-';

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
    
    final bukaVoteUtc = DateHelper.parseWibToUtc(vote['real_tanggal_buka_vote']);
    final bukaVote = DateHelper.parseWibToLocal(vote['real_tanggal_buka_vote']);

    final nowUtc = DateTime.now().toUtc();

    isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);

    String formattedBukaVote = DateFormat("$formatDateId HH:mm").format(bukaVote);
    
    if (isBeforeOpen) {
      // return '$voteOpen $formattedBukaVote';
      return '$voteBelumOpen';
    }
    if (vote['close_payment'] == '1') {
      return '$voteOpenAgain $formattedDate';
    }
    if (vote['harga'] != 0) {
      return buttonPilihPaketText ?? '';
    }
    return bahasa['lanjutkan'] ?? '';
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
      voteBelumOpen = tempbahasa['vote_belum_open'];
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

    for (var item in finalis) {
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
    if (vote.isEmpty) return;

    final nowUtc = DateTime.now().toUtc();
    final difference = deadlineUtc.difference(nowUtc);

    final bukaVoteUtc = DateHelper.parseWibToUtc(vote['real_tanggal_buka_vote']);

    if (difference.isNegative) {
      _timer?.cancel();
    }
    
    setState(() {
      remaining = difference.isNegative ? Duration.zero : difference;
      isBeforeOpen = nowUtc.isBefore(bukaVoteUtc);
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

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      if (value.isNotEmpty) {
        setState(() => _isSearching = true);
        await _searchFinalis(value);
        if (!mounted) return;
        setState(() => _isSearching = false);
      } else if (value.isEmpty) {
        setState(() => _isSearching = true);
        _resetFinalis();
        if (!mounted) return;
        setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _searchFinalis(String keyword) async {
    final result = await ApiService.get('/vote/${widget.id_vote}/finalis?search=$keyword', xLanguage: langCode);

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

  Future<void> _loadMoreKonten() async {
    currentPage++;
    await _fetchKonten(loadMore: true);
  }

  Future<void> _fetchKonten({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore || !hasMore) return;
      setState(() => isLoadingMore = true);
    } else {
      if (!mounted) return;
      setState(() => isFirstLoad = true);
      hasMore = true;
    }

    isFirstLoad = false;

    final resultFinalis = await ApiService.get(
      "/vote/${widget.id_vote}/finalis?"
      "page_size=6"
      "&current_page=$currentPage", 
      xLanguage: langCode,
      xCurrency: currencyCode,
      token: _storedToken);
    

    List newData = [];
    bool fetchFailed = false;
    if (resultFinalis?['rc'] == 200) {
      newData = List.from(resultFinalis?['data'] ?? []);
      hasMore = newData.length >= 6;
      fetchFailed = false;
    } else if (resultFinalis?['rc'] == 404) {
      // anggap ini "data habis", bukan error
      hasMore = false;
      fetchFailed = false;
    } else {
      hasMore = false;
      fetchFailed = true;
    }

    if (!mounted) return;
    setState(() {
      if (loadMore) {
        finalis.addAll(newData);
        isLoadingMore = false;
      } else {
        finalis = newData;
        isFirstLoad = false;
      }

      showErrorBar = fetchFailed;
    });
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

    String themeName = 'default';
    if (vote['theme_name'] != null) {
      themeName = vote['theme_name'];
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

    final isFreeVotePaket = id_paket == 'free_vote';
    final belumPilihPaket = id_paket.isEmpty || counts == 0;
    final paketBerbayarTapiHargaNol = !isFreeVotePaket && totalHarga == 0;

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
              
              remaining.inSeconds == 0 || isBeforeOpen || vote['close_payment'] == '1'
              ? SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      "${bahasa['paket']} $counts ${counts > 1 ? bahasa['text_votes'] : bahasa['text_vote']} ${vote['multiplier'] > 1 ? 'x${vote['multiplier']}' : ''} \n$countData ${bahasa['finalis']}${countData > 1 ? 's' : ''}",
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
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                onPressed: (belumPilihPaket ||
                        paketBerbayarTapiHargaNol ||
                        vote['close_payment'] == '1' ||
                        remaining.inSeconds == 0)
                    ? null
                    : () async {
                      if (isButtonClicked) return;

                      isButtonClicked = true;

                      try {
                        
                        var getUser = await StorageService.getUser();

                        String? idUser = getUser['id'];

                        await refreshAfterVerification(_storedToken!, getUser['email'] ?? '', langCode!);

                        getUser = await StorageService.getUser();

                        if (vote['flag_login'] == '1' && _storedToken!.isEmpty) {
                          await EmailVerifModal.showLogin(context, bahasa, color, onLoginSuccess: _onAfterLogin);
                          return;
                        }

                        if (vote['flag_login'] == '0' && vote['flag_verify_email'] == '1' && _storedToken!.isEmpty) {
                          await EmailVerifModal.showLogin(context, bahasa, color, onLoginSuccess: _onAfterLogin);
                          return;
                        }

                        if (vote['flag_verify_email'] == '1' && getUser['verifEmail'] == '0') {
                          await EmailVerifModal.show(context, _storedToken!, langCode!, bahasa, getUser['email'] ?? '', color);
                          return;
                        }

                        if (mounted) {
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
                                color: color,
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
                        : vote['close_payment'] == '1'
                            ? bahasa['tutup_sementara']
                            : vote['harga'] != 0
                                ? bayarText!
                                : bahasa['lanjutkan'],
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
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!isLoadingMore &&
                hasMore &&
                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              _loadMoreKonten();
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [

              if (
                vote['flag_cd'] == '1' &&
                vote['real_tanggal_tutup_vote'] != null &&
                DateHelper.parseWibToUtc(
                  vote['real_tanggal_tutup_vote'].toString(),
                ).isAfter(DateTime.now().toUtc())
              ) ...[
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
              ],
              
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchBarDelegate(
                  color: color,
                  onSearchChanged: _onSearchChanged,
                  searchHintText: cariFinalisText!,
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: _isSearching
                    ? buildSkeletonGrid()
                    : buildGridView(
                        vote, 
                        finalis, 
                        color, 
                        bgColor, 
                        themeName, 
                        noDataText
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSkeletonGrid() {
    return Column(
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
    );
  }

  Widget buildGridView(Map<String, dynamic> vote, List<dynamic> listFinalis, Color color, Color bgColor, String theme_name, String? noDataText) {
    
    final formatter = NumberFormat.decimalPattern("en_US");
    final hargaFormatted = formatter.format(vote['harga'] ?? 0);

    if (listFinalis.isEmpty) {
      return Column(
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Image.asset(
              'assets/images/placeholder.png',
              width: 200,
              height: 200,
            ),
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

    return Column(
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300,),
                ),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const namaFinalisStyle = TextStyle(fontWeight: FontWeight.bold);

                        final textPainter = TextPainter(
                          text: TextSpan(text: item['nama_finalis'], style: namaFinalisStyle),
                          textDirection: Directionality.of(context),
                        )..layout(maxWidth: constraints.maxWidth);

                        final isMultiline = textPainter.computeLineMetrics().length > 1;

                        return Text(
                          item['nama_finalis'],
                          textAlign: isMultiline ? TextAlign.center : TextAlign.start,
                          style: namaFinalisStyle,
                        );
                      },
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
                        
                        if (vote['leaderboard_tipe'] != 'hidden') ...[
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
                                  Text(
                                    (persen
                                      ? item['percent'] > 1
                                      : item['total_voters'] > 1)
                                        ? bahasa['text_votes']
                                        : bahasa['text_vote'],
                                  ),
                                ],
                              ),
            
                              const SizedBox(height: 10,),
                              Text(
                                persen
                                  ? "${item['percent'] ?? 0}%"
                                  : formatter.format(item['total_voters'] ?? 0),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 15),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final idFinalis = item['id_finalis'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailFinalisPaketPage(
                                id_finalis: idFinalis,
                                vote: _countsPerFinalis[idFinalis] ?? 0,
                                index: index, 
                                total_detail: _hargaPerFinalis[idFinalis] ?? 0,
                                id_paket_bw: _idPaketPerFinalis[idFinalis],
                                remaining: remaining,
                                close_payment: vote['close_payment'],
                                tanggal_buka_payment: formattedDate,
                                flag_hide_no_urut: vote['flag_hide_nomor_urut'],
                                persen: persen,
                                onPaketSelected: (newIdPaket, newCounts, newHarga, newHargaAsli, newCountData) {
                                  setState(() {
                                    _idPaketPerFinalis[idFinalis] = newIdPaket;
                                    _countsPerFinalis[idFinalis] = newCounts;
                                    _hargaPerFinalis[idFinalis] = newHarga;
                                    _hargaAsliPerFinalis[idFinalis] = newHargaAsli;
                                    _countDataPerFinalis[idFinalis] = newCountData;
                                    
                                    slctedIdVote = item['id_vote'];
                                    slctedIdFinalis = idFinalis;
                                    slctedNamaFinalis = item['nama_finalis'];

                                    id_paket = newIdPaket!;
                                    counts = newCounts;
                                    harga_akhir = newHarga;
                                    harga_akhir_asli = newHargaAsli;
                                    countData = newCountData;
                                  });
                                },
                                harga_akhir_asli: _hargaAsliPerFinalis[idFinalis] ?? 0,
                                harga_akhir: _hargaPerFinalis[idFinalis] ?? 0,
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

                              final idFinalis = item['id_finalis'];

                              final selectedQty = await PaketVoteModal.show(
                                context,
                                index,
                                paketTerbaik,
                                paketLainnya,
                                color,
                                bgColor,
                                _idPaketPerFinalis[idFinalis],
                                currencyCode!,
                                selectedIdPaket: _idPaketPerFinalis[idFinalis],
                              );

                              if (selectedQty != null) {
                                setState(() {
                                  _idPaketPerFinalis[idFinalis] = selectedQty['id_paket'];
                                  _countsPerFinalis[idFinalis] = selectedQty['counts'];
                                  _hargaPerFinalis[idFinalis] = selectedQty['harga_akhir'];
                                  _hargaAsliPerFinalis[idFinalis] = selectedQty['harga_akhir_asli'];
                                  _countDataPerFinalis[idFinalis] = selectedQty['count_data'];
                                  
                                  slctedIdVote = item['id_vote'];
                                  slctedIdFinalis = idFinalis;
                                  slctedNamaFinalis = item['nama_finalis'];
                                  
                                  id_paket = _idPaketPerFinalis[idFinalis]!;
                                  counts = _countsPerFinalis[idFinalis] ?? 0;
                                  harga_akhir = _hargaPerFinalis[idFinalis] ?? 0;
                                  harga_akhir_asli = _hargaAsliPerFinalis[idFinalis] ?? 0;
                                  countData = _countDataPerFinalis[idFinalis] ?? 0;
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
            );
          },
        ),

        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          ),

        if (!hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                bahasa['no_more'] ?? 'Semua data sudah ditampilkan',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
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
        SizedBox(height: 20),
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
              borderRadius: BorderRadius.circular(8),
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