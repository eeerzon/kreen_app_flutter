

// ignore_for_file: must_be_immutable, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
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
  final formatter = NumberFormat.decimalPattern("id_ID");

  bool isAnonymous = false;
  final TextEditingController _supportController = TextEditingController();

  Map<String, dynamic> vote = {};
  List<dynamic> leaderboard = [];

  Map<String, dynamic> detailOrder = {};
  Map<String, dynamic> voteOder = {};
  List<dynamic> voteOrderDetail = [];
  List<dynamic> finalis = [];

  String? langCode;
  Map<String, dynamic> detailVoteLang = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _loadkonten();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempDetailVoteLang = await LangService.getJsonData(langCode!, "detail_vote");

    setState(() {
      detailVoteLang = tempDetailVoteLang;
    });
  }

  Future<void> _loadkonten() async {
    final resultVote = await ApiService.get("/vote/${widget.id_vote}");

    final resultOrder = await ApiService.get("/order/vote/${widget.id_order}");
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

  Widget buildKonten() {
    final dateStr = vote['tanggal_grandfinal_mulai']?.toString() ?? '-';
    
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(detailVoteLang['send_support'] ?? '',),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
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
                  detailVoteLang['vote_success'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  detailVoteLang['dukung'],
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
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/img_placeholder.jpg',
                          image: vote['banner'],
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
                    ),
            
                    const SizedBox(width: 16,),
            
                    Expanded( // penting agar tdk overflow
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
                                '${detailVoteLang['penyelenggara']}: ',
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
                              //text
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
                              //text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${detailVoteLang['lokasi']} : ${vote['lokasi_nama_tempat'] ?? '-'}',
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
                    const Text(
                      'Anonymous',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  detailVoteLang['support'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
            
                const SizedBox(height: 8),
                TextField(
                  controller: _supportController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: detailVoteLang['support_hint'],
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                  },
                ),
            
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final dukungan = _supportController.text;
            
                      //kirim ke API
                      // ApiService.post('/support', {'text': dukungan, 'anonymous': isAnonymous});
                      Map<String, dynamic>? result;
                      if (isAnonymous) {
                          final body_anonim = {
                            "id_vote": widget.id_vote,
                            "id_order": widget.id_order,
                            "name": '',
                            "support_text": dukungan,
                            "anonymous": isAnonymous.toString()
                          };
                        result = await ApiService.post('/vote/send-support', body: body_anonim);
                      } else {
                        final body = {
                          "id_vote": widget.id_vote,
                          "id_order": widget.id_order,
                          "name": widget.nama,
                          "support_text": dukungan,
                          "anonymous": isAnonymous.toString()
                        };
                        
                        result = await ApiService.post('/vote/send-support', body: body);
                      }
            
                      if (result != null) {
                        final temprc = result['rc'];
                        if (temprc == 200) {
                          Navigator.pop(context);
                        }
                      }
            
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      detailVoteLang['send_support'],
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}