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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      return _EnhancedTransactionTile(
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

class _EnhancedTransactionTile extends StatelessWidget {
  const _EnhancedTransactionTile({
    required this.transaction,
    required this.isDark,
    required this.onTap,
  });

  final WalletTransaction transaction;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isFailed = transaction.status == TransactionStatus.failed;
    final bool isReceived = transaction.type == TransactionType.received;
    final String amountPrefix = isReceived ? '+' : '-';
    
    String displayName = transaction.otherPartyName ?? transaction.walletName;
    if (transaction.type == TransactionType.transferred || transaction.type == TransactionType.autoTransferred) {
      displayName = "Main Account Transfer";
    }

    Color mainColor;
    IconData typeIcon;

    if (isFailed) {
      mainColor = Colors.red;
      typeIcon = Icons.error_outline;
    } else {
      switch (transaction.type) {
        case TransactionType.received:
          mainColor = const Color(0xFF10B981);
          typeIcon = Icons.add_rounded;
          break;
        case TransactionType.sent:
          mainColor = const Color(0xFF2563EB);
          typeIcon = Icons.remove_rounded;
          break;
        case TransactionType.transferred:
          mainColor = isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED);
          typeIcon = Icons.swap_horiz_rounded;
          break;
        case TransactionType.autoTransferred:
          mainColor = Colors.purple;
          typeIcon = Icons.auto_awesome_rounded;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isFailed 
                    ? Colors.red.withOpacity(0.3) 
                    : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: mainColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isFailed ? Colors.red : (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$amountPrefix${formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isFailed ? Colors.red : (isReceived ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87)),
                  ),
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
    final Color accentColor = isFailed ? Colors.red : (isDark ? const Color(0xFFFACC15) : const Color(0xFF7C3AED));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text(
            'Transaction Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 24),
          _detailRow('Status', txn.status.name.toUpperCase(), isFailed ? Colors.red : Colors.green),
          _divider(),
          _detailRow('Type', txn.type.name.replaceAll('autoTransferred', 'Auto Transfer').toUpperCase(), null),
          _divider(),
          _detailRow('Wallet', txn.walletName, null),
          _divider(),
          _detailRow('Date', formatShortDate(txn.timestamp), null),
          if (txn.otherPartyName != null) ...[
            _divider(),
            _detailRow('Counterparty', txn.otherPartyName!, null),
          ],
          if (isFailed && txn.failureReason != null) ...[
            _divider(),
            _detailRow('Failure Reason', txn.failureReason!, Colors.red),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: valueColor ?? (isDark ? Colors.white : Colors.black87))),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.grey.withOpacity(0.1));
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
            'History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: state.isDarkMode ? Colors.white : const Color(0xFF0F172A),
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
          Icon(Icons.history_toggle_off, size: 80, color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
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
