import { ArrowLeft, ArrowDownLeft, ArrowUpRight } from 'lucide-react';
import type { Transaction } from '@/app/App';

interface TransactionHistoryProps {
  transactions: Transaction[];
  onBack: () => void;
  isDarkMode?: boolean;
}

export function TransactionHistory({ transactions, onBack, isDarkMode }: TransactionHistoryProps) {
  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  };

  return (
    <div className={`p-6 space-y-6 min-h-full ${isDarkMode ? 'bg-black text-white' : 'bg-gray-50'}`}>
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={onBack}
          className={`p-2 rounded-full transition-colors ${
            isDarkMode ? 'hover:bg-zinc-800 text-yellow-400' : 'hover:bg-gray-100 text-gray-700'
          }`}
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h2 className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Transaction History</h2>
      </div>

      {/* Transactions List */}
      {transactions.length === 0 ? (
        <div className="text-center py-16">
          <div className={`w-16 h-16 rounded-full mx-auto mb-4 flex items-center justify-center ${
            isDarkMode ? 'bg-zinc-900' : 'bg-gray-100'
          }`}>
            <svg
              className={`w-8 h-8 ${isDarkMode ? 'text-zinc-700' : 'text-gray-400'}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
              />
            </svg>
          </div>
          <div className={`font-medium mb-1 ${isDarkMode ? 'text-zinc-400' : 'text-gray-600'}`}>No transactions yet</div>
          <div className={`text-sm ${isDarkMode ? 'text-zinc-600' : 'text-gray-500'}`}>Your transaction history will appear here</div>
        </div>
      ) : (
        <div className="space-y-3">
          {transactions.map((transaction) => (
            <div
              key={transaction.id}
              className={`rounded-xl p-4 border transition-all ${
                isDarkMode 
                  ? 'bg-zinc-900 border-zinc-800' 
                  : 'bg-white border-gray-200 hover:shadow-md'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={`p-2 rounded-full ${
                      transaction.type === 'received'
                        ? (isDarkMode ? 'bg-green-400/10' : 'bg-green-100')
                        : (isDarkMode ? 'bg-blue-400/10' : 'bg-blue-100')
                    }`}
                  >
                    {transaction.type === 'received' ? (
                      <ArrowDownLeft className={`w-5 h-5 ${isDarkMode ? 'text-green-400' : 'text-green-600'}`} />
                    ) : (
                      <ArrowUpRight className={`w-5 h-5 ${isDarkMode ? 'text-blue-400' : 'text-blue-600'}`} />
                    )}
                  </div>
                  <div>
                    <div className={`font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                      {transaction.type === 'received' ? 'Received Payment' : 'Auto-Transfer'}
                    </div>
                    <div className={`text-xs font-medium ${isDarkMode ? 'text-yellow-400/80' : 'text-purple-600'}`}>
                      {transaction.walletName}
                    </div>
                    <div className={`text-sm ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>{formatDate(transaction.timestamp)}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div
                    className={`text-lg font-bold ${
                      transaction.type === 'received' 
                        ? (isDarkMode ? 'text-green-400' : 'text-green-600') 
                        : (isDarkMode ? 'text-blue-400' : 'text-blue-600')
                    }`}
                  >
                    {transaction.type === 'received' ? '+' : ''}${transaction.amount.toFixed(2)}
                  </div>
                  <div
                    className={`text-xs px-2 py-0.5 rounded-full inline-block ${
                      transaction.status === 'completed'
                        ? (isDarkMode ? 'bg-green-400/20 text-green-400' : 'bg-green-100 text-green-700')
                        : (isDarkMode ? 'bg-amber-400/20 text-amber-400' : 'bg-amber-100 text-amber-700')
                    }`}
                  >
                    {transaction.status === 'completed' ? 'Completed' : 'Pending'}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Summary */}
      {transactions.length > 0 && (
        <div className={`rounded-xl p-5 border ${
          isDarkMode ? 'bg-zinc-900 border-zinc-800' : 'bg-gradient-to-r from-purple-50 to-blue-50 border-purple-100'
        }`}>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className={`text-sm mb-1 ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>Total Received</div>
              <div className={`text-xl font-bold ${isDarkMode ? 'text-green-400' : 'text-green-600'}`}>
                ${transactions
                  .filter((t) => t.type === 'received')
                  .reduce((sum, t) => sum + t.amount, 0)
                  .toFixed(2)}
              </div>
            </div>
            <div>
              <div className={`text-sm mb-1 ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>Total Transferred</div>
              <div className={`text-xl font-bold ${isDarkMode ? 'text-blue-400' : 'text-blue-600'}`}>
                ${transactions
                  .filter((t) => t.type === 'transferred')
                  .reduce((sum, t) => sum + t.amount, 0)
                  .toFixed(2)}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}