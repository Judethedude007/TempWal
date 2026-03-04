import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({required this.state, super.key});

  final AppState state;

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  LimitType _limitType = LimitType.time;
  double _timeMinutes = 5;
  double _amountLimit = 100;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    final wallets = widget.state.activeWallets;
    if (wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }
  }

  void _handleGenerate() {
    final walletId = _selectedWalletId;
    if (walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a wallet before generating a QR code.')),
      );
      return;
    }

    final value = _limitType == LimitType.time ? _timeMinutes : _amountLimit;
    widget.state.generateQR(_limitType, value, walletId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _limitType == LimitType.time
              ? 'Created time-limited QR for ${value.round()} minutes.'
              : 'Created QR with ${formatCurrency(value)} cap.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = state.isDarkMode;
    final wallets = state.activeWallets;
    _selectedWalletId ??= wallets.isNotEmpty ? wallets.first.id : null;

    return Container(
      color: isDark ? const Color(0xFF050506) : const Color(0xFFF3F4F6),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _Header(state: state),
          const SizedBox(height: 16),
          Text(
            'Generate QR Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          _WalletPicker(
            wallets: wallets,
            selectedWalletId: _selectedWalletId,
            isDark: isDark,
            onSelect: (id) => setState(() => _selectedWalletId = id),
          ),
          const SizedBox(height: 24),
          _LimitChooser(
            limitType: _limitType,
            isDark: isDark,
            onChanged: (type) => setState(() => _limitType = type),
          ),
          const SizedBox(height: 24),
          _LimitSlider(
            limitType: _limitType,
            timeValue: _timeMinutes,
            amountValue: _amountLimit,
            isDark: isDark,
            onTimeChanged: (minutes) => setState(() => _timeMinutes = minutes),
            onAmountChanged: (amount) => setState(() => _amountLimit = amount),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: wallets.isEmpty ? null : _handleGenerate,
            icon: const Icon(Icons.qr_code_2_outlined),
            label: const Text('Generate QR Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 12),
          if (wallets.isEmpty)
            _EmptyWalletHint(isDark: isDark)
          else
            _SummaryCard(
              limitType: _limitType,
              timeValue: _timeMinutes,
              amountValue: _amountLimit,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => state.setView('dashboard'),
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: isDark ? const Color(0xFFFACC15) : const Color(0xFF374151),
        ),
        label: Text(
          'Back',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFFACC15) : const Color(0xFF374151),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }
}

class _WalletPicker extends StatelessWidget {
  const _WalletPicker({
    required this.wallets,
    required this.selectedWalletId,
    required this.isDark,
    required this.onSelect,
  });

  final List<TempWallet> wallets;
  final String? selectedWalletId;
  final bool isDark;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB)),
          color: isDark ? const Color(0x2218181B) : Colors.white,
        ),
        child: Text(
          'No active wallets. Create one on the dashboard first.',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: wallets
          .map(
            (wallet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(wallet.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      width: 2,
                      color: wallet.id == selectedWalletId
                          ? (isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED))
                          : (isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB)),
                    ),
                    color: wallet.id == selectedWalletId
                        ? (isDark ? const Color(0x33FACC15) : const Color(0xFFF3E8FF))
                        : (isDark ? const Color(0xFF0F0F12) : Colors.white),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(wallet.balance),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (wallet.id == selectedWalletId)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LimitChooser extends StatelessWidget {
  const _LimitChooser({
    required this.limitType,
    required this.isDark,
    required this.onChanged,
  });

  final LimitType limitType;
  final bool isDark;
  final ValueChanged<LimitType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LimitChoiceCard(
            label: 'Time Limit',
            icon: Icons.timer,
            selected: limitType == LimitType.time,
            isDark: isDark,
            onTap: () => onChanged(LimitType.time),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LimitChoiceCard(
            label: 'Amount Limit',
            icon: Icons.attach_money,
            selected: limitType == LimitType.amount,
            isDark: isDark,
            onTap: () => onChanged(LimitType.amount),
          ),
        ),
      ],
    );
  }
}

class _LimitChoiceCard extends StatelessWidget {
  const _LimitChoiceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? (isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED))
        : (isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB));
    final background = selected
        ? (isDark ? const Color(0x33FACC15) : const Color(0xFFF3E8FF))
        : (isDark ? const Color(0xFF0F0F12) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 2),
          color: background,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? (isDark ? Colors.black : const Color(0xFF7C3AED))
                    : (isDark ? Colors.white : const Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitSlider extends StatelessWidget {
  const _LimitSlider({
    required this.limitType,
    required this.timeValue,
    required this.amountValue,
    required this.isDark,
    required this.onTimeChanged,
    required this.onAmountChanged,
  });

  final LimitType limitType;
  final double timeValue;
  final double amountValue;
  final bool isDark;
  final ValueChanged<double> onTimeChanged;
  final ValueChanged<double> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final value = limitType == LimitType.time ? timeValue : amountValue;
    final min = limitType == LimitType.time ? 1.0 : 10.0;
    final max = limitType == LimitType.time ? 60.0 : 1000.0;
    final divisions = limitType == LimitType.time ? 59 : 99;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB)),
        color: isDark ? const Color(0xFF0F0F12) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            limitType == LimitType.time ? 'Duration (minutes)' : 'Maximum amount',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (newValue) {
              if (limitType == LimitType.time) {
                onTimeChanged(newValue);
              } else {
                onAmountChanged(newValue);
              }
            },
            activeColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
            inactiveColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  limitType == LimitType.time
                      ? '${value.round()} minutes'
                      : formatCurrency(value),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  limitType == LimitType.time
                      ? 'QR expires automatically when time runs out.'
                      : 'Funds auto-transfer when this total is reached.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.limitType,
    required this.timeValue,
    required this.amountValue,
    required this.isDark,
  });

  final LimitType limitType;
  final double timeValue;
  final double amountValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                limitType == LimitType.time ? Icons.timer : Icons.attach_money,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
              ),
              const SizedBox(width: 8),
              Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0C4A6E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            limitType == LimitType.time
                ? 'People can scan this code until ${timeValue.round()} minutes pass.'
                : 'People can scan this code until contributions reach ${formatCurrency(amountValue)}.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0369A1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Funds move to your main account automatically when the limit is reached.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF0C4A6E),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWalletHint extends StatelessWidget {
  const _EmptyWalletHint({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB)),
        color: isDark ? const Color(0xFF111827) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No wallets available',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a temporary wallet first to generate QR codes for events, trips, or pop-up sales.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
