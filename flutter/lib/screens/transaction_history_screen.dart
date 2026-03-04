import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({required this.state, super.key});

  final AppState state;

  void _showTransactionDetails(BuildContext context, WalletTransaction txn, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TransactionDetailSheet(txn: txn, isDark: isDark),
    );
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      return _PremiumTransactionTile(
                        transaction: txn,
                        isDark: isDark,
                        onTap: () => _showTransactionDetails(context, txn, isDark),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTransactionTile extends StatelessWidget {
  const _PremiumTransactionTile({
    required this.transaction,
    required this.isDark,
    required this.onTap,
  });

  final WalletTransaction transaction;
  final bool isDark;
  final VoidCallback onTap;

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'T';
    List<String> names = name.trim().split(' ');
    if (names.length > 1) {
      return (names[0][0] + names[1][0]).toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFailed = transaction.status == TransactionStatus.failed;
    final bool isReceived = transaction.type == TransactionType.received;
    final String amountPrefix = isReceived ? '+' : '-';
    
    String displayName = transaction.otherPartyName ?? transaction.walletName;
    if (transaction.type == TransactionType.transferred || transaction.type == TransactionType.autoTransferred) {
      displayName = "Internal Transfer";
    }

    Color accentColor;
    IconData typeIcon = Icons.swap_horiz_rounded;

    if (isFailed) {
      accentColor = const Color(0xFFEF4444);
    } else {
      switch (transaction.type) {
        case TransactionType.received:
          accentColor = const Color(0xFF10B981);
          break;
        case TransactionType.sent:
          accentColor = const Color(0xFF6366F1);
          break;
        case TransactionType.transferred:
          accentColor = isDark ? const Color(0xFFFACC15) : const Color(0xFF4F46E5);
          break;
        case TransactionType.autoTransferred:
          accentColor = const Color(0xFF8B5CF6);
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isFailed ? accentColor.withOpacity(0.3) : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: transaction.type == TransactionType.transferred || transaction.type == TransactionType.autoTransferred
                    ? Icon(typeIcon, color: accentColor, size: 24)
                    : Text(
                        _getInitials(transaction.otherPartyName),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isFailed ? accentColor : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatShortDate(transaction.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: isFailed ? accentColor : (isReceived ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A))),
                      ),
                    ),
                    if (isFailed)
                      const Text(
                        'FAILED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFEF4444), letterSpacing: 0.5),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({required this.txn, required this.isDark});
  final WalletTransaction txn;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool isFailed = txn.status == TransactionStatus.failed;
    final Color accentColor = isFailed ? const Color(0xFFEF4444) : (isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(color: Colors.grey[isDark ? 800 : 300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFailed ? Icons.error_outline_rounded : (txn.type == TransactionType.received ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
              size: 48,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFailed ? 'Transaction Failed' : 'Transaction Success',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(txn.amount),
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -1),
          ),
          const SizedBox(height: 40),
          _detailRow('Status', txn.status.name.toUpperCase(), isFailed ? accentColor : const Color(0xFF10B981)),
          _divider(),
          _detailRow('Type', txn.type.name.replaceAll('autoTransferred', 'Auto Transfer').toUpperCase(), null),
          _divider(),
          _detailRow('Wallet', txn.walletName, null),
          _divider(),
          _detailRow('Date & Time', formatShortDate(txn.timestamp), null),
          if (txn.otherPartyName != null) ...[
            _divider(),
            _detailRow('Counterparty', txn.otherPartyName!, null),
          ],
          if (isFailed && txn.failureReason != null) ...[
            _divider(),
            _detailRow('Reason', txn.failureReason!, accentColor),
          ],
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              minimumSize: const Size(double.infinity, 64),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: valueColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)))),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], height: 1);
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final bool isDark = state.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => state.setView('dashboard'),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off_rounded, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
