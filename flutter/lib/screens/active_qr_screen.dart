import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class ActiveQrScreen extends StatefulWidget {
  const ActiveQrScreen({required this.state, required this.qrData, super.key});

  final AppState state;
  final ActiveQRData qrData;

  @override
  State<ActiveQrScreen> createState() => _ActiveQrScreenState();
}

class _ActiveQrScreenState extends State<ActiveQrScreen> {
  late ActiveQRData qr;
  final Duration _tickInterval = const Duration(seconds: 1);
  Timer? _timer;
  Duration remaining = Duration.zero;
  bool showSimulator = false;
  double simulatedAmount = 25;
  late final TextEditingController amountController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    qr = widget.qrData;
    amountController = TextEditingController(text: simulatedAmount.toStringAsFixed(0));
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ActiveQrScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrData.id != widget.qrData.id) {
      qr = widget.qrData;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    amountController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (qr.limitType == LimitType.time && qr.timeLimit != null) {
      _updateRemaining();
      _timer = Timer.periodic(_tickInterval, (_) => _handleTick());
    } else {
      remaining = Duration.zero;
    }
  }

  void _handleTick() {
    if (!mounted) return;
    _updateRemaining();
    if (remaining.inSeconds <= 0) {
      _timer?.cancel();
      widget.state.qrExpired();
    }
  }

  void _updateRemaining() {
    if (!mounted) return;
    if (qr.limitType != LimitType.time || qr.timeLimit == null) {
      setState(() => remaining = Duration.zero);
      return;
    }
    final elapsed = DateTime.now().difference(qr.createdAt).inSeconds;
    final total = qr.timeLimit!;
    final secondsLeft = total - elapsed;
    final safeSeconds = secondsLeft < 0 ? 0 : secondsLeft;
    setState(() => remaining = Duration(seconds: safeSeconds));
  }

  double _progress() {
    if (qr.limitType == LimitType.time && qr.timeLimit != null && qr.timeLimit! > 0) {
      final spent = qr.timeLimit! - remaining.inSeconds;
      return (spent / qr.timeLimit!).clamp(0.0, 1.0);
    }
    if (qr.limitType == LimitType.amount && qr.amountLimit != null && qr.amountLimit! > 0) {
      return (qr.currentAmount / qr.amountLimit!).clamp(0.0, 1.0);
    }
    return 0;
  }

  String _remainingLabel() {
    if (qr.limitType == LimitType.time) {
      final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      final hours = remaining.inHours;
      if (hours > 0) return '$hours:$minutes:$seconds';
      return '$minutes:$seconds';
    }
    return '${formatCurrency(qr.currentAmount)} / ${formatCurrency(qr.amountLimit ?? 0)}';
  }

  void _simulate(double amount) {
    if (amount <= 0) return;
    widget.state.simulatePayment(amount);
    final updated = widget.state.activeQR;
    setState(() {
      showSimulator = false;
      simulatedAmount = amount;
      amountController.text = amount.toStringAsFixed(0);
      if (updated != null) qr = updated;
    });
  }

  Future<void> _shareQrImage() async {
    try {
      final image = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TempWal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Text(
                  'the only wallet you need',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                _QrWithLogo(qrValue: qr.qrValue),
                const SizedBox(height: 32),
                Text(
                  'Pay into: ${qr.walletName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (qr.limitType == LimitType.amount)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Target Limit: ${formatCurrency(qr.amountLimit ?? 0)}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Scan this QR code using TempWal app to pay.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/tempwal_payment_qr.png');
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Hey! Scan this QR code to pay me ₹${(qr.amountLimit ?? 0).toInt()} into my ${qr.walletName} on TempWal!',
      );
    } catch (e) {
      debugPrint('Error sharing QR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.state.activeQR;
    if (latest != null && latest.id == qr.id) qr = latest;
    final isDark = widget.state.isDarkMode;
    final wallet = widget.state.getCurrentWallet();
    final double? remainingAmount = qr.limitType == LimitType.amount && qr.amountLimit != null
        ? (qr.amountLimit! - qr.currentAmount).clamp(0.0, double.infinity)
        : null;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: [
          _BackButton(state: widget.state),
          const SizedBox(height: 12),
          Text(
            'Active QR Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _StatusCard(qr: qr, isDark: isDark, progress: _progress(), remainingLabel: _remainingLabel()),
          const SizedBox(height: 16),
          _QrPreview(qr: qr, isDark: isDark, onShare: _shareQrImage),
          const SizedBox(height: 16),
          _WalletSummary(state: widget.state, wallet: wallet),
          const SizedBox(height: 16),
          _PaymentSimulator(
            isDark: isDark,
            showSimulator: showSimulator,
            controller: amountController,
            simulatedAmount: simulatedAmount,
            remainingAmount: remainingAmount,
            onToggle: (value) => setState(() => showSimulator = value),
            onAmountChange: (value) => setState(() => simulatedAmount = value),
            onSimulate: () => _simulate(simulatedAmount),
            onQuickSimulate: (value) => _simulate(value),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => state.setView('dashboard'),
        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF6366F1)),
        label: Text('Back', style: TextStyle(fontWeight: FontWeight.w600, color: state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF6366F1))),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.qr, required this.isDark, required this.progress, required this.remainingLabel});
  final ActiveQRData qr;
  final bool isDark;
  final double progress;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        color: isDark ? const Color(0xFF1C1C1F) : null,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(qr.limitType == LimitType.time ? Icons.timer_outlined : Icons.account_balance_wallet_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(qr.limitType == LimitType.time ? 'Time remaining' : 'Amount received', style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: isDark ? const Color(0xFFFACC15) : Colors.white, borderRadius: BorderRadius.circular(999)),
            child: Text(
              qr.walletName, 
              style: TextStyle(color: isDark ? Colors.black : const Color(0xFF4F46E5), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(remainingLabel, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _QrWithLogo extends StatelessWidget {
  const _QrWithLogo({required this.qrValue});
  final String qrValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          data: qrValue,
          version: QrVersions.auto,
          size: 220,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1E1B4B)),
          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E1B4B)),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6366F1), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset('assets/app_icon.png', fit: BoxFit.contain),
        ),
      ],
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.qr, required this.isDark, required this.onShare});
  final ActiveQRData qr;
  final bool isDark;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TempWal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Secure Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _QrWithLogo(qrValue: qr.qrValue),
              const SizedBox(height: 24),
              Text('Payment ID: ${qr.qrValue}', style: TextStyle(fontFamily: 'RobotoMono', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onShare,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
            foregroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
          ),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share QR Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary({required this.state, required this.wallet});
  final AppState state;
  final TempWallet? wallet;
  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(wallet?.name ?? 'Wallet', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(formatCurrency(wallet?.balance ?? 0), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1))),
          ]),
          const Spacer(),
          if (wallet != null && wallet!.balance > 0)
            ElevatedButton(
              onPressed: () => state.transferWalletToRealAccount(wallet!.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _PaymentSimulator extends StatelessWidget {
  const _PaymentSimulator({required this.isDark, required this.showSimulator, required this.controller, required this.simulatedAmount, required this.remainingAmount, required this.onToggle, required this.onAmountChange, required this.onSimulate, required this.onQuickSimulate});
  final bool isDark;
  final bool showSimulator;
  final TextEditingController controller;
  final double simulatedAmount;
  final double? remainingAmount;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onAmountChange;
  final VoidCallback onSimulate;
  final ValueChanged<double> onQuickSimulate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF8FAFC),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.bolt_rounded, color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text('Simulator', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF6366F1))),
        ]),
        const SizedBox(height: 12),
        if (!showSimulator)
          ElevatedButton(
            onPressed: () => onToggle(true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
              elevation: 0,
            ),
            child: const Text('Simulate incoming payment'),
          )
        else ...[
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '₹ ', 
              filled: true, 
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) { final p = double.tryParse(v); if (p != null) onAmountChange(p); },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: onSimulate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text('Receive ₹${simulatedAmount.toInt()}'))),
            const SizedBox(width: 12),
            TextButton(onPressed: () => onToggle(false), child: const Text('Cancel')),
          ]),
        ]
      ]),
    );
  }
}
