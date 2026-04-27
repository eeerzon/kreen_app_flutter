// ignore_for_file: use_build_context_synchronously, deprecated_member_use, dead_code

import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';

class ModalFilterVote {
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

    List<String> paramTime = List.from(initialTime);
    List<String> paramPrice = List.from(initialPrice);
    
    final List<String> originalTime = List.from(initialTime);
    final List<String> originalPrice = List.from(initialPrice);

    int paramCount = paramTime.length + paramPrice.length;

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

    bool hasChangedFuction(List<String> time, List<String> price) {
      if (time.length != originalTime.length || price.length != originalPrice.length) return true;
      if (!time.every((e) => originalTime.contains(e))) return true;
      if (!price.every((e) => originalPrice.contains(e))) return true;
      return false;
    }

    void toggleTime(String key, void Function(void Function()) setState) {
      setState(() {
        paramTime.contains(key) ? paramTime.remove(key) : paramTime.add(key);
        paramCount = paramTime.length + paramPrice.length;
      });
    }

    void togglePrice(String key, void Function(void Function()) setState) {
      setState(() {
        paramPrice.contains(key) ? paramPrice.remove(key) : paramPrice.add(key);
        paramCount = paramTime.length + paramPrice.length;
      });
    }

    final String timeTitle =
      selectedIndex == 0
        ? "${bahasa['time_event']}/Grand Final"
        : selectedIndex == 1
          ? "Grand Final"
          : bahasa['time_event'];

    bool isSubmitting = false;

    return await showModalBottomSheet<Map<String, List<String>>>(
      context: context,
      isDismissible: false,
      enableDrag: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            final bool hasChanged = hasChangedFuction(paramTime, paramPrice);

            // Reset visible jika: ada filter aktif awal ATAU ada filter dipilih sekarang
            final bool showReset = paramCount > 0;

            // Apply bisa diklik jika ada perubahan
            // Kasus khusus: jika semua di-reset (paramCount==0) dari kondisi ada filter → tetap bisa apply
            bool canApply = hasChanged && !isSubmitting;

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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close, size: 30),
                            ),
                            const SizedBox(width: 8),
                            const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),

                        // Reset hanya tampil jika ada filter terpilih
                        if (showReset)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                paramTime.clear();
                                paramPrice.clear();
                                paramCount = 0;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),

                    const Divider(),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(timeTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 8),
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

                    const Divider(),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(bahasa['harga'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 8),
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

                    const SizedBox(height: 20),

                    // tombol apply
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canApply
                          ? () async {
                              setState(() {
                                canApply = true;
                                isSubmitting = true;
                              });

                              await Future.delayed(const Duration(milliseconds: 400));

                              Navigator.pop(context, {
                                'time': paramTime,
                                'price': paramPrice,
                              });
                            }
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              "Apply",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
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