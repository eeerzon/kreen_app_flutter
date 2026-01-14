import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class ExploreAll extends StatefulWidget {
  final String keyword;
  const ExploreAll({super.key, required this.keyword});

  @override
  State<ExploreAll> createState() => _ExploreAllState();
}

class _ExploreAllState extends State<ExploreAll> {
  String? langCode, currencyCode;
  bool isLoadingContent = true;
  bool isFirst = true;

  List<dynamic> allData = [];
  List<dynamic> events = [];
  List<dynamic> votes = [];
  List<dynamic> allDataCombained = [];

  Map<String, dynamic> votelang = {};

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() {
      langCode = code;
    });
    
    final tempvotelang = await LangService.getJsonData(langCode!, "detail_vote");

    setState(() {
      votelang = tempvotelang;
    });
  }

  Future<void> _getCurrency() async {
    final code = await StorageService.getCurrency();
    setState(() {
      currencyCode = code;
    });
  }

  Future<void> _loadContent(bool isFirst, String? term) async {
    final endpointAll = isFirst ? "/global-search" : "/global-search?term=$term";

    final responses = await ApiService.get(endpointAll, xLanguage: langCode, xCurrency: currencyCode);

    if (!mounted) return;

    final resultAll = responses;

    events = resultAll!['data']['events'] as List<dynamic>;

    votes = resultAll['data']['votes'] as List<dynamic>;

    List<dynamic> allItems = [
      ...events,
      ...votes,
    ];

    sortByNearestDate(allItems);

    setState(() {
      allDataCombained = allItems;
      isLoadingContent = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadContent(isFirst, null);
    });
  }

  @override
  void didUpdateWidget(covariant ExploreAll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword) {
      _loadContent(false, widget.keyword);
    }
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
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: 10,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65, // sesuaikan dengan card asli
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // image placeholder
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    height: 12,
                    width: 80,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildKonten() {
    if (allDataCombained.isEmpty) {
      return Column(
        children: [
          Image.asset(
            'assets/images/placeholder.png',
            width: 200,
            height: 200,
          ),

          SizedBox(height: 12,),

          Text(
            votelang['no_data'] ?? 'No Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //konten
        Expanded(
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            itemCount: allDataCombained.length,
            itemBuilder: (context, index) {
              final item = allDataCombained[index];
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

              final formatter = NumberFormat.decimalPattern("en_US");
              final hargaFormatted = formatter.format(item['price'] ?? 0);

              final typeEvent = item['type_event'] ?? '-';
              Color colorType = Colors.blue;
              if (typeEvent == 'offline') {
                colorType = Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.all(0),
                child: InkWell(
                  onTap: () {
                    if (item['jenis'] == 'event') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailEventPage(
                                id_event: item['id_event'].toString(), 
                                price: item['price'],
                              ),
                        ),
                      );
                    } else if (item['jenis'] == 'vote') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailVotePage(
                            id_event: item['id_event'].toString(),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300,),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //gambar
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: img.isNotEmpty
                                  ? FadeInImage.assetNetwork(
                                      placeholder: 'assets/images/img_placeholder.jpg',
                                      image: img,
                                      fit: BoxFit.cover,
                                      imageErrorBuilder: (context, error, stack) => AspectRatio(
                                        aspectRatio: 4 / 5,
                                        child: Image.asset(
                                          'assets/images/img_broken.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/img_broken.jpg',
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            ),

                            if (item['jenis'] == 'event') Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeEvent.toString().toUpperCase(),
                                  style: TextStyle(
                                    color: colorType,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        

                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 38,
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                  child: Text(
                                  formattedDate,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12, color: Colors.grey
                                  ),
                                ),
                              ),
                              

                              const SizedBox(height: 4),
                              Text(
                                item['price'] == 0
                                ? votelang['harga_detail']  //'Gratis'
                                : currencyCode == null
                                  ? "${item['currency']} $hargaFormatted"
                                  : "$currencyCode $hargaFormatted",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

  DateTime parseDate(String date) {
    return DateTime.parse(date); // yyyy-MM-dd
  }

  void sortByNearestDate(List<dynamic> list) {
    final now = DateTime.now();

    list.sort((a, b) {
      final dateA = parseDate(a['date_event']);
      final dateB = parseDate(b['date_event']);

      final diffA = dateA.difference(now).inDays.abs();
      final diffB = dateB.difference(now).inDays.abs();

      return diffA.compareTo(diffB);
    });
  }

}