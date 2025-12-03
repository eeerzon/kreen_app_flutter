// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // final MobileScannerController controller = MobileScannerController(
  //   detectionSpeed: DetectionSpeed.normal,
  //   returnImage: false,
  // );

  String? lastDetectedCode;
  bool isProcessingGallery = false;

  Future<void> _playFeedback() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 150);
    }
  }

  void _onDetect(String code) async {
    if (lastDetectedCode == code) return;
    lastDetectedCode = code;

    await _playFeedback();
    // controller.stop(); // Stop kamera dulu

    await Future.delayed(const Duration(milliseconds: 200));
    _showResultDialog(code);
  }

  Future<void> _pickFromGallery() async {
    if (isProcessingGallery) return;

    setState(() => isProcessingGallery = true);

    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);

    if (img == null) {
      setState(() => isProcessingGallery = false);
      return;
    }

    // final success = await controller.analyzeImage(img.path);

    // if (!success) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("QR Code tidak ditemukan di gambar")),
    //   );
    // }

    setState(() => isProcessingGallery = false);
  }

  void _showResultDialog(String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("QR Terdeteksi"),
        content: Text(text),
        actions: [
          TextButton(
            child: const Text("Tutup"),
            onPressed: () {
              Navigator.pop(context);
              // controller.start(); // Lanjut scan lagi
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    // controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text("Scan QR"),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.flash_on),
          //   onPressed: () => controller.toggleTorch(),
          // ),
          // IconButton(
          //   icon: const Icon(Icons.cameraswitch),
          //   onPressed: () => controller.switchCamera(),
          // ),
        ],
      ),
      body: Column(
        children: [
          // Expanded(
          //   child: MobileScanner(
          //     controller: controller,
          //     overlay: ScannerOverlay(),
          //     onDetect: (capture) {
          //       final barcode = capture.barcodes.first;
          //       if (barcode.rawValue != null) {
          //         _onDetect(barcode.rawValue!);
          //       }
          //     },
          //   ),
          // ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: isProcessingGallery ? null : _pickFromGallery,
              icon: const Icon(Icons.image),
              label: Text(
                isProcessingGallery
                    ? "Menganalisis..."
                    : "Pilih Gambar dari Galeri",
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScannerOverlayPainter(),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.2,
      size.width * 0.7,
      size.height * 0.5,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
