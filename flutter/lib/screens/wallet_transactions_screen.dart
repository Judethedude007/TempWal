import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class WalletTransactionsScreen extends StatelessWidget {
  const WalletTransactionsScreen({required this.state, required this.wallet, super.key});

  final AppState state;
  final TempWallet wallet;

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final entries = state.transactions
        .where((txn) => txn.walletId == wallet.id)
        .toList();
    
    // Check if there is an active QR for THIS specific wallet
    final activeQR = state.activeQR != null && state.activeQR!.walletId == wallet.id 
        ? state.activeQR 
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050506) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _WalletHeader(state: state, wallet: wallet),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _WalletSummaryCard(
                  wallet: wallet, 
                  isDark: isDark, 
                  onTransfer: () => state.transferWalletToRealAccount(wallet.id)
                ),
                if (activeQR != null) ...[
                  const SizedBox(height: 20),
                  _ActiveQRCard(qr: activeQR, isDark: isDark, state: state),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                  child: Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  _EmptyTransactions(isDark: isDark)
                else
                  ...entries.map((txn) => _WalletTransactionTile(transaction: txn, isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveQRCard extends StatelessWidget {
  const _ActiveQRCard({required this.qr, required this.isDark, required this.state});
  final ActiveQRData qr;
  final bool isDark;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFFFACC15).withOpacity(0.5) : const Color(0xFF7C3AED).withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED)).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE QR CODE',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () => state.setView('active'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Full Screen',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qr.qrValue,
              version: QrVersions.auto,
              size: 140,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            qr.limitType == LimitType.amount 
                ? 'Limit: ${formatCurrency(qr.amountLimit ?? 0)}'
                : 'Timed QR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.state, required this.wallet});

  final AppState state;
  final TempWallet wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: state.isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created ${formatShortDate(wallet.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: state.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({required this.wallet, required this.isDark, required this.onTransfer});

  final TempWallet wallet;
  final bool isDark;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    final balance = wallet.balance;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current balance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(balance),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: balance > 0 ? onTransfer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF2563EB),
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({required this.transaction, required this.isDark});

  final WalletTransaction transaction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.type == TransactionType.received;
    final color = isIncoming ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    final prefix = isIncoming ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            ),
            child: Icon(
              isIncoming ? Icons.call_received : Icons.call_made,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncoming ? 'Payment received' : 'Transferred',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatShortDate(transaction.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$prefix${formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 48, color: isDark ? const Color(0xFF4B5563) : const Color(0xFFCBD5F5)),
            const SizedBox(height: 16),
            Text(
              'No payments yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share your active QR code to start receiving funds.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
