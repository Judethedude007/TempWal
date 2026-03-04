import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  Future<void> _copyDetails() async {
    final payload = 'Payment QR for ${qr.walletName}\nID: ${qr.qrValue}';
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR code details copied to clipboard')));
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _StatusCard(qr: qr, isDark: isDark, progress: _progress(), remainingLabel: _remainingLabel()),
          const SizedBox(height: 16),
          _QrPreview(qr: qr, isDark: isDark, onShare: _copyDetails),
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
        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF374151)),
        label: Text('Back', style: TextStyle(fontWeight: FontWeight.w600, color: state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF374151))),
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
        gradient: isDark ? null : const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        color: isDark ? const Color(0xFF1C1C1F) : null,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(qr.limitType == LimitType.time ? Icons.timer_outlined : Icons.attach_money, color: Colors.white),
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
            decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(999)),
            child: Text(qr.walletName, style: const TextStyle(color: Color(0xFF854D0E), fontWeight: FontWeight.w600)),
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
            border: Border.all(color: const Color(0xFFEDE9FE), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TempWal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                      Text('Secure Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: qr.qrValue,
                    version: QrVersions.auto,
                    size: 220,
                    errorCorrectionLevel: QrErrorCorrectLevel.H, // HIGH error correction
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1E1B4B)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E1B4B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFACC15), width: 2),
                    ),
                    child: const Text('TempWal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('ID: ${qr.qrValue}', style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onShare,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share QR Code', style: TextStyle(fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0x33FACC15) : const Color(0xFFFFFBEB),
        border: Border.all(color: isDark ? const Color(0xFFFACC15) : const Color(0xFFFCD34D), width: 2),
      ),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(wallet?.name ?? 'Wallet', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE7E5E4) : const Color(0xFF92400E))),
            const SizedBox(height: 4),
            Text(formatCurrency(wallet?.balance ?? 0), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFACC15) : const Color(0xFF92400E))),
          ]),
          const Spacer(),
          if (wallet != null && wallet!.balance > 0)
            ElevatedButton(
              onPressed: () => state.transferWalletToRealAccount(wallet!.id),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Transfer'),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE), border: Border.all(color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF7DD3FC), width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.bolt_outlined, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
          const SizedBox(width: 8),
          Text('Payment Simulator', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0C4A6E))),
        ]),
        const SizedBox(height: 12),
        if (!showSimulator)
          ElevatedButton(onPressed: () => onToggle(true), style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Simulate payment'))
        else ...[
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(prefixText: '\$ ', filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            onChanged: (v) { final p = double.tryParse(v); if (p != null) onAmountChange(p); },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: onSimulate, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Send \$${simulatedAmount}'))),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () => onToggle(false), child: const Text('Cancel')),
          ]),
        ]
      ]),
    );
  }
}
