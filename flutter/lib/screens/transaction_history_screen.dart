import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({required this.state, super.key});

  final AppState state;

  Color _typeColor(TransactionType type, TransactionStatus status, bool isDark) {
    if (status == TransactionStatus.failed) return Colors.red;
    
    switch (type) {
      case TransactionType.received:
        return const Color(0xFF10B981); // Green
      case TransactionType.sent:
        return const Color(0xFF2563EB); // Blue
      case TransactionType.transferred:
        return isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED);
      case TransactionType.autoTransferred:
        return Colors.purple; // Distinct color for auto
    }
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.received:
        return Icons.add_circle_outline;
      case TransactionType.sent:
        return Icons.remove_circle_outline;
      case TransactionType.transferred:
        return Icons.account_balance_wallet_outlined;
      case TransactionType.autoTransferred:
        return Icons.auto_awesome_outlined;
    }
  }

  String _titleForType(TransactionType type, String? otherParty) {
    switch (type) {
      case TransactionType.received:
        return otherParty != null ? 'From $otherParty' : 'Payment Received';
      case TransactionType.sent:
        return otherParty != null ? 'To $otherParty' : 'Payment Sent';
      case TransactionType.transferred:
        return 'Transferred to Main';
      case TransactionType.autoTransferred:
        return 'Auto-Transferred';
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = state.transactions;
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050506) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _HistoryHeader(state: state),
          Expanded(
            child: transactions.isEmpty
                ? _EmptyState(isDark: isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      final color = _typeColor(txn.type, txn.status, isDark);
                      return _TransactionTile(
                        transaction: txn,
                        icon: _iconForType(txn.type),
                        color: color,
                        title: _titleForType(txn.type, txn.otherPartyName),
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.state});
  final AppState state;

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
          Text(
            'Transaction History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: state.isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
  });

  final WalletTransaction transaction;
  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool isFailed = transaction.status == TransactionStatus.failed;
    final String amountPrefix = transaction.type == TransactionType.received ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          width: isFailed ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.walletName} • ${formatShortDate(transaction.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (isFailed && transaction.failureReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.failureReason!,
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${formatCurrency(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFailed ? 'FAILED' : 'SUCCESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isFailed ? Colors.red : Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
