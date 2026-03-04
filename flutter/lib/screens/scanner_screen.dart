import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_state.dart';
import '../utils/formatters.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({required this.state, super.key});

  final AppState state;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;
  String? _scannedData;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
          _scannedData = code;
        });
        _showConfirmationSheet(code);
        break;
      }
    }
  }

  void _showConfirmationSheet(String qrData) {
    // Attempt to parse QR data if it's JSON
    String recipientName = 'External Wallet';
    String? walletId;
    double? suggestedAmount;

    try {
      if (qrData.startsWith('{')) {
        final data = jsonDecode(qrData);
        recipientName = data['name'] ?? 'Recipient';
        walletId = data['walletId'];
        suggestedAmount = data['amount']?.toDouble();
      } else if (qrData.startsWith('QR-')) {
        // Handle our internal QR format
        recipientName = 'TempWal Recipient';
        walletId = qrData;
      }
    } catch (e) {
      recipientName = 'Unknown Recipient';
    }

    if (suggestedAmount != null) {
      _amountController.text = suggestedAmount.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationSheet(
        recipientName: recipientName,
        suggestedAmount: suggestedAmount,
        amountController: _amountController,
        isDark: widget.state.isDarkMode,
        onConfirm: (amount) {
          Navigator.pop(context);
          _completePayment(qrData, amount, recipientName);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _isScanning = true);
        },
      ),
    );
  }

  void _completePayment(String qrId, double amount, String recipientName) {
    if (amount > widget.state.realAccountBalance) {
      _showStatusDialog(false, 'Insufficient balance in your main account.');
      setState(() => _isScanning = true);
      return;
    }

    widget.state.scannerPayment(qrId, amount);
    _showStatusDialog(true, 'Successfully sent ${formatCurrency(amount)} to $recipientName');
  }

  void _showStatusDialog(bool success, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.state.isDarkMode ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Payment Sent' : 'Payment Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.state.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.state.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (success) {
                  widget.state.setView('dashboard');
                } else {
                  setState(() => _isScanning = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          _buildOverlay(isDark),
          Positioned(
            top: 48,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => widget.state.setView('dashboard'),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScannerActionBtn(
                  icon: Icons.flash_on,
                  onPressed: () => _scannerController.toggleTorch(),
                ),
                const SizedBox(width: 24),
                _ScannerActionBtn(
                  icon: Icons.flip_camera_ios,
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(bool isDark) {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: isDark ? const Color(0xFFFACC15) : Colors.blue,
          borderRadius: 20,
          borderLength: 40,
          borderWidth: 8,
          cutOutSize: 280,
        ),
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({
    required this.recipientName,
    this.suggestedAmount,
    required this.amountController,
    required this.isDark,
    required this.onConfirm,
    required this.onCancel,
  });

  final String recipientName;
  final double? suggestedAmount;
  final TextEditingController amountController;
  final bool isDark;
  final Function(double) onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirm Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 35,
            backgroundColor: isDark ? const Color(0xFFFACC15).withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: isDark ? const Color(0xFFFACC15) : Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recipientName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFACC15) : Colors.blue,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '\$ ',
              border: InputBorder.none,
              hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey : Colors.black54)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      onConfirm(amount);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFACC15) : Colors.blue,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerActionBtn extends StatelessWidget {
  const _ScannerActionBtn({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final double width = rect.width;
    final double height = rect.height;
    final double cutOutWidth = cutOutSize;
    final double cutOutHeight = cutOutSize;
    final double left = (width - cutOutWidth) / 2;
    final double top = (height - cutOutHeight) / 2;

    final Paint paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cutOutWidth, cutOutHeight),
          Radius.circular(borderRadius),
        )),
      ),
      paint,
    );

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderLength)
        ..lineTo(left, top)
        ..lineTo(left + borderLength, top),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + cutOutWidth - borderLength, top)
        ..lineTo(left + cutOutWidth, top)
        ..lineTo(left + cutOutWidth, top + borderLength),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + cutOutWidth, top + cutOutHeight - borderLength)
        ..lineTo(left + cutOutWidth, top + cutOutHeight)
        ..lineTo(left + cutOutWidth - borderLength, top + cutOutHeight),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + borderLength, top + cutOutHeight)
        ..lineTo(left, top + cutOutHeight)
        ..lineTo(left, top + cutOutHeight - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
