import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/widgets/loading_page.dart';

class SavedModal {
  static void show(BuildContext context, String langCode) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      body: FutureBuilder<Map<String, dynamic>>(
        future: LangService.getJsonDataArray(langCode, "detail_finalis", "modal_saved"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showLoadingDialog(context);
            });
            return const Scaffold(); // kosong sementara
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              hideLoadingDialog(context);
            });
          }

          if (snapshot.hasError) {
            return const Text("Error load text");
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                //header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.black),
                    ),
                  ],
                ),
                const Divider(),

                const SizedBox(height: 8),

                //isi konten
                Image.asset(
                  "assets/images/img_saved.png"
                ),

                const SizedBox(height: 16),
                Text(
                  "QR berhasil disimpan",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  "Periksa penyimpan atan galeri handphone kamu",
                  softWrap: true,
                ),
              ],
            ),
          );
        },
      ),
    ).show();
  }
}