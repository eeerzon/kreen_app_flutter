// ignore_for_file: must_be_immutable, deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/modal/detail_order_modal.dart';
import 'package:kreen_app_flutter/pages/event/detail_event.dart';
import 'package:kreen_app_flutter/pages/order/waiting_order_event.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:http/http.dart' as http;

class OrderEvent extends StatefulWidget {
  const OrderEvent({super.key});

  @override
  State<OrderEvent> createState() => _OrderEventState();
}

class _OrderEventState extends State<OrderEvent> with SingleTickerProviderStateMixin{
  String? langCode, currencyCode;
  late TabController _tabController;
  bool isLoading = true;

  Map<String, dynamic> bahasa = {};
  String? orderMenunggu, orderGagal;

  bool showErrorBar = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _getCurrency();
      await _loadContent();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");
    
    setState(() {
      bahasa = tempbahasa;
      orderMenunggu = bahasa['order_menunggu'];
      orderGagal = bahasa['order_gagal'];
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
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> orderSuccess = [];
  List<dynamic> orderPending = [];
  List<dynamic> orderFail = [];

  List<Map<String, dynamic>> eventSukses = [];
  List<Map<String, dynamic>> eventPending = [];
  List<Map<String, dynamic>> eventGagal = [];

  Future<void> _loadContent() async {

    var getUser = await StorageService.getUser();
    var idUser = getUser['id'];

    var resultSuccess = await ApiService.get('/order/event?id_user=$idUser&status=success&sort_by=terbaru', xLanguage: langCode);
    if (resultSuccess == null || resultSuccess['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultSuccess?['message'];
      });
      return;
    }

    var resultPending = await ApiService.get('/order/event?id_user=$idUser&status=pending&sort_by=terbaru', xLanguage: langCode);
    if (resultPending == null || resultPending['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultPending?['message'];
      });
      return;
    }

    var resultFail = await ApiService.get('/order/event?id_user=$idUser&status=fail&sort_by=terbaru', xLanguage: langCode);
    if (resultFail == null || resultFail['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = resultFail?['message'];
      });
      return;
    }

    var tempSuccess = resultSuccess['data'];
    var tempPending = resultPending['data'];
    var tempFail = resultFail['data'];

    List<Map<String, dynamic>> tempEventSukses = [];
    List<Map<String, dynamic>> tempEventPending = [];
    List<Map<String, dynamic>> tempEventGagal = [];

    for (var ordersukses in tempSuccess) {
      final idOrder = ordersukses['id_order'];
      if (idOrder == null || idOrder.toString().isEmpty) continue;

      final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
      final data = resultOrder?['data'];
      final tempOrder = data is Map<String, dynamic> ? data : {};
      final tempVoteSukses = tempOrder['event'] ?? {};
      final tempVoteOrder = tempOrder['event_order'] ?? {};

      tempEventSukses.add({
        'id_order': tempVoteOrder['id_order'],
        'event_title': tempVoteSukses['event_title'] ?? '-',
        'order_status': tempVoteOrder['order_status'],
        'tanggal': ordersukses['created_at'] ?? '-',
        'banner': tempVoteSukses['event_banner'],
        'id_event': tempVoteSukses['id_event'],
      });
    }

    for (var orderpending in tempPending) {
      final idOrder = orderpending['id_order'];
      if (idOrder == null || idOrder.toString().isEmpty) continue;

      final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
      final data = resultOrder?['data'];
      final tempOrder = data is Map<String, dynamic> ? data : {};
      final tempVotePending = tempOrder['event'] ?? {};
      final tempVoteOrder = tempOrder['event_order'] ?? {};

      tempEventPending.add({
        'id_order': tempVoteOrder['id_order'],
        'event_title': tempVotePending['event_title'] ?? '-',
        'order_status': tempVoteOrder['order_status'],
        'tanggal': orderpending['created_at'] ?? '-',
        'banner': tempVotePending['event_banner'],
        'id_event': tempVotePending['id_event'],
      });
    }

