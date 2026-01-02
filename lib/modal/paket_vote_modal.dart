// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class PaketVoteModal {
  static Future<Map<String, dynamic>?> show(BuildContext context, int index, List<Map<String, dynamic>> paketTerbaik, List<Map<String, dynamic>> paketLainnya, Color color, Color bgColor, String? idPaketBw, String currency) async {
    int? selectedIndex, selectedVotes, counts;
    num? hargaGet;
    String? idPaket;

    final formatter = NumberFormat.decimalPattern("id_ID");
    bool isLoading = true;

    String? langCode;
    Map<String, dynamic> modalLang = {};

    Future <void> getBahasa() async {
      langCode = await StorageService.getLanguage();

      modalLang = await LangService.getJsonData(langCode!, "modal");
    }

    Widget buildSkeleton() {
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

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        
        return StatefulBuilder(
          builder: (context, setState) {

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (isLoading) {
                await getBahasa();
                setState(() {
                  isLoading = false;
                });
              }
            });

            return isLoading ? buildSkeleton() : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: kGlobalPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20,),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            modalLang["pilih_paket"] ?? "", // "Pilih Paket Vote",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(modalLang["pilih_paket_desc"] ?? ""), //"Silahkan pilih paket vote anda.."
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: ListView(
                          children: [
                            // SECTION 1 — Paket Terbaik
                            if (paketTerbaik.isNotEmpty) ...[
                              Text(
                                modalLang["paket_terbaik"] ?? "", //"Paket Terbaik buat kamu",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),

                              ...paketTerbaik.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;

                                final qty = int.tryParse(item['qty'].toString()) ?? 0;
                                final harga = double.tryParse(item['harga'].toString());
                                final hargaAkhir = double.tryParse(item['harga_akhir'].toString());
                                final diskon = int.tryParse(item['diskon_persen']?.toString() ?? '0') ?? 0;

                                final isSelected = selectedIndex == idx;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = idx;
                                      selectedVotes = qty;
                                      counts = qty;
                                      hargaGet = hargaAkhir;
                                      idPaket = item['id'];
                                    });
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? bgColor : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300,),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // kiri
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${NumberFormat.decimalPattern("id_ID").format(qty)} Vote",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (diskon > 0)
                                                Text(
                                                  "$diskon% OFF",
                                                  style: TextStyle(
                                                    color: Colors.green.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          // kanan
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              if (diskon > 0)
                                                Text(
                                                  "$currency ${formatter.format(harga)}",
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    decoration: TextDecoration.lineThrough,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              Text(
                                                "$currency ${formatter.format(hargaAkhir)}",
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],

                            // SECTION 2 — Paket Lainnya
                            if (paketLainnya.isNotEmpty) ...[
                              Text(
                                modalLang["paket_lainnya"] ?? "", //"Paket Lainnya",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),

                              ...paketLainnya.asMap().entries.map((entry) {
                                final idx = paketTerbaik.length + entry.key;
                                final item = entry.value;

                                final qty = int.tryParse(item['qty'].toString()) ?? 0;
                                final harga = double.tryParse(item['harga'].toString()) ?? 0;

                                final isSelected = selectedIndex == idx;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = idx;
                                      selectedVotes = qty;
                                      counts = qty;
                                      hargaGet = harga;
                                      idPaket = item['id'];
                                    });
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? bgColor : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300,),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${NumberFormat.decimalPattern("id_ID").format(qty)} Vote",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            "$currency ${formatter.format(harga)}",
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tombol
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (states) {
                                    if (states.contains(MaterialState.disabled)) {
                                      return Colors.grey;
                                    }
                                    return color;
                                  },
                                ),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              onPressed: selectedVotes == null
                                  ? null
                                  : () => Navigator.pop(context, {'id_paket': idPaket, 'counts': counts, 'harga': hargaGet,}),
                              child: Text(
                                modalLang['konfirmasi'] ?? "", // "Konfirmasi",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                modalLang['batal'] ?? "", //]"Cancel",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              )
            );
          },
        );
      },
    );
    return result;
  }
}
