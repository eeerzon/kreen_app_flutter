// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:vibration/vibration.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {

  late AnimationController animController;
  late Animation<double> anim;
  bool scanned = false;

  Key scannerKey = UniqueKey();
  bool showScanner = true;
  String? langCode;
  Map<String, dynamic> bahasa = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });

    animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeInOut),
    );
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
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutOut = size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          
          if (showScanner)
            QRCodeDartScanView(
              key: scannerKey,
              scanInvertedQRCode: true,
              typeScan: TypeScan.live,
              onCapture: (result) {
                if (scanned) return;
                scanned = true;
                _onScanResult(result.text);
              },
            ),
          
          Positioned.fill(
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) {
                final topOffset = size.height * 0.5 - cutOut / 2;

                return Positioned(
                  top: topOffset + (cutOut - 4) * anim.value,
                  left: size.width * 0.125,
                  child: Container(
                    width: cutOut,
                    height: 4,
                    color: Colors.redAccent,
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Scan QR Code",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )
              ],
            ),
          ),
          
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.image),
                  label: Text(bahasa['scan_dari_galeri']),
                  onPressed: _pickImageFromGallery,
                ),

                const SizedBox(height: 12),
                // QRCodeDartScanCameraToggleBuilder(
                //   builder: (context, isOn, toggle) {
                //     return IconButton(
                //       onPressed: toggle,
                //       icon: Icon(
                //         isOn ? Icons.flash_on : Icons.flash_off,
                //         color: Colors.white,
                //         size: 32,
                //       ),
                //     );
                //   },
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onScanResult(String text) async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 120);
    }
    HapticFeedback.mediumImpact();

    _showResult(text);
  }

  void _showResult(String text) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: false,
      builder: (_) => Container(
        width: double.infinity,
        padding: kGlobalPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bahasa['rq_terdeteksi'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.pop(context, text);
                Navigator.pop(context);
              },
              child: Container(
                padding: kGlobalPadding,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  bahasa['lanjut'],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 200), () async {
                  setState(() {
                    scanned = false;
                    showScanner = false;
                  });
                  
                  await Future.delayed(const Duration(milliseconds: 250));

                  setState(() {
                    scannerKey = UniqueKey();
                    showScanner = true;
                  });
                });
              },
              child: Container(
                padding: kGlobalPadding,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  bahasa['scan_lagi'],
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    try {
      // final result = await QrCodeToolsPlugin.decodeFrom(img.path);
      final result = null;

      if (result != null && result.isNotEmpty) {
        _onScanResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bahasa['gagal_scan_1'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bahasa['gagal_scan_2'])),
      );
    }
  }
}
