// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';

class PaketVotePersenModal {
  static Future<void> show(BuildContext context) async {
    int? selectedIndex;

    final List<Map<String, dynamic>> paketTerbaik = [
      {
        "vote": 100,
        "hargaAsli": 200000,
        "hargaDiskon": 180000,
        "diskon": "Diskon 10%"
      },
      {
        "vote": 100,
        "hargaAsli": 200000,
        "hargaDiskon": 180000,
        "diskon": "Diskon 10%"
      },
    ];

    final List<Map<String, dynamic>> paketLainnya = [
      {"vote": 5, "harga": 10000},
      {"vote": 10, "harga": 20000},
      {"vote": 25, "harga": 50000},
      {"vote": 50, "harga": 100000},
      {"vote": 200, "harga": 400000},
    ];

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
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
                            "Pilih Paket Vote",
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
                        child: Text("Silahkan pilih paket vote anda.."),
                      ),
                      const SizedBox(height: 16),

                      // Paket Terbaik
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Paket Terbaik buat kamu",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...paketTerbaik.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var item = entry.value;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = idx),
                          child: Card(
                            color: selectedIndex == idx
                                ? Colors.green.shade50
                                : Colors.white,
                            child: ListTile(
                              leading: Radio<int>(
                                value: idx,
                                groupValue: selectedIndex,
                                onChanged: (val) {
                                  setState(() => selectedIndex = val);
                                },
                              ),
                              title: Text("${item['vote']} Vote"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Rp ${item['hargaAsli']}",
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${item['hargaDiskon']} - (${item['diskon']})",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Paket lainnya",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Paket Lainnya
                      ...paketLainnya.asMap().entries.map((entry) {
                        int idx = paketTerbaik.length + entry.key;
                        var item = entry.value;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = idx),
                          child: Card(
                            color: selectedIndex == idx
                                ? Colors.green.shade50
                                : Colors.white,
                            child: ListTile(
                              leading: Radio<int>(
                                value: idx,
                                groupValue: selectedIndex,
                                onChanged: (val) {
                                  setState(() => selectedIndex = val);
                                },
                              ),
                              title: Text("${item['vote']} Vote"),
                              subtitle: Text(
                                "Rp ${item['harga']}",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Tombol
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                
                              },
                              child: Text(
                                "Lanjutkan Pembayaran",
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
                                Navigator.pop(context, selectedIndex);
                              },
                              child: Text(
                                "Cancel",
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
  }
}
