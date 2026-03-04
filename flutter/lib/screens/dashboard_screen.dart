import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final activeWallets = state.activeWallets;
    final expiredWallets = state.expiredWallets;

    return Container(
      color: isDark ? Colors.black : const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          _RealBalanceCard(state: state),
          const SizedBox(height: 24),
          _WalletHeader(state: state),
          const SizedBox(height: 12),
          _WalletTotals(state: state),
          const SizedBox(height: 12),
          if (activeWallets.isNotEmpty)
            ...activeWallets.map(
              (wallet) => _WalletTile(
                wallet: wallet,
                isDark: isDark,
                onTap: () => state.viewWalletTransactions(wallet.id),
              ),
            )
          else
            _EmptyWalletMessage(isDark: isDark),
          if (expiredWallets.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ExpiredSection(wallets: expiredWallets, state: state),
          ],
          const SizedBox(height: 24),
          _AddWalletButton(state: state),
          const SizedBox(height: 24),
          _InfoPanel(isDark: isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RealBalanceCard extends StatelessWidget {
  const _RealBalanceCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? const Color(0xFF1C1C1F) : null,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: const Color(0xFF27272A))
            : null,
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: isDark ? const Color(0xFFFACC15) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Main Account',
                style: TextStyle(
                  color: isDark ? const Color(0xFFA1A1AA) : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatCurrency(state.realAccountBalance),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFFACC15) : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Available balance',
            style: TextStyle(
              color: isDark ? const Color(0xFF71717A) : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Temporary Wallets',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => state.setView('wallets'),
          icon: Icon(
            Icons.add,
            size: 18,
            color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
          ),
          label: Text(
            'Manage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ],
    );
  }
}

class _WalletTotals extends StatelessWidget {
  const _WalletTotals({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x2218181B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFFCD34D),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total in Temporary Wallets',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8A8A91) : const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(state.getTotalTempBalance()),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF92400E),
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
    required this.onTap,
  });

  final TempWallet wallet;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101013) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(wallet.balance),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? const Color(0xFF52525B) : const Color(0xFF9CA3AF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWalletMessage extends StatelessWidget {
  const _EmptyWalletMessage({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x2218181B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'No active temporary wallets',
        style: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _ExpiredSection extends StatelessWidget {
  const _ExpiredSection({required this.wallets, required this.state});

  final List<TempWallet> wallets;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF52525B) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Expired Wallets',
              style: TextStyle(
                letterSpacing: 1.2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...wallets.map(
          (wallet) => GestureDetector(
            onTap: () => state.viewWalletTransactions(wallet.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x0818181B) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                ),
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
                            color: isDark
                                ? const Color(0xFFE4E4E7)
                                : const Color(0xFF4B5563),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Expired',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF71717A)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              'View history',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF71717A)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? const Color(0xFF52525B) : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    return ElevatedButton.icon(
      onPressed: () => state.setView('wallets'),
      icon: Icon(
        Icons.add,
        color: isDark ? Colors.black : Colors.white,
      ),
      label: Text(
        'Add New Wallet',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor:
            isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 8,
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1018181B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE0E7FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            final text = switch (index) {
              0 => 'Create named wallets for different causes (Emergency, Disaster Relief, etc.)',
              1 => 'Generate QR codes linked to specific wallets - multiple people can pay',
              _ => 'All funds auto-transfer to main account when limits are reached',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFFACC15)
                          : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
