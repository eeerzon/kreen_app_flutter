import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class ExploreAll extends StatefulWidget {
  final String keyword;
  final List<String> timeFilter;
  final List<String> priceFilter;
  final int pageFilter;

  const ExploreAll({
    super.key, 
    required this.keyword,
    required this.timeFilter,
    required this.priceFilter,
    required this.pageFilter
  });

  @override
  State<ExploreAll> createState() => _ExploreAllState();
}

class _ExploreAllState extends State<ExploreAll> {
  String? langCode, currencyCode;
  bool isLoadingMore = false;
  bool isFirstLoad = true;

  List<dynamic> allData = [];
  List<dynamic> events = [];
  List<dynamic> votes = [];
  List<dynamic> allDataCombained = [];

  final ScrollController _scrollController = ScrollController();
  bool hasMore = true;
  int limit = 6;
  late int currentPage = widget.pageFilter;

  Map<String, dynamic> bahasa = {};

  bool showErrorBar = false;
  String errorMessage = "";

  Future<void> _getBahasa() async {
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

  Future<void> _loadContent(bool isFirst, String? term) async {
    String filterTime = "";
    if (widget.timeFilter.isNotEmpty) {
      filterTime = widget.timeFilter.join(",");
    }

    String filterPrice = "";
    if (widget.priceFilter.isNotEmpty) {
      filterPrice = widget.priceFilter.join(",");
    }

    final endpointAll = isFirst 
      ? "/v2/global-search?time=$filterTime&price=$filterPrice&limit=$limit&page=1" 
      : filterTime == ""
        ? "/v2/global-search?term=$term&time=$filterTime&price=$filterPrice&limit=$limit&page=1"
        : "/v2/global-search?term=$term&time=$filterTime&price=$filterPrice&limit=9999&page=1";

    final responses = await ApiService.get(endpointAll, xLanguage: langCode, xCurrency: currencyCode);
    if (responses == null || responses['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = responses?['message'];
      });
      return;
    }

    if (!mounted) return;

    final resultAll = responses!['data'] ?? [];

    setState(() {
      allDataCombained = resultAll;
      isFirstLoad = false;
      showErrorBar = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadContent(isFirstLoad, null);
    });
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        _loadMoreKonten();
      }
    });
  }

  Future<void> _fetchKonten({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore || !hasMore) return;
      isLoadingMore = true;
    } else {
      if (!mounted) return;
      setState(() => isFirstLoad = true);
      hasMore = true;
    }

    final url = "$baseapiUrl/v2/global-search?time=${widget.timeFilter.join(",")}&price=${widget.priceFilter.join(",")}&limit=6&page=$currentPage";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
        "x-language": langCode!,
        "x-currency": currencyCode!
      }
    );

    List newData = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      newData = List.from(data['data'] ?? []);
    } else if (response.statusCode == 408) {
      showErrorBar = true;
      errorMessage = bahasa['timeout'];
      return;
    } else if (response.statusCode == 503) {
      showErrorBar = true;
      errorMessage = bahasa['no_internet'];
      return;
    } else if (response.statusCode == 500) {
      showErrorBar = true;
      errorMessage = bahasa['error'];
      return;
    }

    if (!mounted) return;
    setState(() {
      if (loadMore) {
        allDataCombained.addAll(newData);
        isLoadingMore = false;
      } else {
        allDataCombained = newData;
        isFirstLoad = false;
      }
      hasMore = newData.isNotEmpty;

      showErrorBar = false;
    });
  }


  Future<void> _loadMoreKonten() async {
    setState(() {
      currentPage++;
    });
    await _fetchKonten(loadMore: true);
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  void didUpdateWidget(covariant ExploreAll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeFilter != widget.timeFilter ||
      oldWidget.priceFilter != widget.priceFilter ||
      oldWidget.keyword != widget.keyword) {
      _loadContent(false, widget.keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              isFirstLoad
                ? buildSkeleton()
                : buildKonten(),

              GlobalErrorBar(
                visible: showErrorBar, 
                message: errorMessage, 
                onRetry: () {
                  _loadContent(false, widget.keyword);
                }
              )
            ],
          ), 
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
            bahasa['no_data'] ?? 'No Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoadingMore &&
              hasMore &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMoreKonten();
          }
          return false;
        },
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: allDataCombained.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < allDataCombained.length) {
              final item = allDataCombained[index];
              final title = item['title']?.toString() ?? 'Tanpa Judul';
              final dateStr = item['start_date']?.toString() ?? '-';
              final img = item['banner']?.toString() ?? '';

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
                    if (item['type'] == 'event') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailEventPage(
                                id_event: item['id'].toString(), 
                                price: item['price'],
                              ),
                        ),
                      );
                    } else if (item['type'] == 'vote') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailVotePage(
                            id_event: item['id'].toString(),
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
                                  ? Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Image.asset(
                                          'assets/images/img_placeholder.jpg',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/img_broken.jpg',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/img_broken.jpg',
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            ),

                            if (item['type'] == 'event') Positioned(
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

                              //penyelenggara
                              const SizedBox(height: 4),
                              Text(
                                item['merchant_name'],
                                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                                ? bahasa['harga_detail']  //'Gratis'
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
            } else {
              if (isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Colors.red,)),
                );
              } else if (!hasMore) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      //"Tidak ada data lagi",
                      bahasa['no_more'] ?? "",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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