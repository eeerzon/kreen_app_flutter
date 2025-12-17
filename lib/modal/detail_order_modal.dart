// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailOrderModal {
  static Future<void> show(BuildContext context, String idOrder) async {
    final formatter = NumberFormat.decimalPattern("id_ID");

    Map<String, dynamic> voteOder = {};
    List<dynamic> voteOrderDetail = [];
    List<dynamic> finalis = [];
    Map<String, dynamic> vote = {};
    String? statusOrder;
    bool isLoading = true;

    String? langCode;

    Map<String, dynamic> paymentLang = {};
    Map<String, dynamic> voteLang = {};

    Future <void> getBahasa() async {
      langCode = await StorageService.getLanguage();

      paymentLang = await LangService.getJsonData(langCode!, "payment");
      voteLang = await LangService.getJsonData(langCode!, "detail_vote");

      isLoading = false;
    }

    Future<void> loadOrder() async {
      final resultOrder = await ApiService.get("/order/vote/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};

      final tempVoteOrder = tempOrder['vote_order'] ?? {};
      final tempVoteOrderDetail = tempOrder['vote_order_detail'] ?? [];
      final tempFinalis = tempOrder['vote_finalis'] ?? [];

      final tempVote = tempOrder['vote'] ?? {};

      voteOder = tempVoteOrder;
      voteOrderDetail = tempVoteOrderDetail;
      finalis = tempFinalis;

      vote = tempVote;
      
      if (voteOder['order_status'] == '0'){
        statusOrder = paymentLang['status_order_0'] ?? ""; // 'gagal';
      } else if (voteOder['order_status'] == '1'){
        statusOrder = paymentLang['status_order_1'] ?? ""; // 'selesai';
      } else if (voteOder['order_status'] == '2'){
        statusOrder = paymentLang['status_order_2'] ?? ""; // 'batal';
      } else if (voteOder['order_status'] == '3'){
        statusOrder = paymentLang['status_order_3'] ?? ""; // 'menunggu';
      } else if (voteOder['order_status'] == '4'){
        statusOrder = paymentLang['status_order_4'] ?? ""; // 'refund';
      } else if (voteOder['order_status'] == '20'){
        statusOrder = paymentLang['status_order_20'] ?? ""; // 'expired';
      } else if (voteOder['order_status'] == '404'){
        statusOrder = paymentLang['status_order_404'] ?? ""; // 'hidden';
      }
    }

    Widget buildSkeleton() {
      return SafeArea(
        child: SingleChildScrollView(
          padding: kGlobalPadding,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detail Order",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                Container(
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
                ),

                const SizedBox(height: 16),
                Container(
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
                ),

                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Table(
                    columnWidths: {
                      0: IntrinsicColumnWidth(),
                      1: FixedColumnWidth(20),
                      2: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // Row 1
                      TableRow(children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const Text(' :  '),
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ]),
                      const TableRow(children: [
                        SizedBox(height: 12),
                        SizedBox(height: 12),
                        SizedBox(height: 12),
                      ]),
                      // Row 2
                      TableRow(children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const Text(' :  '),
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                )
              ],
            ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final url = vote['banner_vote']?.toString() ?? '';
        final hasValidUrl = url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true && (url.startsWith('http://') || url.startsWith('https://'));
        if (hasValidUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await precacheImage(NetworkImage(url), context);
          });
        }
        return StatefulBuilder(
          builder: (context, setState) {
            final url = vote['banner_vote']?.toString() ?? '';
            final hasValidUrl = url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true && (url.startsWith('http://') || url.startsWith('https://'));

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (isLoading) {
                await getBahasa();
                await loadOrder();
                if (hasValidUrl) {
                  await precacheImage(NetworkImage(url), context);
                }
                setState(() {
                  isLoading = false;
                });
              }
            });

            return isLoading ? buildSkeleton() : SafeArea(
              child: SingleChildScrollView(
                padding: kGlobalPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Detail Order",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (voteOder['order_status'] == '0')
                                ? Colors.red.shade50
                                : (voteOder['order_status'] == '1')
                                    ? Colors.green.shade50
                                    : (voteOder['order_status'] == '2')
                                        ? Colors.red.shade50
                                        : (voteOder['order_status'] == '3')
                                            ? Colors.orange.shade50
                                            : (voteOder['order_status'] == '4')
                                                ? Colors.red.shade50
                                                : (voteOder['order_status'] == '20')
                                                    ? Colors.red.shade50
                                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (voteOder['order_status'] == '0')
                                  ? Colors.red
                                  : (voteOder['order_status'] == '1')
                                      ? Colors.green
                                      : (voteOder['order_status'] == '2')
                                          ? Colors.red
                                          : (voteOder['order_status'] == '3')
                                              ? Colors.orange
                                              : (voteOder['order_status'] == '4')
                                                  ? Colors.red
                                                  : (voteOder['order_status'] == '20')
                                                      ? Colors.red
                                                      : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusOrder!,
                            style: TextStyle(
                              color: (voteOder['order_status'] == '0')
                                  ? Colors.red
                                  : (voteOder['order_status'] == '1')
                                      ? Colors.green
                                      : (voteOder['order_status'] == '2')
                                          ? Colors.red
                                          : (voteOder['order_status'] == '3')
                                              ? Colors.orange
                                              : (voteOder['order_status'] == '4')
                                                  ? Colors.red
                                                  : (voteOder['order_status'] == '20')
                                                      ? Colors.red
                                                      : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(),

                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
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
                                    child: hasValidUrl
                                      ? Image.network(
                                          url,
                                          height: 70,
                                          width: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/img_broken.jpg',
                                              height: 70,
                                              width: 70,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          'assets/images/img_broken.jpg',
                                          height: 70,
                                          width: 70,
                                          fit: BoxFit.cover,
                                        )
                                  ),
                                ),

                                const SizedBox(width: 8,),

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
                                      const SizedBox(height: 4),
                                      Text(
                                        "${vote['nama_penyelenggara'] ?? '-'}",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        voteOder['total_amount'] == 0
                                        ? voteLang['harga_detail'] ?? "" //'Gratis'
                                        : "${voteOder['currency_vote']} ${formatter.format(voteOder['total_amount'])}",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      voteLang['finalis'] ?? "",
                    ),

                    SizedBox(height: 8,),
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
                              border: Border.all(color: Colors.grey.shade300),
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
                                        height: 70,
                                        width: 70,
                                      )
                                    : Image.asset(
                                        'assets/images/img_broken.jpg',
                                        height: 70,
                                        width: 70,
                                        fit: BoxFit.cover,
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
                                        "${formatter.format(voteOrderDetail[index]['qty'])} ${voteLang['text_vote']}",
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

                    if (voteOder['total_amount'] != 0) ... {
                      const SizedBox(height: 16),
                      Text(
                        paymentLang['pembayaran'] ?? "", //'Pembayaran',
                      ),

                      SizedBox(height: 8,),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Table(
                          columnWidths: {
                            0: IntrinsicColumnWidth(),
                            1: FixedColumnWidth(20),
                            2: FlexColumnWidth(),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(children: [
                              const Text('ID Order', style: TextStyle(color: Colors.grey),),
                              const Text(' :  '),
                              Text(
                                voteOder['id_order'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]),
                            const TableRow(children: [
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                            ]),
                            TableRow(children: [
                              Text(voteLang['harga'] ?? "", style: TextStyle(color: Colors.grey),),
                              const Text(' :  '),
                              Text(
                                "${voteOder['currency_vote']} ${formatter.format(voteOder['total_amount'])}",
                                style: TextStyle(fontWeight: FontWeight.bold),),
                            ]),
                            const TableRow(children: [
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                            ]),
                            TableRow(children: [
                              Text(paymentLang['metode_pembayaran'] ?? "", style: TextStyle(color: Colors.grey),),
                              const Text(' :  '),
                              Text(
                                voteOder['payment_method_name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    }
                  ]
                )
              ),
            );
          }
        );
      }
    );
  }


  static Future<void> showEvent(BuildContext context, String idOrder, bool isSukses) async {
    final formatter = NumberFormat.decimalPattern("id_ID");
    
    Map<String, dynamic> eventOder = {};
    List<dynamic> eventOrderDetail = [];
    List<dynamic> eventTiket = [];
    Map<String, dynamic> event = {};
    String? statusOrder, dateshow, maxend, formattedDate;
    bool isLoading = true;

    String? langCode;

    Map<String, dynamic> paymentLang = {};
    Map<String, dynamic> voteLang = {};
    Map<String, dynamic> eventLang = {};

    Future <void> getBahasa() async {
      langCode = await StorageService.getLanguage();

      paymentLang = await LangService.getJsonData(langCode!, "payment");
      voteLang = await LangService.getJsonData(langCode!, "detail_vote");
      eventLang = await LangService.getJsonData(langCode!, "event");

      isLoading = false;
    }

    String formatTime(String time) {
      final t = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("HH:mm").format(t);
    }
    

    Future<void> loadOrder() async {
      final resultOrder = await ApiService.get("/order/event/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};

      final tempEventOrder = tempOrder['event_order'] ?? {};
      final tempEventOrderDetail = tempOrder['event_order_detail'] ?? [];
      final tempEventTiket = tempOrder['event_ticket'] ?? [];

      final tempEvent = tempOrder['event'] ?? {};

      eventOder = tempEventOrder;
      eventOrderDetail = tempEventOrderDetail;
      eventTiket = tempEventTiket;

      event = tempEvent;

      final body = {
        "id_event": event['id_event'],
      };

      final resultEvent = await ApiService.post('/event/detail', body: body);
      final Map<String, dynamic> tempEventDetail = resultEvent?['data'] ?? {};

      dateshow = tempEventDetail['eventdate'][0]['dateshow'];
      maxend = formatTime(tempEventDetail['eventdate'][0]['maxend']).toString();

      final dateStr = tempEventDetail['eventdate'][0]['date_event']?.toString() ?? '-';
      
      if (dateStr.isNotEmpty) {
        try {
          // parsing string ke DateTime
          final date = DateTime.parse(dateStr); // pastikan format ISO (yyyy-MM-dd)
          if (langCode == 'id') {
            // Bahasa Indonesia
            final dayName = DateFormat("EEEE", "id_ID").format(date);
            formattedDate = dayName;
          } else {
            // Bahasa Inggris
            final dayName = DateFormat("EEEE", "en_US").format(date);
            formattedDate = dayName;
          }
        } catch (e) {
          formattedDate = '-';
        }
      }
      
      if (eventOder['order_status'] == '0'){
        statusOrder = paymentLang['status_order_0'] ?? ""; // 'gagal';
      } else if (eventOder['order_status'] == '1'){
        statusOrder = paymentLang['status_order_1'] ?? ""; // 'selesai';
      } else if (eventOder['order_status'] == '2'){
        statusOrder = paymentLang['status_order_2'] ?? ""; // 'batal';
      } else if (eventOder['order_status'] == '3'){
        statusOrder = paymentLang['status_order_3'] ?? ""; // 'menunggu';
      } else if (eventOder['order_status'] == '4'){
        statusOrder = paymentLang['status_order_4'] ?? ""; // 'refund';
      } else if (eventOder['order_status'] == '20'){
        statusOrder = paymentLang['status_order_20'] ?? ""; // 'expired';
      } else if (eventOder['order_status'] == '404'){
        statusOrder = paymentLang['status_order_404'] ?? ""; // 'hidden';
      }
    }

    Widget buildSkeleton() {
      return SafeArea(
        child: SingleChildScrollView(
          padding: kGlobalPadding,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detail Order",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                Container(
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
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300,),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: 20,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1.2, color: Colors.grey, height: 100),
                            const SizedBox(width: 12),

                            // Info Kolom
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      // QR Fake
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: 90,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (context, setState) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (isLoading) {
                await getBahasa();
                await loadOrder();
                setState(() {
                  isLoading = false;
                });
              }
            });
            return isLoading ? buildSkeleton() : SafeArea(
              child: SingleChildScrollView(
                padding: kGlobalPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Detail Order",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (eventOder['order_status'] == '0')
                                ? Colors.red.shade50
                                : (eventOder['order_status'] == '1')
                                    ? Colors.green.shade50
                                    : (eventOder['order_status'] == '2')
                                        ? Colors.red.shade50
                                        : (eventOder['order_status'] == '3')
                                            ? Colors.orange.shade50
                                            : (eventOder['order_status'] == '4')
                                                ? Colors.red.shade50
                                                : (eventOder['order_status'] == '20')
                                                    ? Colors.red.shade50
                                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (eventOder['order_status'] == '0')
                                  ? Colors.red
                                  : (eventOder['order_status'] == '1')
                                      ? Colors.green
                                      : (eventOder['order_status'] == '2')
                                          ? Colors.red
                                          : (eventOder['order_status'] == '3')
                                              ? Colors.orange
                                              : (eventOder['order_status'] == '4')
                                                  ? Colors.red
                                                  : (eventOder['order_status'] == '20')
                                                      ? Colors.red
                                                      : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusOrder!,
                            style: TextStyle(
                              color: (eventOder['order_status'] == '0')
                                  ? Colors.red
                                  : (eventOder['order_status'] == '1')
                                      ? Colors.green
                                      : (eventOder['order_status'] == '2')
                                          ? Colors.red
                                          : (eventOder['order_status'] == '3')
                                              ? Colors.orange
                                              : (eventOder['order_status'] == '4')
                                                  ? Colors.red
                                                  : (eventOder['order_status'] == '20')
                                                      ? Colors.red
                                                      : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(),

                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300,),
                      ),
                      child: Column(
                        children: [
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
                                      event['event_banner'],
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
                                        event['event_title'] ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // const SizedBox(height: 4),
                                      // Text(
                                      //   "${vote['nama_penyelenggara']}",
                                      //   style: TextStyle(color: Colors.grey),
                                      // ),
                                      const SizedBox(height: 4),
                                      Text(
                                        eventOder['amount'] == 0
                                        ? voteLang['harga_detail'] ?? "" //'Gratis'
                                        : "${eventOder['currency_event']} ${formatter.format(eventOder['amount'] + eventOder['fees'])}",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      paymentLang['informasi_tiket'] ?? "", // 'Informasi Tiket',
                    ),

                    SizedBox(height: 8,),
                    Column(
                      children: List.generate(eventTiket.length, (index) {
                        final item = eventTiket[index];

                        return Padding(
                          padding: EdgeInsets.only(bottom: index == eventTiket.length - 1 ? 0 : 16),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300,),
                                ),
                                child: Row(
                                  children: [
                                    // Kiri: Barcode dan info tiket
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SvgPicture.network(
                                            "$baseUrl/image/barcode.svg",
                                            fit: BoxFit.fitHeight,
                                            width: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Container(width: 1.2, color: Colors.grey,height: 100,),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${paymentLang['tiket']} ${index + 1} ${item['ticket_name']}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(eventOrderDetail[index]['ticket_buyer_name']),
                                                const SizedBox(height: 8),
                                                Text(
                                                  eventOrderDetail[index]['ticket_buyer_email'],
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(eventOrderDetail[index]['ticket_buyer_phone']),
                                                const SizedBox(height: 8),
                                                Text(
                                                  // berlaku hingga
                                                  '${eventLang['expired_at']} \n$formattedDate $dateshow \n$maxend',
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Kanan: QR code
                                    if (isSukses)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                _showQrFullscreen(
                                                  context,
                                                  'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${eventOrderDetail[index]['id_order_detail']}',
                                                );
                                              },
                                              child: Image.network(
                                                'https://api.qrserver.com/v1/create-qr-code/?size=70x70&data=${eventOrderDetail[index]['id_order_detail']}',
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 4),
                                            Text(
                                              eventOrderDetail[index]['id_order_detail'],
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 8,),
                              Divider(),
                              SizedBox(height: 10,),
                              Padding(
                                padding: EdgeInsets.only(bottom: index == eventTiket.length - 1 ? 0 : 20),
                                child: Table(
                                  columnWidths: {
                                    0: IntrinsicColumnWidth(),
                                    1: FixedColumnWidth(20),
                                    2: FlexColumnWidth(),
                                  },
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: eventOrderDetail[index]['order_form_answers'].map<TableRow>((answer) {
                                    bool isFile = answer["type_form"] == "file";

                                    return TableRow(children: [
                                      Text(answer["question"], style: const TextStyle(color: Colors.grey)),
                                      const Text(" : "),
                                      isFile
                                          ? GestureDetector(
                                              onTap: () {
                                                final url = answer['answer'];
                                                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                              },
                                              child: Text(
                                                eventLang['lihat_file'] ?? "", //"Lihat File",
                                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          : Text(answer["answer"], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    if (eventOder['order_status'] == '3') ... [
                      const SizedBox(height: 16),
                      Text(
                        paymentLang['detail_pembayaran'] ?? "", //'Detail Pembayaran',
                      ),

                      SizedBox(height: 8,),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300,),
                        ),
                        child: Table(
                          columnWidths: {
                            0: IntrinsicColumnWidth(),
                            1: FixedColumnWidth(20),
                            2: FlexColumnWidth(),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(children: [
                              const Text('ID Order', style: TextStyle(color: Colors.grey),),
                              const Text(' :  '),
                              Text(
                                eventOder['id_order'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]),
                            const TableRow(children: [
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                            ]),
                            TableRow(children: [
                              Text(voteLang['harga'] ?? "", style: TextStyle(color: Colors.grey),),
                              const Text(' :  '),
                              Text(
                                "${eventOder['currency_event']} ${formatter.format(eventOder['amount'] + eventOder['fees'])}",
                                style: TextStyle(fontWeight: FontWeight.bold),),
                            ]),
                            const TableRow(children: [
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                              SizedBox(height: 8),
                            ]),
                            TableRow(children: [
                              Text(paymentLang['metode_pembayaran'] ?? "", style: TextStyle(color: Colors.grey),),
                              const Text(' :  '),
                              Text(
                                eventOder['payment_method_name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ]
                  ]
                )
              ),
            );
          }
        );
      }
    );
  }

  static Future<void> _showQrFullscreen(BuildContext context, String url) async {
    double currentBrightness = await ScreenBrightness().current;

    // set brightness MAX
    await ScreenBrightness().setScreenBrightness(1.0);

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3,
                child: Image.network(
                  url,
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );

    // restore brightness
    await ScreenBrightness().setScreenBrightness(currentBrightness);
  }

}