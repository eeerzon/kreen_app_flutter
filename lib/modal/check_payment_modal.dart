// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/pages/event/detail_event/order_event_paid.dart';
import 'package:kreen_app_flutter/pages/vote/add_support.dart';
import 'package:kreen_app_flutter/services/api_services.dart';

class CheckPaymentModal {
  static Future<void> show(BuildContext context, String idOrder) async {
    final formatter = NumberFormat.decimalPattern("id_ID");

    Map<String, dynamic> voteOrder = {};
    List<dynamic> voteOrderDetail = [];
    List<dynamic> voteFinalis = [];
    Map<String, dynamic> vote = {};
    String? statusOrder;

    Future<void> loadOrder() async {
      final resultOrder = await ApiService.get("/order/vote/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};

      voteOrder = tempOrder['vote_order'] ?? {};
      voteOrderDetail = tempOrder['vote_order_detail'] ?? [];
      voteFinalis = tempOrder['vote_finalis'] ?? [];
      vote = tempOrder['vote'] ?? {};

      if (voteOrder['order_status'] == '0'){
        statusOrder = 'gagal';
      } else if (voteOrder['order_status'] == '1'){
        statusOrder = 'selesai';
      } else if (voteOrder['order_status'] == '2'){
        statusOrder = 'batal';
      } else if (voteOrder['order_status'] == '3'){
        statusOrder = 'menunggu';
      } else if (voteOrder['order_status'] == '4'){
        statusOrder = 'refund';
      } else if (voteOrder['order_status'] == '20'){
        statusOrder = 'expired';
      } else if (voteOrder['order_status'] == '404'){
        statusOrder = 'hidden';
      }
    }

    await loadOrder(); // load pertama sebelum tampil

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
                        const Text(
                          "Informasi Pesanan",
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
                            child: Text('Nama Event'),
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
                            child: Text('Nama Finalis'),
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
                                "- ${finalis['nama_finalis']} (${detail['qty']}x)",
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
                          const Text('Total Pembayaran'),
                          const Text(' :  '),
                          Text(
                            voteOrder.isNotEmpty
                                ? "${voteOrder['currency_vote'] ?? 'Rp'} ${formatter.format(voteOrder['total_amount'] ?? 0)}"
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
                          const Text('Status Pembayaran'),
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
                      label: const Text(
                        "Check Status Pesanan",
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
                                content: Text("Redirect dalam $i detik..."),
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
    final formatter = NumberFormat.decimalPattern("id_ID");

    Map<String, dynamic> eventOrder = {};
    List<dynamic> eventOrderDetail = [];
    List<dynamic> eventTiket = [];
    Map<String, dynamic> event = {};
    String? statusOrder;

    Future<void> loadOrder() async {
      final resultOrder = await ApiService.get("/order/event/$idOrder");
      final tempOrder = resultOrder?['data'] ?? {};

      eventOrder = tempOrder['event_order'] ?? {};
      eventOrderDetail = tempOrder['event_order_detail'] ?? [];
      eventTiket = tempOrder['event_ticket'] ?? [];
      event = tempOrder['event'] ?? {};

      if (eventOrder['order_status'] == '0'){
        statusOrder = 'gagal';
      } else if (eventOrder['order_status'] == '1'){
        statusOrder = 'selesai';
      } else if (eventOrder['order_status'] == '2'){
        statusOrder = 'batal';
      } else if (eventOrder['order_status'] == '3'){
        statusOrder = 'menunggu';
      } else if (eventOrder['order_status'] == '4'){
        statusOrder = 'refund';
      } else if (eventOrder['order_status'] == '20'){
        statusOrder = 'expired';
      } else if (eventOrder['order_status'] == '404'){
        statusOrder = 'hidden';
      }
    }

    await loadOrder(); // load pertama sebelum tampil

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
                        const Text(
                          "Informasi Pesanan",
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
                            child: Text('Nama Event'),
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
                            child: Text('Tiket'),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Text(' :  '),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedTickets.values.map((tiket) {
                              return Text(
                                "- ${tiket['ticket_name']} ${tiket['qty']}x",
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
                          const Text('Total Pembayaran'),
                          const Text(' :  '),
                          Text(
                            eventOrder.isNotEmpty
                                ? "${eventOrder['currency_event'] ?? 'Rp'} ${formatter.format(eventOrder['amount'] + eventOrder['fees'])}"
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
                          const Text('Status Pembayaran'),
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
                      label: const Text(
                        "Check Status Pesanan",
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
                                content: Text("Redirect dalam $i detik..."),
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