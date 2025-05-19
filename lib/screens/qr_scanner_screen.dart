import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isTorchOn = false;
  bool isBackCamera = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 스캐너'),
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
          ),
          IconButton(
            icon: Icon(isBackCamera ? Icons.camera_rear : Icons.camera_front),
            onPressed: () {
              controller.switchCamera();
              setState(() {
                isBackCamera = !isBackCamera;
              });
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          for (final barcode in capture.barcodes) {
            final value = barcode.rawValue;
            if (value != null) {
              debugPrint('QR Code: $value');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('스캔된 QR: $value')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