    for (var ordergagal in tempFail) {
      final idOrder = ordergagal['id_order'];
      if (idOrder == null || idOrder.toString().isEmpty) continue;

      final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
      final data = resultOrder?['data'];
      final tempOrder = data is Map<String, dynamic> ? data : {};
      final tempVoteGagal = tempOrder['event'] ?? {};
      final tempVoteOrder = tempOrder['event_order'] ?? {};

      tempEventGagal.add({
        'id_order': tempVoteOrder['id_order'],
        'event_title': tempVoteGagal['event_title'] ?? '-',
        'order_status': tempVoteOrder['order_status'],
        'tanggal': ordergagal['created_at'] ?? '-',
        'banner': tempVoteGagal['event_banner'],
        'id_event': tempVoteGagal['id_event'],
      });
    }

    if (!mounted) return;
    setState(() {
      orderSuccess = tempSuccess;
      eventSukses = tempEventSukses;

      orderPending = tempPending;
      eventPending = tempEventPending;

      orderFail = tempFail;
      eventGagal = tempEventGagal;

      isLoading = false;
      showErrorBar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GlobalErrorBar(
          visible: showErrorBar, 
          message: errorMessage, 
          onRetry: () {
            _loadContent();
          }
        ),

        Column(
          children: [
            
            Material(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.red,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.check_circle_outline), text: bahasa['selesai']), //selesai
                  Tab(icon: Icon(Icons.access_time), text: orderMenunggu), //menunggu
                  Tab(icon: Icon(Icons.close_rounded), text: orderGagal), //gagal
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                color: Colors.white,
                child: isLoading
                    ? _buildSkeletonLoader()
                    : TabBarView(
                  controller: _tabController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [

                    orderSuccess.isNotEmpty
                      ? EventSuccess(orderSuccess: orderSuccess, events: eventSukses,)
                      : NoOrder(),

                    orderPending.isNotEmpty
                      ? EventPending(orderPending: orderPending, events: eventPending)
                      : NoOrder(),

                    orderFail.isNotEmpty
                      ? EventFail(orderFail: orderFail, events: eventGagal)
                      : NoOrder(),

                  ],
                ),
              ) 
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EventSuccess extends StatefulWidget {
  List<dynamic> orderSuccess;
  List<Map<String, dynamic>> events;
  EventSuccess({super.key,  required this.orderSuccess, required this.events});

  @override
  State<EventSuccess> createState() => _EventSuccessState();
}

class _EventSuccessState extends State<EventSuccess> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> orderSuccess = [];
  List<dynamic> events = [];

  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;

  String? langCode;

  final formatterNUmber = NumberFormat.decimalPattern("en_US");

  String statusOrder = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
    
    orderSuccess = List.from(widget.orderSuccess);
    events = List.from(widget.events);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreOrders();
      }
    });
  }

  Map<String, dynamic> bahasa = {};

  Future <void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;

      isLoading = false;
    });
  }

  Future<void> _fetchOrders({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    if (!loadMore) {
        currentPage = 1;
        hasMore = true;
      }

    var getUser = await StorageService.getUser();
    var idUser = getUser['id'] ?? '';

    final url =
        "$baseapiUrl/order/event?id_user=$idUser&status=success&sort_by=terbaru&current_page=$currentPage";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
      },
    );

    List newEvents = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List newData = data['data'] ?? [];

      for (var ordersuccess in newData) {
        final idOrder = ordersuccess['id_order'];
        if (idOrder == null || idOrder.toString().isEmpty) continue;

        final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
        final data = resultOrder?['data'];
        final tempOrder = data is Map<String, dynamic> ? data : {};
        final tempEventSukses = tempOrder['event'] ?? {};
        final tempEventOrder = tempOrder['event_order'] ?? {};

        newEvents.add({
          'id_order': tempEventOrder['id_order'],
          'event_title': tempEventSukses['event_title'] ?? '-',
          'order_status': tempEventOrder['order_status'],
          'tanggal': ordersuccess['created_at'] ?? '-',
          'banner': tempEventSukses['event_banner'],
          'id_event': tempEventSukses['id_event'],
        });
      }

      setState(() {
        if (loadMore) {
          orderSuccess.addAll(newData);
          events.addAll(newEvents);
        } else {
          orderSuccess = newData;
          events = newEvents;
        }
        
        hasMore = newData.isNotEmpty;
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    setState(() => currentPage++);
    await _fetchOrders(loadMore: true);
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMoreOrders();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: kGlobalPadding,
          itemCount: orderSuccess.length + 1,
          itemBuilder: (context, index) {
            if (index < orderSuccess.length) {
              final item = orderSuccess[index];
              final itemEvents = events[index];

              String formattedDate = '-';

              if (item['created_at'].isNotEmpty) {
                try {
                  // parsing string ke DateTime
                  final date = DateTime.parse(item['created_at']); // pastikan format ISO (yyyy-MM-dd)
                  if (langCode == 'id') {
                    // Bahasa Indonesia
                    final formatter = DateFormat("dd MMMM yyyy", "id_ID");
                    formattedDate = formatter.format(date);
                  } else {
                    // Bahasa Inggris
                    final formatter = DateFormat("MMMM d yyyy", "en_US");
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

              var qty = item['qty'].toString();
              
              if (itemEvents['order_status'] == '0'){
                statusOrder = bahasa['status_order_0'] ?? '-'; // 'gagal';
              } else if (itemEvents['order_status'] == '1'){
                statusOrder = bahasa['status_order_1'] ?? '-'; // 'selesai';
              } else if (itemEvents['order_status'] == '2'){
                statusOrder = bahasa['status_order_2'] ?? '-'; // 'batal';
              } else if (itemEvents['order_status'] == '3'){
                statusOrder = bahasa['status_order_3'] ?? '-'; // 'menunggu';
              } else if (itemEvents['order_status'] == '4'){
                statusOrder = bahasa['status_order_4'] ?? '-'; // 'refund';
              } else if (itemEvents['order_status'] == '20'){
                statusOrder = bahasa['status_order_20'] ?? '-'; // 'expired';
              } else if (itemEvents['order_status'] == '404'){
                statusOrder = bahasa['status_order_404'] ?? '-'; // 'hidden';
              }

              var eventPrice = item['price'] ?? 0;

              String? currencyRegion;
              if (item['region'] == "EU"){
                currencyRegion = 'EUR';
              } else if (item['region'] == "ID"){
                currencyRegion = 'IDR';
              } else if (item['region'] == "PH"){
                currencyRegion = 'PHP';
              } else if (item['region'] == "SG"){
                currencyRegion = 'SGD';
              } else if (item['region'] == "US"){
                currencyRegion = 'USD';
              } else if (item['region'] == "TH"){
                currencyRegion = 'THB';
              } else if (item['region'] == "MY"){
                currencyRegion = 'MYR';
              } else if (item['region'] == "VN"){
                currencyRegion = 'VND';
              }

              num totalPrice = item['price'] + item['fees'];
              num totalPriceRegion = totalPrice * item['currency_value_region'];
              totalPriceRegion = num.parse(totalPriceRegion.toStringAsFixed(5));
              totalPriceRegion = (totalPriceRegion * 100).ceil() / 100;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Column(
                    children: [
                      //tgl
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate
                            ),

                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (itemEvents['order_status'] == '0')
                                          ? Colors.red.shade50
                                          : (itemEvents['order_status'] == '1')
                                                ? Colors.green.shade50
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red.shade50
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange.shade50
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red.shade50
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red.shade50
                                                        : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (itemEvents['order_status'] == '0')
                                          ? Colors.red
                                          : (itemEvents['order_status'] == '1')
                                                ? Colors.green
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red
                                                        : Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    statusOrder,
                                    style: TextStyle(
                                      color: (itemEvents['order_status'] == '0')
                                              ? Colors.red
                                              : (itemEvents['order_status'] == '1')
                                                ? Colors.green
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red
                                                        : Colors.black,),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // image
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemEvents['banner'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/img_broken.jpg',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8,),

                            Expanded( // penting agar tdk overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemEvents['event_title'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$qty ${bahasa['tiket']}"
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'] == 0
                                    ? bahasa['harga_detail'] ?? "" //'Gratis'
                                    : "$currencyRegion ${formatterNUmber.format(totalPriceRegion)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // button
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (itemEvents['id_event'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailEventPage(id_event: itemEvents['id_event'].toString(), price: eventPrice,),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(bahasa['no_data'] ?? "")));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    // "Beli Lagi",
                                      bahasa['beli_lagi'] ?? "",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  if (itemEvents['id_order'] != null) {
                                    await DetailOrderModal.showEvent(context, itemEvents['id_order'], true);
                                  } else {
                                    ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(bahasa['no_data'])));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Detail Order",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              );

            } else {
              if (isLoading) {
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
                return const SizedBox(height: 80);
              }
            }
          }
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}


class EventPending extends StatefulWidget {
  List<dynamic> orderPending;
  List<Map<String, dynamic>> events;
  EventPending({super.key,  required this.orderPending, required this.events});

  @override
  State<EventPending> createState() => _EventPendingState();
}

class _EventPendingState extends State<EventPending> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> orderPending = [];
  List<dynamic> events = [];

  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;

  String? langCode;

  final formatterNUmber = NumberFormat.decimalPattern("en_US");
  String statusOrder = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
    
    orderPending = List.from(widget.orderPending);
    events = List.from(widget.events);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreOrders();
      }
    });
  }
  
  Map<String, dynamic> bahasa = {};

  Future <void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;

      isLoading = false;
    });
  }

  Future<void> _fetchOrders({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    if (!loadMore) {
        currentPage = 1;
        hasMore = true;
      }

    var getUser = await StorageService.getUser();
    var idUser = getUser['id'] ?? '';

    final url =
        "$baseapiUrl/order/event?id_user=$idUser&status=pending&sort_by=terbaru&current_page=$currentPage";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
      },
    );

    List newEvents = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List newData = data['data'] ?? [];

      for (var orderpending in newData) {
        final idOrder = orderpending['id_order'];
        if (idOrder == null || idOrder.toString().isEmpty) continue;

        final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
        final data = resultOrder?['data'];
        final tempOrder = data is Map<String, dynamic> ? data : {};
        final tempEventPending = tempOrder['event'] ?? {};
        final tempEventOrder = tempOrder['event_order'] ?? {};

        newEvents.add({
          'id_order': tempEventOrder['id_order'],
          'event_title': tempEventPending['event_title'] ?? '-',
          'order_status': tempEventOrder['order_status'],
          'tanggal': orderpending['created_at'] ?? '-',
          'banner': tempEventPending['event_banner'],
          'id_event': tempEventPending['id_event'],
        });
      }

      setState(() {
        if (loadMore) {
          orderPending.addAll(newData);
          events.addAll(newEvents);
        } else {
          orderPending = newData;
          events = newEvents;
        }
        
        hasMore = newData.isNotEmpty;
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    setState(() => currentPage++);
    await _fetchOrders(loadMore: true);
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMoreOrders();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: kGlobalPadding,
          itemCount: orderPending.length + 1,
          itemBuilder: (context, index) {
            if (index < orderPending.length) {
              final item = orderPending[index];
              final itemEvents = events[index];

              String formattedDate = '-';

              if (item['created_at'].isNotEmpty) {
                try {
                  // parsing string ke DateTime
                  final date = DateTime.parse(item['created_at']); // pastikan format ISO (yyyy-MM-dd)
                  if (langCode == 'id') {
                    // Bahasa Indonesia
                    final formatter = DateFormat("dd MMMM yyyy", "id_ID");
                    formattedDate = formatter.format(date);
                  } else {
                    // Bahasa Inggris
                    final formatter = DateFormat("MMMM d yyyy", "en_US");
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

              var qty = item['qty'].toString();
              
              if (itemEvents['order_status'] == '0'){
                statusOrder = bahasa['status_order_0'] ?? '-'; // 'gagal';
              } else if (itemEvents['order_status'] == '1'){
                statusOrder = bahasa['status_order_1'] ?? '-'; // 'selesai';
              } else if (itemEvents['order_status'] == '2'){
                statusOrder = bahasa['status_order_2'] ?? '-'; // 'batal';
              } else if (itemEvents['order_status'] == '3'){
                statusOrder = bahasa['status_order_3'] ?? '-'; // 'menunggu';
              } else if (itemEvents['order_status'] == '4'){
                statusOrder = bahasa['status_order_4'] ?? '-'; // 'refund';
              } else if (itemEvents['order_status'] == '20'){
                statusOrder = bahasa['status_order_20'] ?? '-'; // 'expired';
              } else if (itemEvents['order_status'] == '404'){
                statusOrder = bahasa['status_order_404'] ?? '-'; // 'hidden';
              }

              String? currencyRegion;
              if (item['region'] == "EU"){
                currencyRegion = 'EUR';
              } else if (item['region'] == "ID"){
                currencyRegion = 'IDR';
              } else if (item['region'] == "PH"){
                currencyRegion = 'PHP';
              } else if (item['region'] == "SG"){
                currencyRegion = 'SGD';
              } else if (item['region'] == "US"){
                currencyRegion = 'USD';
              } else if (item['region'] == "TH"){
                currencyRegion = 'THB';
              } else if (item['region'] == "MY"){
                currencyRegion = 'MYR';
              } else if (item['region'] == "VN"){
                currencyRegion = 'VND';
              }

              num totalPrice = item['price'] + item['fees'];
              num totalPriceRegion = totalPrice * item['currency_value_region'];
              totalPriceRegion = num.parse(totalPriceRegion.toStringAsFixed(5));
              totalPriceRegion = (totalPriceRegion * 100).ceil() / 100;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Column(
                    children: [
                      //tgl
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate
                            ),

                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (itemEvents['order_status'] == '0')
                                          ? Colors.red.shade50
                                          : (itemEvents['order_status'] == '1')
                                                ? Colors.green.shade50
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red.shade50
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange.shade50
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red.shade50
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red.shade50
                                                        : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (itemEvents['order_status'] == '0')
                                          ? Colors.red
                                          : (itemEvents['order_status'] == '1')
                                                ? Colors.green
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red
                                                        : Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    statusOrder,
                                    style: TextStyle(
                                      color: (itemEvents['order_status'] == '0')
                                              ? Colors.red
                                              : (itemEvents['order_status'] == '1')
                                                ? Colors.green
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red
                                                        : Colors.black,),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // image
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemEvents['banner'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/img_broken.jpg',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8,),

                            Expanded( // penting agar tdk overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemEvents['event_title'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$qty ${bahasa['tiket']}"
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'] == 0
                                    ? bahasa['harga_detail'] ?? "" //'Gratis'
                                    : "$currencyRegion ${formatterNUmber.format(totalPriceRegion)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // button
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (itemEvents['id_order'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => WaitingOrderEvent(id_order: itemEvents['id_order'], formHistory: true, currency_session: item['currency'],)),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(bahasa['no_data'] ?? "")));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                      //"Kembali ke Pembayaran",
                                      bahasa['back_payment'] ?? "",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  if (itemEvents['id_order'] != null) {
                                    await DetailOrderModal.showEvent(context, itemEvents['id_order'], false);
                                  } else {
                                    ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(bahasa['no_data'])));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Detail Order",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              );

            } else {
              if (isLoading) {
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
                return const SizedBox(height: 80);
              }
            }
          }
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}


class EventFail extends StatefulWidget {
  List<dynamic> orderFail;
  List<Map<String, dynamic>> events;
  EventFail({super.key, required this.orderFail, required this.events});

  @override
  State<EventFail> createState() => _EventFailState();
}

class _EventFailState extends State<EventFail> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> orderFail = [];
  List<dynamic> events = [];

  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;

  String? langCode;

  final formatterNUmber = NumberFormat.decimalPattern("en_US");
  String statusOrder = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
    
    orderFail = List.from(widget.orderFail);
    events = List.from(widget.events);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreOrders();
      }
    });
  }
  
  Map<String, dynamic> bahasa = {};

  Future <void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() {
      langCode = code;
    });

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      bahasa = tempbahasa;

      isLoading = false;
    });
  }

  Future<void> _fetchOrders({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    if (!loadMore) {
        currentPage = 1;
        hasMore = true;
      }

    var getUser = await StorageService.getUser();
    var idUser = getUser['id'] ?? '';

    final url =
        "$baseapiUrl/order/event?id_user=$idUser&status=fail&sort_by=terbaru&current_page=$currentPage";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
      },
    );

    List newEvents = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List newData = data['data'] ?? [];

      for (var ordergagal in newData) {
        final idOrder = ordergagal['id_order'];
        if (idOrder == null || idOrder.toString().isEmpty) continue;

        final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
        final data = resultOrder?['data'];
        final tempOrder = data is Map<String, dynamic> ? data : {};
        final tempEventFail = tempOrder['event'] ?? {};
        final tempEventOrder = tempOrder['event_order'] ?? {};

        newEvents.add({
          'id_order': tempEventOrder['id_order'],
          'event_title': tempEventFail['event_title'] ?? '-',
          'order_status': tempEventOrder['order_status'],
          'tanggal': ordergagal['created_at'] ?? '-',
          'banner': tempEventFail['event_banner'],
          'id_event': tempEventFail['id_event'],
        });
      }

      setState(() {
        if (loadMore) {
          orderFail.addAll(newData);
          events.addAll(newEvents);
        } else {
          orderFail = newData;
          events = newEvents;
        }
        
        hasMore = newData.isNotEmpty;
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    setState(() => currentPage++);
    await _fetchOrders(loadMore: true);
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMoreOrders();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: kGlobalPadding,
          itemCount: orderFail.length + 1,
          itemBuilder: (context, index) {
            if (index < orderFail.length) {
              final item = orderFail[index];
              final itemEvents = events[index];

              String formattedDate = '-';

              if (item['created_at'].isNotEmpty) {
                try {
                  // parsing string ke DateTime
                  final date = DateTime.parse(item['created_at']); // pastikan format ISO (yyyy-MM-dd)
                  if (langCode == 'id') {
                    // Bahasa Indonesia
                    final formatter = DateFormat("dd MMMM yyyy", "id_ID");
                    formattedDate = formatter.format(date);
                  } else {
                    // Bahasa Inggris
                    final formatter = DateFormat("MMMM d yyyy", "en_US");
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

              var qty = item['qty'].toString();
              
              if (itemEvents['order_status'] == '0'){
                statusOrder = bahasa['status_order_0'] ?? '-'; // 'gagal';
              } else if (itemEvents['order_status'] == '1'){
                statusOrder = bahasa['status_order_1'] ?? '-'; // 'selesai';
              } else if (itemEvents['order_status'] == '2'){
                statusOrder = bahasa['status_order_2'] ?? '-'; // 'batal';
              } else if (itemEvents['order_status'] == '3'){
                statusOrder = bahasa['status_order_3'] ?? '-'; // 'menunggu';
              } else if (itemEvents['order_status'] == '4'){
                statusOrder = bahasa['status_order_4'] ?? '-'; // 'refund';
              } else if (itemEvents['order_status'] == '20'){
                statusOrder = bahasa['status_order_20'] ?? '-'; // 'expired';
              } else if (itemEvents['order_status'] == '404'){
                statusOrder = bahasa['status_order_404'] ?? '-'; // 'hidden';
              }

              var eventPrice = item['price'] ?? 0;

              String? currencyRegion;
              if (item['region'] == "EU"){
                currencyRegion = 'EUR';
              } else if (item['region'] == "ID"){
                currencyRegion = 'IDR';
              } else if (item['region'] == "PH"){
                currencyRegion = 'PHP';
              } else if (item['region'] == "SG"){
                currencyRegion = 'SGD';
              } else if (item['region'] == "US"){
                currencyRegion = 'USD';
              } else if (item['region'] == "TH"){
                currencyRegion = 'THB';
              } else if (item['region'] == "MY"){
                currencyRegion = 'MYR';
              } else if (item['region'] == "VN"){
                currencyRegion = 'VND';
              }

              num totalPrice = item['price'] + item['fees'];
              num totalPriceRegion = totalPrice * item['currency_value_region'];
              totalPriceRegion = num.parse(totalPriceRegion.toStringAsFixed(5));
              totalPriceRegion = (totalPriceRegion * 100).ceil() / 100;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Column(
                    children: [
                      //tgl
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate
                            ),

                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (itemEvents['order_status'] == '0')
                                          ? Colors.red.shade50
                                          : (itemEvents['order_status'] == '1')
                                                ? Colors.green.shade50
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red.shade50
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange.shade50
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red.shade50
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red.shade50
                                                        : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (itemEvents['order_status'] == '0')
                                          ? Colors.red
                                          : (itemEvents['order_status'] == '1')
                                                ? Colors.green
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red
                                                        : Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    statusOrder,
                                    style: TextStyle(
                                      color: (itemEvents['order_status'] == '0')
                                              ? Colors.red
                                              : (itemEvents['order_status'] == '1')
                                                ? Colors.green
                                                : (itemEvents['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemEvents['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemEvents['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemEvents['order_status'] == '20')
                                                        ? Colors.red
                                                        : Colors.white,),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // image
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemEvents['banner'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/img_broken.jpg',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8,),

                            Expanded( // penting agar tdk overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemEvents['event_title'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$qty ${bahasa['tiket']}"
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'] == 0
                                    ? bahasa['harga_detail'] ?? "" //'Gratis'
                                    : "$currencyRegion ${formatterNUmber.format(totalPriceRegion)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // button
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (itemEvents['id_event'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailEventPage(id_event: itemEvents['id_event'].toString(), price: eventPrice,),
                                      ),
                                    );
                                  }  else {
                                    ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(bahasa['no_data'])));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    // "Ulangi Pembelian",
                                    bahasa['retry_payment'] ?? "",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  if (itemEvents['id_order'] != null) {
                                    await DetailOrderModal.showEvent(context, itemEvents['id_order'], false);
                                  } else {
                                    ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(bahasa['no_data'])));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Detail Order",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              );

            } else {
              if (isLoading) {
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
                return const SizedBox(height: 80);
              }
            }
          }
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}


class NoOrder extends StatefulWidget {
  const NoOrder({super.key});

  @override
  State<NoOrder> createState() => _NoOrderState();
}

class _NoOrderState extends State<NoOrder> {
  String? langCode;
  Map<String, dynamic> bahasa = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: Colors.grey.shade200,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: kGlobalPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Image.asset(
                      'assets/images/no_order.png',
                      height: 170,
                    )
                  ),

                  const SizedBox(height: 20),
                  Text(
                    // 'maaaf...',
                    bahasa['maaf'] ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    // 'Belum ada Transaksi',
                    bahasa['belum_ada_transaksi'] ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
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
}