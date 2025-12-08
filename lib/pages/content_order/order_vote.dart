// ignore_for_file: must_be_immutable, deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/modal/detail_order_modal.dart';
import 'package:kreen_app_flutter/pages/vote/detail_vote.dart';
import 'package:kreen_app_flutter/pages/vote/waiting_order_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:http/http.dart' as http;

class OrderVote extends StatefulWidget {
  const OrderVote({super.key});

  @override
  State<OrderVote> createState() => _OrderVoteState();
}

class _OrderVoteState extends State<OrderVote> with SingleTickerProviderStateMixin{

  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
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

  List<Map<String, dynamic>> votesSukses = [];
  List<Map<String, dynamic>> votesPending = [];
  List<Map<String, dynamic>> votesGagal = [];
  
  Future<void> _loadContent() async {

    var getUser = await StorageService.getUser();
    var email = getUser['email'];

    var resultSuccess = await ApiService.get('/order/vote?email_voter=$email&status=success&sort_by=terbaru&type_data=new');
    var resultPending = await ApiService.get('/order/vote?email_voter=$email&status=pending&sort_by=terbaru&type_data=new');
    var resultFail = await ApiService.get('/order/vote?email_voter=$email&status=fail&sort_by=terbaru&type_data=new');

    var tempSuccess = resultSuccess?['data'];
    var tempPending = resultPending?['data'];
    var tempFail = resultFail?['data'];

    List<Map<String, dynamic>> tempVotesSukses = [];
    List<Map<String, dynamic>> tempVotesPending = [];
    List<Map<String, dynamic>> tempVotesGagal = [];

    for (var ordersukses in tempSuccess) {
      final idOrder = ordersukses['id_order'];
      if (idOrder == null || idOrder.toString().isEmpty) continue;

      final resultOrder = await ApiService.get("/order/vote/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};
      final tempVoteSukses = tempOrder['vote'] ?? {};
      final tempVoteOrder = tempOrder['vote_order'] ?? {};

      tempVotesSukses.add({
        'id_order': idOrder,
        'judul_vote': tempVoteSukses['judul_vote'] ?? '-',
        'order_status': tempVoteOrder['order_status'],
        'tanggal': ordersukses['created_at'] ?? '-',
        'banner': tempVoteSukses['banner_vote'],
        'id_vote': tempVoteSukses['id_vote'],
      });
    }

    for (var orderpending in tempPending) {
      final idOrder = orderpending['id_order'];
      if (idOrder == null || idOrder.toString().isEmpty) continue;

      final resultOrder = await ApiService.get("/order/vote/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};
      final tempVotePending = tempOrder['vote'] ?? {};
      final tempVoteOrder = tempOrder['vote_order'] ?? {};

      tempVotesPending.add({
        'id_order': idOrder,
        'judul_vote': tempVotePending['judul_vote'] ?? '-',
        'order_status': tempVoteOrder['order_status'],
        'tanggal': orderpending['created_at'] ?? '-',
        'banner': tempVotePending['banner_vote'],
        'id_vote': tempVotePending['id_vote'],
      });
    }

    for (var ordergagal in tempFail) {
      final idOrder = ordergagal['id_order'];
      if (idOrder == null || idOrder.toString().isEmpty) continue;

      final resultOrder = await ApiService.get("/order/vote/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};
      final tempVoteGagal = tempOrder['vote'] ?? {};
      final tempVoteOrder = tempOrder['vote_order'] ?? {};

      tempVotesGagal.add({
        'id_order': idOrder,
        'judul_vote': tempVoteGagal['judul_vote'] ?? '-',
        'order_status': tempVoteOrder['order_status'],
        'tanggal': ordergagal['created_at'] ?? '-',
        'banner': tempVoteGagal['banner_vote'],
        'id_vote': tempVoteGagal['id_vote'],
      });
    }

    setState(() {
      orderSuccess = tempSuccess;
      votesSukses = tempVotesSukses;

      orderPending = tempPending;
      votesPending = tempVotesPending;

      orderFail = tempFail;
      votesGagal = tempVotesGagal;

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.red,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.check_circle_outline), text: "Selesai"),
              Tab(icon: Icon(Icons.access_time), text: "Menunggu"),
              Tab(icon: Icon(Icons.close_rounded), text: "Gagal"),
            ],
          ),
        ),
        
        Expanded(
          child: isLoading
                ? _buildSkeletonLoader()
                : TabBarView(
              controller: _tabController,
              physics: NeverScrollableScrollPhysics(),
              children: [

                orderSuccess.isNotEmpty
                  ? VoteSuccess(orderSuccess: orderSuccess, votes: votesSukses,)
                  : NoOrder(),

                orderPending.isNotEmpty
                  ? VotePending(orderPending: orderPending, votes: votesPending)
                  : NoOrder(),

                orderFail.isNotEmpty
                  ? VoteFail(orderFail: orderFail, votes: votesGagal)
                  : NoOrder(),

              ],
            ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
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

class VoteSuccess extends StatefulWidget {
  List<dynamic> orderSuccess;
  List<Map<String, dynamic>> votes;
  VoteSuccess({super.key,  required this.orderSuccess, required this.votes});

  @override
  State<VoteSuccess> createState() => _VoteSuccessState();
}

class _VoteSuccessState extends State<VoteSuccess> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> orderSuccess = [];
  List<dynamic> votes = [];

  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;

  String langCode = 'id';

  final formatterNUmber = NumberFormat.decimalPattern("id_ID");
  String statusOrder = '';

  @override
  void initState() {
    super.initState();
    
    orderSuccess = List.from(widget.orderSuccess);
    votes = List.from(widget.votes);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreOrders();
      }
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
    var email = getUser['email'] ?? '';

    final url =
        "$baseapiUrl/order/vote?email_voter=$email&status=success&sort_by=terbaru&current_page=$currentPage&type_data=new";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
      },
    );

    List newVotes = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List newData = data['data'] ?? [];

      for (var ordersuccess in newData) {
        final idOrder = ordersuccess['id_order'];
        if (idOrder == null || idOrder.toString().isEmpty) continue;

        final resultOrder = await ApiService.get("/order/vote/$idOrder");
        final tempOrder = resultOrder?['data'] ?? {};
        final tempVoteSuccess = tempOrder['vote'] ?? {};
        final tempVoteOrder = tempOrder['vote_order'] ?? {};

        newVotes.add({
          'id_order': idOrder,
          'judul_vote': tempVoteSuccess['judul_vote'] ?? '-',
          'order_status': tempVoteOrder['order_status'],
          'tanggal': ordersuccess['created_at'] ?? '-',
          'banner': tempVoteSuccess['banner_vote'],
          'id_vote': tempVoteSuccess['id_vote'],
        });
      }

      setState(() {
        if (loadMore) {
          orderSuccess.addAll(newData);
          votes.addAll(newVotes);
        } else {
          orderSuccess = newData;
          votes = newVotes;
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
              final itemVotes = votes[index];

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
              var price = formatterNUmber.format(item['price'] + item['fees']);
              
              if (itemVotes['order_status'] == '0'){
                statusOrder = 'gagal';
              } else if (itemVotes['order_status'] == '1'){
                statusOrder = 'selesai';
              } else if (itemVotes['order_status'] == '2'){
                statusOrder = 'batal';
              } else if (itemVotes['order_status'] == '3'){
                statusOrder = 'menunggu';
              } else if (itemVotes['order_status'] == '4'){
                statusOrder = 'refund';
              } else if (itemVotes['order_status'] == '20'){
                statusOrder = 'expired';
              } else if (itemVotes['order_status'] == '404'){
                statusOrder = 'hidden';
              }

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
                                color: (itemVotes['order_status'] == '0')
                                          ? Colors.red.shade50
                                          : (itemVotes['order_status'] == '1')
                                                ? Colors.green.shade50
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red.shade50
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange.shade50
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red.shade50
                                                      : (itemVotes['order_status'] == '20')
                                                        ? Colors.red.shade50
                                                        : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (itemVotes['order_status'] == '0')
                                          ? Colors.red
                                          : (itemVotes['order_status'] == '1')
                                                ? Colors.green
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemVotes['order_status'] == '20')
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
                                      color: (itemVotes['order_status'] == '0')
                                              ? Colors.red
                                              : (itemVotes['order_status'] == '1')
                                                ? Colors.green
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemVotes['order_status'] == '20')
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
                              height: 70,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  itemVotes['banner'],
                                  height: 70,
                                  width: 70,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/img_broken.jpg',
                                      height: 70,
                                      width: 70,
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 8,),

                            Expanded( // penting agar tdk overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemVotes['judul_vote'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$qty vote"
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'] == 0
                                    ? 'Gratis'
                                    : "${item['currency']} $price",
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailVotePage(id_event: itemVotes['id_vote'].toString()),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                      "Vote Lagi",
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
                                  await DetailOrderModal.show(context, itemVotes['id_order']);
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
                ),
              );

            } else {
              if (isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Colors.red,)),
                );
              } else if (!hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Tidak ada data lagi",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
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

class VotePending extends StatefulWidget {
  List<dynamic> orderPending;
  List<Map<String, dynamic>> votes;
  VotePending({super.key,  required this.orderPending, required this.votes});

  @override
  State<VotePending> createState() => _VotePendingState();
}

class _VotePendingState extends State<VotePending> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> orderPending = [];
  List<dynamic> votes = [];

  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;

  String langCode = 'id';

  final formatterNUmber = NumberFormat.decimalPattern("id_ID");
  String statusOrder = '';

  @override
  void initState() {
    super.initState();
    
    orderPending = List.from(widget.orderPending);
    votes = List.from(widget.votes);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreOrders();
      }
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
    var email = getUser['email'] ?? '';

    final url =
        "$baseapiUrl/order/vote?email_voter=$email&status=pending&sort_by=terbaru&current_page=$currentPage&type_data=new";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
      },
    );

    List newVotes = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List newData = data['data'] ?? [];

      for (var orderpending in newData) {
        final idOrder = orderpending['id_order'];
        if (idOrder == null || idOrder.toString().isEmpty) continue;

        final resultOrder = await ApiService.get("/order/vote/$idOrder");
        final tempOrder = resultOrder?['data'] ?? {};
        final tempVotePending = tempOrder['vote'] ?? {};
        final tempVoteOrder = tempOrder['vote_order'] ?? {};

        newVotes.add({
          'id_order': idOrder,
          'judul_vote': tempVotePending['judul_vote'] ?? '-',
          'order_status': tempVoteOrder['order_status'],
          'tanggal': orderpending['created_at'] ?? '-',
          'banner': tempVotePending['banner_vote'],
          'id_vote': tempVotePending['id_vote'],
        });
      }

      setState(() {
        if (loadMore) {
          orderPending.addAll(newData);
          votes.addAll(newVotes);
        } else {
          orderPending = newData;
          votes = newVotes;
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
              final itemVotes = votes[index];

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
              var price = formatterNUmber.format(item['price'] + item['fees']);
              
              if (itemVotes['order_status'] == '0'){
                statusOrder = 'gagal';
              } else if (itemVotes['order_status'] == '1'){
                statusOrder = 'selesai';
              } else if (itemVotes['order_status'] == '2'){
                statusOrder = 'batal';
              } else if (itemVotes['order_status'] == '3'){
                statusOrder = 'menunggu';
              } else if (itemVotes['order_status'] == '4'){
                statusOrder = 'refund';
              } else if (itemVotes['order_status'] == '20'){
                statusOrder = 'expired';
              } else if (itemVotes['order_status'] == '404'){
                statusOrder = 'hidden';
              }

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
                                color: (itemVotes['order_status'] == '0')
                                          ? Colors.red.shade50
                                          : (itemVotes['order_status'] == '1')
                                                ? Colors.green.shade50
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red.shade50
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange.shade50
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red.shade50
                                                      : (itemVotes['order_status'] == '20')
                                                        ? Colors.red.shade50
                                                        : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (itemVotes['order_status'] == '0')
                                          ? Colors.red
                                          : (itemVotes['order_status'] == '1')
                                                ? Colors.green
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemVotes['order_status'] == '20')
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
                                      color: (itemVotes['order_status'] == '0')
                                              ? Colors.red
                                              : (itemVotes['order_status'] == '1')
                                                ? Colors.green
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemVotes['order_status'] == '20')
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
                              height: 70,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  itemVotes['banner'],
                                  height: 70,
                                  width: 70,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/img_broken.jpg',
                                      height: 70,
                                      width: 70,
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 8,),

                            Expanded( // penting agar tdk overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemVotes['judul_vote'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$qty vote"
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'] == 0
                                    ? 'Gratis'
                                    : "${item['currency']} $price",
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => WaitingOrderPage(id_order: itemVotes['id_order'])),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                      "Kembali ke Pembayaran",
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
                                  await DetailOrderModal.show(context, itemVotes['id_order']);
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
                ),
              );

            } else {
              if (isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Colors.red,)),
                );
              } else if (!hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Tidak ada data lagi",
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



class VoteFail extends StatefulWidget {
  List<dynamic> orderFail;
  List<Map<String, dynamic>> votes;
  VoteFail({super.key, required this.orderFail, required this.votes});

  @override
  State<VoteFail> createState() => _VoteFailState();
}

class _VoteFailState extends State<VoteFail> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> orderFail = [];
  List<dynamic> votes = [];

  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;

  String langCode = 'id';

  final formatterNUmber = NumberFormat.decimalPattern("id_ID");
  String statusOrder = '';

  @override
  void initState() {
    super.initState();
    
    orderFail = List.from(widget.orderFail);
    votes = List.from(widget.votes);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _loadMoreOrders();
      }
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
    var email = getUser['email'] ?? '';

    final url =
        "$baseapiUrl/order/vote?email_voter=$email&status=fail&sort_by=terbaru&current_page=$currentPage&type_data=new";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "API-Secret-Key": "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=",
        "Accept": "application/json",
      },
    );

    List newVotes = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List newData = data['data'] ?? [];

      for (var ordergagal in newData) {
        final idOrder = ordergagal['id_order'];
        if (idOrder == null || idOrder.toString().isEmpty) continue;

        final resultOrder = await ApiService.get("/order/vote/$idOrder");
        final tempOrder = resultOrder?['data'] ?? {};
        final tempVoteGagal = tempOrder['vote'] ?? {};
        final tempVoteOrder = tempOrder['vote_order'] ?? {};

        newVotes.add({
          'id_order': idOrder,
          'judul_vote': tempVoteGagal['judul_vote'] ?? '-',
          'order_status': tempVoteOrder['order_status'],
          'tanggal': ordergagal['created_at'] ?? '-',
          'banner': tempVoteGagal['banner_vote'],
          'id_vote': tempVoteGagal['id_vote'],
        });
      }

      setState(() {
        if (loadMore) {
          orderFail.addAll(newData);
          votes.addAll(newVotes);
        } else {
          orderFail = newData;
          votes = newVotes;
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
              final itemVotes = votes[index];

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
              var price = formatterNUmber.format(item['price'] + item['fees']);
              
              if (itemVotes['order_status'] == '0'){
                statusOrder = 'gagal';
              } else if (itemVotes['order_status'] == '1'){
                statusOrder = 'selesai';
              } else if (itemVotes['order_status'] == '2'){
                statusOrder = 'batal';
              } else if (itemVotes['order_status'] == '3'){
                statusOrder = 'menunggu';
              } else if (itemVotes['order_status'] == '4'){
                statusOrder = 'refund';
              } else if (itemVotes['order_status'] == '20'){
                statusOrder = 'expired';
              } else if (itemVotes['order_status'] == '404'){
                statusOrder = 'hidden';
              }

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
                                color: (itemVotes['order_status'] == '0')
                                          ? Colors.red.shade50
                                          : (itemVotes['order_status'] == '1')
                                                ? Colors.green.shade50
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red.shade50
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange.shade50
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red.shade50
                                                      : (itemVotes['order_status'] == '20')
                                                        ? Colors.red.shade50
                                                        : Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (itemVotes['order_status'] == '0')
                                          ? Colors.red
                                          : (itemVotes['order_status'] == '1')
                                                ? Colors.green
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemVotes['order_status'] == '20')
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
                                      color: (itemVotes['order_status'] == '0')
                                              ? Colors.red
                                              : (itemVotes['order_status'] == '1')
                                                ? Colors.green
                                                : (itemVotes['order_status'] == '2') 
                                                  ? Colors.red
                                                  : (itemVotes['order_status'] == '3') 
                                                    ? Colors.orange
                                                    : (itemVotes['order_status'] == '4')
                                                      ? Colors.red
                                                      : (itemVotes['order_status'] == '20')
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
                              height: 70,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  itemVotes['banner'],
                                  height: 70,
                                  width: 70,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/img_broken.jpg',
                                      height: 70,
                                      width: 70,
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 8,),

                            Expanded( // penting agar tdk overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemVotes['judul_vote'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$qty vote"
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'] == 0
                                    ? 'Gratis'
                                    : "${item['currency']} $price",
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailVotePage(id_event: itemVotes['id_vote'].toString()),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Ulangi Pembelian",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  await DetailOrderModal.show(context, itemVotes['id_order']);
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
                ),
              );

            } else {
              if (isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Colors.red,)),
                );
              } else if (!hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Tidak ada data lagi",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
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
              border: Border.all(color: Colors.grey.shade300,),
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
                      height: 220,
                    )
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Belum ada Transaksi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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