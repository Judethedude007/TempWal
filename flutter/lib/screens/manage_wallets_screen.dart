import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class ManageWalletsScreen extends StatefulWidget {
  const ManageWalletsScreen({required this.state, super.key});

  final AppState state;

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.state.addWallet(name);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.state.tempWallets;
    final isDark = widget.state.isDarkMode;

    return Container(
      color: isDark ? const Color(0xFF050506) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _WalletsHeader(state: widget.state),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _CreateWalletCard(
              controller: _controller,
              onSubmit: _submit,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: wallets.isEmpty
                ? _EmptyWallets(isDark: isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      return _WalletTile(
                        wallet: wallet,
                        isDark: isDark,
                        onView: () => widget.state.viewWalletTransactions(wallet.id),
                        onDelete: () => widget.state.deleteWallet(wallet.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WalletsHeader extends StatelessWidget {
  const _WalletsHeader({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => state.setView('dashboard'),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: state.isDarkMode ? const Color(0xFFFACC15) : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Manage Wallets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: state.isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateWalletCard extends StatelessWidget {
  const _CreateWalletCard({required this.controller, required this.onSubmit, required this.isDark});

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a temp wallet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. Weekend fair',
              filled: true,
              fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.add),
              label: const Text('Add wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.isDark,
    required this.onView,
    required this.onDelete,
  });

  final TempWallet wallet;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
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
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(wallet.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onView,
            icon: const Icon(Icons.receipt_long),
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }
}

class _EmptyWallets extends StatelessWidget {
  const _EmptyWallets({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wallet_outlined, size: 48, color: isDark ? const Color(0xFF4B5563) : const Color(0xFFCBD5F5)),
          const SizedBox(height: 16),
          Text(
            'No temp wallets yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create one to start receiving event or personal payments.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
