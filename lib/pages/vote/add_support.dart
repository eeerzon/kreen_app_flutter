

// ignore_for_file: must_be_immutable, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_function.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class AddSupportPage extends StatefulWidget {
  String id_vote;
  String id_order;
  String nama;

  AddSupportPage({super.key, required this.id_vote, required this.id_order, required this.nama});

  @override
  State<AddSupportPage> createState() => _AddSupportPageState();
}

class _AddSupportPageState extends State<AddSupportPage> {
  bool _isLoading = true;
  final formatter = NumberFormat.decimalPattern("en_US");

  bool isAnonymous = false;
  final TextEditingController _supportController = TextEditingController();

  Map<String, dynamic> vote = {};
  List<dynamic> leaderboard = [];

  Map<String, dynamic> detailOrder = {};
  Map<String, dynamic> voteOder = {};
  List<dynamic> voteOrderDetail = [];
  List<dynamic> finalis = [];

  String? langCode, token;
  Map<String, dynamic> bahasa = {};

  bool isSubmitting = false;
  String? currencyCode;

  bool _showError = false;

  final _supportFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadkonten();
    });
  }

  Future<void> _getBahasa() async {
    token = await StorageService.getToken();
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  Future<void> _loadkonten() async {
    final resultVote = await ApiService.get("/vote/${widget.id_vote}", xLanguage: langCode, xCurrency: currencyCode, token: token);

    final resultOrder = await ApiService.get("/order/vote/${widget.id_order}", xLanguage: langCode, xCurrency: currencyCode, token: token);
    final tempOrder = resultOrder?['data'] ?? {};
    final temp_vote_order = tempOrder['vote_order'] ?? {};
    final temp_vote_order_detail = tempOrder['vote_order_detail'] ?? [];
    final tempFinalis = tempOrder['vote_finalis'] ?? [];

    final Map<String, dynamic> tempVote = resultVote?['data'] ?? {};
    if (mounted) {
      setState(() {
        vote = tempVote;

        detailOrder = tempOrder;

        voteOder = temp_vote_order;
        voteOrderDetail = temp_vote_order_detail;
        finalis = tempFinalis;

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? buildSkeletonHome()
          : buildKonten()
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

  Widget buildKonten() {
    final dateStr = vote['tanggal_grandfinal_mulai']?.toString() ?? '-';
    
    String formattedDate = '-';

    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        if (langCode == 'id') {
          final formatter = DateFormat("$formatDay, $formatDateId", "id_ID");
          formattedDate = formatter.format(date);
        } else {
          final formatter = DateFormat("$formatDay, $formatDateEn", "en_US");
          formattedDate = formatter.format(date);
          
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

    Future<void> doSubmitProcess() async {
      final dukungan = _supportController.text;

      bool isdukunganEmpty = dukungan.isEmpty;

      if (isdukunganEmpty) {
        setState(() {
          _showError = true;
        });
        return;
      }
      
      Map<String, dynamic>? result;
      final body = {
        "id_vote": widget.id_vote,
        "id_order": widget.id_order,
        "name": isAnonymous ? '' : widget.nama,
        "support_text": dukungan,
        "anonymous": isAnonymous.toString()
      };
      result = await ApiService.post('/vote/send-support', body: body, xLanguage: langCode, xCurrency: currencyCode, token: token);

      if (result != null) {
        final temprc = result['rc'];
        if (temprc == 200) {

          await Future.delayed(const Duration(milliseconds: 400));

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DetailVotePage(
                id_event: widget.id_vote,
                currencyCode: currencyCode,
              ),
            ),
            (route) => route.isFirst,
          );
        } else {
          setState(() => isSubmitting = false);
        }
      } else {
        setState(() => isSubmitting = false);
      }
    }

    void handleSubmit() async {
      
      if (isSubmitting) return;

      final isValid = _validateAllForm();

      if (!isValid) {
        return;
      }

      setState(() => isSubmitting = true);

      try {
        await doSubmitProcess(); 
      } finally {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(bahasa['send_support'] ?? '',),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => DetailVotePage(
                  id_event: widget.id_vote,
                  currencyCode: currencyCode,
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: kGlobalPadding,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.network(
                    '$baseUrl//image/success.svg',
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/img_broken.jpg',
                        height: 180,
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  Text(
                    bahasa['vote_success'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    bahasa['dukung'],
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
              
                  SizedBox(height: 16,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 4 / 5,
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/images/img_placeholder.jpg',
                              image: vote['banner'],
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
                      ),
              
                      const SizedBox(width: 16,),
              
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vote['judul_vote'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
              
                            SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${bahasa['penyelenggara']}: ',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  vote['nama_penyelenggara'] ?? '-',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
              
                            SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SvgPicture.network(
                                  "$baseUrl/image/Calendar.svg",
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
              
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formattedDate
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
              
                            SizedBox(height: 8,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SvgPicture.network(
                                  "$baseUrl/image/Locations.svg",
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
              
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${bahasa['lokasi']} : ${vote['lokasi_nama_tempat'] ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]
                  ),
              
                  SizedBox(height: 20,),
                  Column(
                    children: List.generate(finalis.length, (index) {
                      final item = finalis[index];
              
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == finalis.length - 1 ? 0 : 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300,),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item['poster_finalis'] != null 
                                    ? Image.network(
                                        item['poster_finalis'],
                                        width: 70,
                                        height: 70,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            "$baseUrl/noimage_finalis.png",
                                            width: 70,
                                            height: 70,
                                          );
                                        },
                                      )
                                    : Image.network(
                                        "$baseUrl/noimage_finalis.png",
                                        width: 70,
                                        height: 70,
                                      ),
                                ),
                              ),
              
                              const SizedBox(width: 8),
              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama_finalis'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    const SizedBox(height: 4),
                                    Text(
                                      "${formatter.format(voteOrderDetail[index]['qty'])} vote",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            isAnonymous = !isAnonymous;
                          });
                        },
                        child: Text(
                          bahasa['anonim'] ?? 'Anonymous',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      Checkbox(
                        value: isAnonymous,
                        activeColor: Colors.red,
                        onChanged: (value) {
                          setState(() {
                            isAnonymous = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 16),
                  Text(
                    bahasa['support'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
              
                  const SizedBox(height: 8),
                  TextField(
                    controller: _supportController,
                    focusNode: _supportFocus,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: bahasa['support_hint'],
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      if (_showError && val.trim().isNotEmpty) {
                        setState(() => _showError = false);
                      } else if (!_showError && val.trim().isEmpty) {
                        setState(() => _showError = true);
                      }
                    },
                  ),
                  if (_showError)
                      Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 0, 0),
                        child: Text(
                          bahasa['support_answer_error'],
                          style: TextStyle(color: Colors.red[900], fontSize: 12),
                        ),
                      ),
                    ),
              
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting 
                        ? null 
                        : handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Text(
                              bahasa['send_support'],
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  bool _validateAllForm() {
    bool isValid = true;
    FocusNode? firstErrorFocus;

    if (_supportController.text.trim().isEmpty) {
      isValid = false;
      firstErrorFocus ??= _supportFocus;
      setState(() => _showError = true);
    }

    if (!isValid) {
      if (firstErrorFocus != null) {
        _scrollToFocus(firstErrorFocus);
      }
    }

    return isValid;
  }

  void _scrollToFocus(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      node.requestFocus();

      final context = node.context;
      if (context == null) return;

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    });
  }
}