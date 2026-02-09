// ignore_for_file: use_build_context_synchronously 

import 'dart:io' show File, Directory, Platform;
import 'dart:ui' as ui; 

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
    final url = 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=$qrData'; 
    final response = await http.get(Uri.parse(url)); 
    if (response.statusCode != 200) { 
      _showSnack(context, downloadScanGagal); 
      return; 
    } 

    final borderedQr = await addBorderToQr(
      response.bodyBytes,
      borderSize: 50, // tebal border
    );
    
    final tempDir = await getTemporaryDirectory();
    final filePath =
      '${tempDir.path}/QR_${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File(filePath);
    // await file.writeAsBytes(response.bodyBytes);
    await file.writeAsBytes(borderedQr);
    
    Directory dir; 
    
    if (Platform.isAndroid) { 
      // Public Download folder 
      dir = Directory('/storage/emulated/0/Download'); 
      final outFile = File('${dir.path}/${file.uri.pathSegments.last}');
      // await outFile.writeAsBytes(response.bodyBytes);
      await outFile.writeAsBytes(borderedQr);

      _showSnack( context, downloadScanBerhasil, ); 
    } else { 
      // iOS sandbox Documents 
      dir = await getApplicationDocumentsDirectory(); 

      await file.writeAsBytes(borderedQr);
      
      await _channel.invokeMethod('saveImageToGallery', {
        'path': file.path,
      });

      _showSnack( context, downloadScanBerhasil, ); 
    }

    if (!context.mounted) return;
    
    // OPTIONAL: langsung buka file 
    //// await OpenFile.open(file.path); 
  } catch (e) { 
    if (!context.mounted) return; 
    _showSnack(
      context, 
      kesalahanSimpanScan
    ); 
  } 
} 

void _showSnack(BuildContext context, String message) { 
  ScaffoldMessenger.of(context) 
    .showSnackBar(SnackBar(content: Text(message))); 
}

Future<Uint8List> addBorderToQr(
  Uint8List qrBytes, {
  double borderSize = 40,
  Color borderColor = Colors.black,
  Color backgroundColor = Colors.white,
}) async {
  final codec = await ui.instantiateImageCodec(qrBytes);
  final frame = await codec.getNextFrame();
  final qrImage = frame.image;

  final size = qrImage.width.toDouble();
  final totalSize = size + borderSize * 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final paintBg = Paint()..color = backgroundColor;
  final paintBorder = Paint()..color = borderColor;

  // background
  canvas.drawRect(
    Rect.fromLTWH(0, 0, totalSize, totalSize),
    paintBg,
  );

  // border
  canvas.drawRect(
    Rect.fromLTWH(0, 0, totalSize, totalSize),
    paintBorder,
  );

  // inner white area
  canvas.drawRect(
    Rect.fromLTWH(
      borderSize / 2,
      borderSize / 2,
      totalSize - borderSize,
      totalSize - borderSize,
    ),
    paintBg,
  );

  // draw QR
  canvas.drawImage(
    qrImage,
    Offset(borderSize, borderSize),
    Paint(),
  );

  final picture = recorder.endRecording();
  final finalImage =
      await picture.toImage(totalSize.toInt(), totalSize.toInt());

  final byteData =
      await finalImage.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}