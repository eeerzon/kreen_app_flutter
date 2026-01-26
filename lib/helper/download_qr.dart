// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File, Directory, Platform;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<void> downloadQrImage(
  BuildContext context, 
  String qrData,
  String downloadScanGagal,
  String downloadScanBerhasil,
  String kesalahanSimpanScan
) async {
  try {
    final url =
        'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=$qrData';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      _showSnack(context, downloadScanGagal);
      return;
    }

    Directory dir;

    if (Platform.isAndroid) {
      // Public Download folder
      dir = Directory('/storage/emulated/0/Download');
    } else {
      // iOS sandbox Documents
      dir = await getApplicationDocumentsDirectory();
    }
    
    final fileName =
        "QR_${DateTime.now().millisecondsSinceEpoch}.png";
    final file = File("${dir.path}/$fileName");

    await file.writeAsBytes(response.bodyBytes);

    if (!context.mounted) return;

    _showSnack(
      context,
      downloadScanBerhasil,
    );

    // OPTIONAL: langsung buka file
    // await OpenFile.open(file.path);

  } catch (e) {
    if (!context.mounted) return;
    _showSnack(context, kesalahanSimpanScan);
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
