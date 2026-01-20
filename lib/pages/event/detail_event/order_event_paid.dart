// ignore_for_file: must_be_immutable, non_constant_identifier_names, prefer_typing_uninitialized_variables, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:shimmer/shimmer.dart';

class OrderEventPaid extends StatefulWidget {
  String idOrder;
  bool isSukses;
  OrderEventPaid({super.key, required this.idOrder, required this.isSukses});

  @override
  State<OrderEventPaid> createState() => _OrderEventPaidState();
}

class _OrderEventPaidState extends State<OrderEventPaid> {
  final formatter = NumberFormat.decimalPattern("en_US");
  String? langCode;
  bool _isLoading = true;

  Map<String, dynamic> detailOrder = {};
  Map<String, dynamic> eventOder = {};
  List<dynamic> eventOrderDetail = [];
  List<dynamic> eventTiket = [];
  Map<String, dynamic> paymentDetail = {};
  List<dynamic> instruction = [];
  Map<String, dynamic> event = {};
  String? statusOrder, dateshow, maxend, formattedDate, penyelenggara, venue_name;
  var qty, price;

  Map<String, dynamic> bahasa = {};

  Future<void> _loadOrder() async {

    final resultOrder = await ApiService.get("/order/event/${widget.idOrder}");
    final tempOrder = resultOrder?['data'] ?? {};

    final temp_event_order = tempOrder['event_order'] ?? {};
    final temp_event_order_detail = tempOrder['event_order_detail'] ?? [];
    final temp_event_tiket = tempOrder['event_ticket'] ?? [];

    final temp_payment_detail = tempOrder['payment_detail'] ?? {};
    final temp_instruction = temp_payment_detail['instruction'] ?? [];

    final temp_event = tempOrder['event'] ?? {};

    final body = {
      "id_event": temp_event['id_event'],
    };

    final resultEvent = await ApiService.post('/event/detail', body: body);
    final Map<String, dynamic> tempEventDetail = resultEvent?['data'] ?? {};

    if (mounted) {
      setState(() {
        detailOrder = tempOrder;

        eventOder = temp_event_order;
        eventOrderDetail = temp_event_order_detail;
        eventTiket = temp_event_tiket;

        paymentDetail = temp_payment_detail;
        instruction = temp_instruction;

        event = temp_event;

        dateshow = tempEventDetail['eventdate'][0]['dateshow'];
        maxend = tempEventDetail['eventdate'][0]['maxend'];
        penyelenggara = tempEventDetail['event']['organizer'];
        venue_name = tempEventDetail['event']['venue_name'];

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
          statusOrder = 'gagal';
        } else if (eventOder['order_status'] == '1'){
          statusOrder = 'selesai';
        } else if (eventOder['order_status'] == '2'){
          statusOrder = 'batal';
        } else if (eventOder['order_status'] == '3'){
          statusOrder = 'menunggu';
        } else if (eventOder['order_status'] == '4'){
          statusOrder = 'refund';
        } else if (eventOder['order_status'] == '20'){
          statusOrder = 'expired';
        } else if (eventOder['order_status'] == '404'){
          statusOrder = 'hidden';
        }

        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
      await _loadOrder();
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
    return Scaffold(
      body: _isLoading
          ? buildSkeleton()
          : buildKonten()
    );
  }

  Widget buildSkeleton() {
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
    return SafeArea(
      // backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   title: Text("test menu order"),
      //   centerTitle: false,
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back_ios),
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //   ),
      // ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: kGlobalPadding,
                children: [
                  Column(
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
                        //'Selamat... Pesananmu Berhasil',
                        bahasa['order_sukses'],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        //'Cek email kamu. Jika kamu tidak ketemu, jangan lupa cek SPAM atau PROMOSI.',
                        bahasa['order_sukses_desc'],
                        softWrap: true,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 16,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID: ${widget.idOrder}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              eventOder['amount'] == 0
                              ? bahasa['harga_detail'] //"Gratis"
                              : bahasa['berbayar'], // "Berbayar",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      Divider(),

                      SizedBox(height: 16,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                event['event_banner'],
                                height: 120,
                                width: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/img_broken.jpg',
                                    height: 120,
                                    width: 120,
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
                                  event['event_title'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      //'Diselenggarakan Oleh: ',
                                      "${bahasa['penyelenggara']}: ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      penyelenggara ?? '-',
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
                                            '$formattedDate $dateshow, $maxend'
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
                                            '${bahasa['lokasi']}: ${venue_name ?? '-'}',
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
                        ],
                      ),
                                
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          //"Total Pembayaran",
                          bahasa['total_pembayaran'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                                
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          eventOder['amount'] == 0
                          ? bahasa['harga_detail'] //"Gratis"
                          : "${eventOder['currency_event']} ${formatter.format(eventOder['amount'] + eventOder['fees'])}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),

                      SizedBox(height: 20,),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300,),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue,),
                            SizedBox(width: 12,),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(text: bahasa['warning_order_1']), //"QR Code digunakan untuk akses masuk. ",
                                      TextSpan(
                                        text: bahasa['warning_order_2'], //"Screenshot QR Code ",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: bahasa['warning_order_3']), //" atau pastikan "
                                      TextSpan(
                                        text: "E-Ticket",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: bahasa['warning_order_4']), //" Anda sudah masuk di email."
                                    ],
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20,),
                      Column(
                        children: List.generate(eventTiket.length, (index) {
                          final item = eventTiket[index];

                          return Padding(
                            padding: EdgeInsets.only(bottom: index == eventTiket.length - 1 ? 0 : 20),
                            child: Container(
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
                                        Container(width: 1.2, color: Colors.grey.shade200),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${bahasa['tiket']} ${index + 1} ${item['ticket_name']}',
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
                                                //"Berlaku hingga"
                                                '${bahasa['expired_at']} \n$formattedDate $dateshow \n$maxend',
                                                softWrap: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Kanan: QR code
                                  if (widget.isSukses)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Image.network(
                                            'https://api.qrserver.com/v1/create-qr-code/?size=70x70&data=${eventOrderDetail[index]['id_order_detail']}',
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.contain,
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
                          );
                        }),
                      ),


                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          bahasa['selesai'], //"Selesai",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ),
        ],
      ),
    );
  }
}