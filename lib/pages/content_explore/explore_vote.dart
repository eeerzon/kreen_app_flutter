// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:shimmer/shimmer.dart';

class ExploreVote extends StatefulWidget {
  const ExploreVote({super.key});

  @override
  State<ExploreVote> createState() => _ExploreVoteState();
}

class _ExploreVoteState extends State<ExploreVote> {
  String? langCode;
  bool isLoadingContent = true;
  bool isFirst = true;

  List<dynamic> votes = [];

  Future<void> _loadContent(bool isFirst, String? term) async {
    
    final endpointVote = isFirst ? "/vote" : "/vote?term=$term";

    final responses = await ApiService.get(endpointVote);

    if (!mounted) return;

    final resultVote = responses;

    await _precacheAllImages(context, resultVote!['data']);

    setState(() {
      votes = resultVote['data'] ?? [];
      isLoadingContent = false;
    });
  }



  Future<void> _precacheAllImages(BuildContext context, List<dynamic> votes) async {
    List<String> allImageUrls = [];

    // ambil semua img dari vote populer
    for (var item in votes) {
      final url = item['img']?.toString();
      if (url != null && url.isNotEmpty) allImageUrls.add(url);
    }

    // hilangkan duplikat biar efisien
    allImageUrls = allImageUrls.toSet().toList();

    // pre-cache semua gambar
    for (String url in allImageUrls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        debugPrint("Gagal pre-cache $url: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent(isFirst, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          color: Colors.white,
          child: isLoadingContent
            ? buildSkeleton()
            : buildKonten()
        ),
    );
  }

  Widget buildSkeleton() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildKonten() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // search bar
        TextField(
          decoration: InputDecoration(
            hintText: "Pencarian",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            _loadContent(false, value);
            setState(() {
              buildKonten();
            });
          },
        ),

        // konten
        SizedBox(height: 16,),
        Expanded(
          child: ListView.builder(
            itemCount: votes.length,
            itemBuilder: (context, index) {
              final item = votes[index];
              final title = item['title']?.toString() ?? 'Tanpa Judul';
              final dateStr = item['date_event']?.toString() ?? '-';
              final img = item['img']?.toString() ?? '';

              String formattedDate = '-';
              if (dateStr.isNotEmpty) {
                try {
                  final date = DateTime.parse(dateStr);
                  if (langCode == 'id') {
                    formattedDate = DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(date);
                  } else {
                    final formatter = DateFormat("EEEE, MMMM d yyyy", "en_US");
                    formattedDate = formatter.format(date);
                    final day = date.day;
                    String suffix = 'th';
                    if (day % 10 == 1 && day != 11) {
                      suffix = 'st';
                    } else if (day % 10 == 2 && day != 12) {
                      suffix = 'nd';
                    } else if (day % 10 == 3 && day != 13) {
                      suffix = 'rd';
                    }
                    formattedDate = formatter.format(date).replaceFirst('$day', '$day$suffix');
                  }
                } catch (e) {
                  formattedDate = '-';
                }
              }

              final formatter = NumberFormat.decimalPattern("id_ID");
              final hargaFormatted = formatter.format(item['price'] ?? 0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailVotePage(
                          id_event: item['id_event'].toString(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: kGlobalPadding,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300,),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: img.isNotEmpty
                              ? FadeInImage.assetNetwork(
                                  placeholder: 'assets/images/placeholder.png',
                                  image: img,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder: (context, error, stack) => Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Konten
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['price'] == 0
                                ? 'Gratis'
                                : "${item['currency']} $hargaFormatted",
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}