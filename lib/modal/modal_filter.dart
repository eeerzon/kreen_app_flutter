// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

class ModalFilter {
  static Future<Map<String, List<String>>?> show(
    BuildContext context,
    String langCode,
    List<String> initialTime,
    List<String> initialPrice,
    int ititialPage,
    {
      required int selectedIndex,
    }
  ) async {

    // copy agar tidak langsung mutate parent sebelum OK
    List<String> paramTime = List.from(initialTime);
    List<String> paramPrice = List.from(initialPrice);

    final bahasa = await LangService.getJsonData(langCode, "bahasa");

    final Map<String, String> timeLabels = {
      'this_week': bahasa['this_week'],
      'this_month': bahasa['this_month'],
      'next_month': bahasa['next_month'],
    };

    final Map<String, String> priceLabels = {
      'free': bahasa['harga_detail'],
      'paid': bahasa['berbayar'],
    };

    void toggleTime(String key, void Function(void Function()) setState) {
      setState(() {
        paramTime.contains(key)
            ? paramTime.remove(key)
            : paramTime.add(key);
      });
    }

    void togglePrice(String key, void Function(void Function()) setState) {
      setState(() {
        paramPrice.contains(key)
            ? paramPrice.remove(key)
            : paramPrice.add(key);
      });
    }

    final String timeTitle =
      selectedIndex == 0 // 0 = All
        ? "${bahasa['time_event']}/Grand Final"
        : selectedIndex == 1 // 1 = Vote
          ? "Grand Final"
          : bahasa['time_event'];


    return await showModalBottomSheet<Map<String, List<String>>>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: kGlobalPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                        // IconButton(
                        //   icon: Icon(Icons.close),
                        //   onPressed: () => Navigator.pop(context),
                        // ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              paramTime.clear();
                              paramPrice.clear();
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Divider(),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(timeTitle, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      children: timeLabels.keys.map((key) {
                        return InkWell(
                          onTap: () => toggleTime(key, setState),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(timeLabels[key] ?? key),
                              Checkbox(
                                value: paramTime.contains(key),
                                onChanged: (_) => toggleTime(key, setState),
                                activeColor: Colors.red,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    Divider(),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(bahasa['harga'], style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Column(
                      children: priceLabels.keys.map((key) {
                        return InkWell(
                          onTap: () => togglePrice(key, setState),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(priceLabels[key] ?? key),
                              Checkbox(
                                value: paramPrice.contains(key),
                                onChanged: (_) => togglePrice(key, setState),
                                activeColor: Colors.red,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),

                    // tombol apply
                    InkWell(
                      onTap: () {
                        Navigator.pop(context, {
                          'time': paramTime,
                          'price': paramPrice,
                        });
                      },
                      child: SizedBox(
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),
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