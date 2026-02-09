// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File, Directory, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const MethodChannel _channel = MethodChannel('save_image_channel');

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
    
    final tempDir = await getTemporaryDirectory();
    final filePath =
      '${tempDir.path}/QR_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    if (Platform.isAndroid) {
      // Public Download folder
      final dir = Directory('/storage/emulated/0/Download');
      final outFile = File('${dir.path}/${file.uri.pathSegments.last}');
      await outFile.writeAsBytes(response.bodyBytes);
    } else {
      // iOS sandbox Documents
      await _channel.invokeMethod('saveImageToGallery', {
        'path': file.path,
      });
    }

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
