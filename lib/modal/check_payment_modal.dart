// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/pages/order/order_event_paid.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class CheckPaymentModal {
  static Future<void> show(BuildContext context, String idOrder) async {
    final formatter = NumberFormat.decimalPattern("en_US");

    Map<String, dynamic> voteOrder = {};
    List<dynamic> voteOrderDetail = [];
    List<dynamic> voteFinalis = [];
    Map<String, dynamic> vote = {};
    String? statusOrder;

    String? langCode;
    Map<String, dynamic> bahasa = {};
    Future<void> getBahasa() async {
      langCode = await StorageService.getLanguage();

      bahasa = await LangService.getJsonData(langCode!, "bahasa");
    }

    Future<void> loadOrder() async {
      final resultOrder = await ApiService.get("/order/vote/$idOrder", xLanguage: langCode);
      if (resultOrder != null) {
        if (resultOrder['rc'] == 200) {
          final tempOrder = resultOrder['data'] ?? {};

          voteOrder = tempOrder['vote_order'] ?? {};
          voteOrderDetail = tempOrder['vote_order_detail'] ?? [];
          voteFinalis = tempOrder['vote_finalis'] ?? [];
          vote = tempOrder['vote'] ?? {};

          if (voteOrder['order_status'] == '0'){
            statusOrder = bahasa['status_order_0'];
          } else if (voteOrder['order_status'] == '1'){
            statusOrder = bahasa['status_order_1'];
          } else if (voteOrder['order_status'] == '2'){
            statusOrder = bahasa['status_order_2'];
          } else if (voteOrder['order_status'] == '3'){
            statusOrder = bahasa['status_order_3'];
          } else if (voteOrder['order_status'] == '4'){
            statusOrder = bahasa['status_order_4'];
          } else if (voteOrder['order_status'] == '20'){
            statusOrder = bahasa['status_order_20'];
          } else if (voteOrder['order_status'] == '404'){
            statusOrder = bahasa['status_order_404'];
          }
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.noHeader,
            animType: AnimType.topSlide,
            title: bahasa['maaf'],
            desc: bahasa['error'],
            btnOkOnPress: () {},
            btnOkColor: Colors.red,
            buttonsTextStyle: TextStyle(color: Colors.white),
            headerAnimationLoop: false,
            dismissOnTouchOutside: true,
            showCloseIcon: true,
          ).show();
        }
      }
    }

    await getBahasa();
    await loadOrder();

    String? currencyRegion;
    if (voteOrder['order_region'] == "EU"){
      currencyRegion = 'EUR';
    } else if (voteOrder['order_region'] == "ID"){
      currencyRegion = 'IDR';
    } else if (voteOrder['order_region'] == "PH"){
      currencyRegion = 'PHP';
    } else if (voteOrder['order_region'] == "SG"){
      currencyRegion = 'SGD';
    } else if (voteOrder['order_region'] == "US"){
      currencyRegion = 'USD';
    } else if (voteOrder['order_region'] == "TH"){
      currencyRegion = 'THB';
    } else if (voteOrder['order_region'] == "MY"){
      currencyRegion = 'MYR';
    } else if (voteOrder['order_region'] == "VN"){
      currencyRegion = 'VND';
    }

    num sumAmount = voteOrder['total_amount'] * voteOrder['currency_value_region'];
    num totalAmountPg = num.parse(sumAmount.toStringAsFixed(5)); // konversi ke double (num())
    if (currencyRegion == "IDR") {
      totalAmountPg = totalAmountPg.ceil();
    } else {
      totalAmountPg = (totalAmountPg * 100).ceil() / 100;
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
            return SafeArea(
              child: SingleChildScrollView(
                padding: kGlobalPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bahasa['info_pesanan'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Konten
                    Table(
                      columnWidths: {
                        0: IntrinsicColumnWidth(),
                        1: FixedColumnWidth(20),
                        2: FlexColumnWidth(),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text('Event'),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(' :  '),
                          ),
                          Text(
                            vote['judul_vote'] ?? '-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ]),
                        const TableRow(children: [
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                        ]),
                        TableRow(children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(bahasa['finalis']),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(' :  '),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: voteOrderDetail.map((detail) {
                              // cari finalis yang sesuai id_finalis-nya
                              final finalis = voteFinalis.firstWhere(
                                (f) => f['id_finalis'] == detail['id_finalis'],
                                orElse: () => {'nama_finalis': 'Tidak Diketahui'},
                              );

                              return Text(
                                "- ${finalis['nama_finalis']} (${detail['qty']} ${bahasa['text_vote']})",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              );
                            }).toList(),
                          ),
                        ]),
                        const TableRow(children: [
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                        ]),
                        TableRow(children: [
                          Text(bahasa['total_bayar']),
                          const Text(' :  '),
                          Text(
                            voteOrder.isNotEmpty
                                ? "$currencyRegion ${formatter.format(totalAmountPg)}"
                                : '-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ]),
                        const TableRow(children: [
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                        ]),
                        TableRow(children: [
                          Text(bahasa['status_pembayaran']),
                          const Text(' :  '),
                          Text(
                            statusOrder ?? '-',
                            style: TextStyle(
                              color: (voteOrder['order_status'] == '0')
                                      ? Colors.red
                                      : (voteOrder['order_status'] == '1')
                                        ? Colors.green
                                        : (voteOrder['order_status'] == '2') 
                                          ? Colors.red
                                          : (voteOrder['order_status'] == '3') 
                                            ? Colors.orange
                                            : (voteOrder['order_status'] == '4')
                                              ? Colors.red
                                              : (voteOrder['order_status'] == '20')
                                                ? Colors.red
                                                : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tombol refresh status
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        bahasa['check_status'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await loadOrder();
                        setState(() {});

                        if (voteOrder['order_status'] == '1') {
                          for (int i = 3; i > 0; i--) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${bahasa['redirect']} $i ${bahasa['second']}..."),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                            await Future.delayed(const Duration(seconds: 1));
                          }
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => AddSupportPage(id_vote: vote['id_vote'], id_order: voteOrder['id_order'], nama: voteOrder['voter_name'],)),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  static Future<void> showEvent(BuildContext context, String idOrder) async {
    final formatter = NumberFormat.decimalPattern("en_US");

    Map<String, dynamic> eventOrder = {};
    List<dynamic> eventOrderDetail = [];
    List<dynamic> eventTiket = [];
    Map<String, dynamic> event = {};
    String? statusOrder;

    String? langCode;
    Map<String, dynamic> bahasa = {};
    Future<void> getBahasa() async {
      langCode = await StorageService.getLanguage();

      bahasa = await LangService.getJsonData(langCode!, "bahasa");
    }

    Future<void> loadOrder() async {
      final resultOrder = await ApiService.get("/order/event/$idOrder", xLanguage: langCode);
      final tempOrder = resultOrder?['data'] ?? {};

      eventOrder = tempOrder['event_order'] ?? {};
      eventOrderDetail = tempOrder['event_order_detail'] ?? [];
      eventTiket = tempOrder['event_ticket'] ?? [];
      event = tempOrder['event'] ?? {};

      if (eventOrder['order_status'] == '0'){
        statusOrder = bahasa['status_order_0'];
      } else if (eventOrder['order_status'] == '1'){
        statusOrder = bahasa['status_order_1'];
      } else if (eventOrder['order_status'] == '2'){
        statusOrder = bahasa['status_order_2'];
      } else if (eventOrder['order_status'] == '3'){
        statusOrder = bahasa['status_order_3'];
      } else if (eventOrder['order_status'] == '4'){
        statusOrder = bahasa['status_order_4'];
      } else if (eventOrder['order_status'] == '20'){
        statusOrder = bahasa['status_order_20'];
      } else if (eventOrder['order_status'] == '404'){
        statusOrder = bahasa['status_order_404'];
      }
    }

    await getBahasa();
    await loadOrder();

    String? currencyRegion;
    if (eventOrder['order_region'] == "EU"){
      currencyRegion = 'EUR';
    } else if (eventOrder['order_region'] == "ID"){
      currencyRegion = 'IDR';
    } else if (eventOrder['order_region'] == "PH"){
      currencyRegion = 'PHP';
    } else if (eventOrder['order_region'] == "SG"){
      currencyRegion = 'SGD';
    } else if (eventOrder['order_region'] == "US"){
      currencyRegion = 'USD';
    } else if (eventOrder['order_region'] == "TH"){
      currencyRegion = 'THB';
    } else if (eventOrder['order_region'] == "MY"){
      currencyRegion = 'MYR';
    } else if (eventOrder['order_region'] == "VN"){
      currencyRegion = 'VND';
    }

    num sumAmount = (eventOrder['amount'] + eventOrder['fees']) * eventOrder['currency_value_region'];
    num totalAmountPg = num.parse(sumAmount.toStringAsFixed(5)); // konversi ke double (num())
    if (currencyRegion == "IDR") {
      totalAmountPg = totalAmountPg.ceil();
    } else {
      totalAmountPg = (totalAmountPg * 100).ceil() / 100;
    }

    await showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {

        final Map<String, Map<String, dynamic>> groupedTickets = {};

        for (var detail in eventOrderDetail) {
          final id = detail['id_event_ticket'];
          final ticket = eventTiket.firstWhere(
            (f) => f['id_event_ticket'] == id,
            orElse: () => {'ticket_name': 'Tidak Diketahui'},
          );

          if (groupedTickets.containsKey(id)) {
            groupedTickets[id]!['qty'] += 1;
          } else {
            groupedTickets[id] = {
              'ticket_name': ticket['ticket_name'],
              'qty': 1,
            };
          }
        }
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: kGlobalPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bahasa['info_pesanan'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Konten
                    Table(
                      columnWidths: {
                        0: IntrinsicColumnWidth(),
                        1: FixedColumnWidth(20),
                        2: FlexColumnWidth(),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text('Event'),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(' :  '),
                          ),
                          Text(
                            event['event_title'] ?? '-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ]),
                        const TableRow(children: [
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                        ]),
                        TableRow(children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(bahasa['tiket']),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(' :  '),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedTickets.values.map((tiket) {
                              return Text(
                                "- ${tiket['ticket_name']} ${tiket['qty']} x",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              );
                            }).toList(),
                          ),
                        ]),
                        const TableRow(children: [
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                        ]),
                        TableRow(children: [
                          Text(bahasa['total_bayar']),
                          const Text(' :  '),
                          Text(
                            eventOrder.isNotEmpty
                                ? "$currencyRegion ${formatter.format(totalAmountPg)}"
                                : '-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ]),
                        const TableRow(children: [
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                          SizedBox(height: 8),
                        ]),
                        TableRow(children: [
                          Text(bahasa['status_pembayaran']),
                          const Text(' :  '),
                          Text(
                            statusOrder ?? '-',
                            style: TextStyle(
                              color: (eventOrder['order_status'] == '0')
                                      ? Colors.red
                                      : (eventOrder['order_status'] == '1')
                                        ? Colors.green
                                        : (eventOrder['order_status'] == '2') 
                                          ? Colors.red
                                          : (eventOrder['order_status'] == '3') 
                                            ? Colors.orange
                                            : (eventOrder['order_status'] == '4')
                                              ? Colors.red
                                              : (eventOrder['order_status'] == '20')
                                                ? Colors.red
                                                : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tombol refresh status
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        bahasa['check_status'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await loadOrder();
                        setState(() {});

                        if (eventOrder['order_status'] == '1') {
                          for (int i = 3; i > 0; i--) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${bahasa['redirect']} $i ${bahasa['second']}..."),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                            await Future.delayed(const Duration(seconds: 1));
                          }
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (_) => OrderEventPaid(idOrder: eventOrder['id_order'], isSukses: true,)),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}