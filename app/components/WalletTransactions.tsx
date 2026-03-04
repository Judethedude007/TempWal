import { ArrowLeft, ArrowDownLeft, ArrowUpRight, Share2, Clock, DollarSign } from 'lucide-react';
import type { Transaction, TempWallet, ActiveQRData } from '@/app/App';
import QRCode from 'react-qr-code';
import { toast } from 'sonner';

interface WalletTransactionsProps {
  wallet: TempWallet;
  activeQR: ActiveQRData | null;
  transactions: Transaction[];
  onBack: () => void;
  onExpired: () => void;
  onSimulatePayment: (amount: number) => void;
  isDarkMode?: boolean;
}

export function WalletTransactions({ 
  wallet, 
  activeQR, 
  transactions, 
  onBack, 
  onExpired,
  onSimulatePayment,
  isDarkMode 
}: WalletTransactionsProps) {
  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  };

  const handleShare = async () => {
    if (!activeQR) return;
    
    const shareData = {
      title: 'TempVal Payment Request',
      text: `Pay to ${wallet.name} using this Secure QR. Limit: ${
        activeQR.limitType === 'time' 
          ? 'Time based' 
          : `$${activeQR.amountLimit}`
      }`,
      url: window.location.href, // In a real app, this would be a deep link
    };

    try {
      if (navigator.share) {
        await navigator.share(shareData);
      } else {
        await navigator.clipboard.writeText(`Payment ID: ${activeQR.id}\nWallet: ${wallet.name}`);
        toast.success('Payment details copied to clipboard');
      }
    } catch (err) {
      console.error('Share failed:', err);
    }
  };

  return (
    <div className={`p-6 space-y-6 min-h-full ${isDarkMode ? 'bg-black' : 'bg-gray-50'}`}>
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
        <div>
          <h2 className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{wallet.name}</h2>
          <p className={`text-sm ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>
            {wallet.isExpired ? 'Expired Wallet' : 'Active Wallet'}
          </p>
        </div>
      </div>

      {/* Active QR Code Section */}
      {!wallet.isExpired && activeQR && (
        <div className={`${
          isDarkMode ? 'bg-zinc-900 border-zinc-800' : 'bg-white border-gray-200'
        } rounded-3xl p-6 border shadow-sm space-y-4`}>
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-2">
              <div className={`w-2 h-2 rounded-full bg-green-500 animate-pulse`}></div>
              <span className={`text-xs font-bold uppercase tracking-widest ${isDarkMode ? 'text-zinc-400' : 'text-gray-500'}`}>
                Active Payment QR
              </span>
            </div>
            <button
              onClick={handleShare}
              className={`p-2 rounded-full transition-colors ${
                isDarkMode ? 'bg-yellow-400 text-black hover:bg-yellow-300' : 'bg-purple-100 text-purple-600 hover:bg-purple-200'
              }`}
            >
              <Share2 className="w-4 h-4" />
            </button>
          </div>

          <div className="relative aspect-square max-w-[200px] mx-auto bg-white p-4 rounded-2xl shadow-inner border border-gray-100">
            <QRCode
              value={activeQR.qrValue}
              size={256}
              style={{ height: "auto", maxWidth: "100%", width: "100%" }}
              viewBox={`0 0 256 256`}
              fgColor={isDarkMode ? "#000000" : "#1e1b4b"}
            />
            {/* Watermark */}
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-10">
              <span className="text-xl font-black rotate-[-45deg] whitespace-nowrap uppercase">
                {wallet.name}
              </span>
            </div>
          </div>

          <div className="text-center space-y-1">
            <div className={`text-xs font-medium ${isDarkMode ? 'text-zinc-500' : 'text-gray-400'}`}>
              Payment ID: <span className="font-mono">{activeQR.id}</span>
            </div>
            <div className="flex items-center justify-center gap-4 mt-4">
              {activeQR.limitType === 'time' ? (
                <div className="flex items-center gap-1.5 text-sm font-semibold text-amber-600">
                  <Clock className="w-4 h-4" />
                  <span>Expires Soon</span>
                </div>
              ) : (
                <div className="flex items-center gap-1.5 text-sm font-semibold text-purple-600">
                  <DollarSign className="w-4 h-4" />
                  <span>Limit: ${activeQR.amountLimit}</span>
                </div>
              )}
            </div>
          </div>

          <div className="pt-2">
            <button
              onClick={() => onSimulatePayment(50)}
              className={`w-full py-3 rounded-xl text-sm font-bold transition-all ${
                isDarkMode 
                  ? 'bg-zinc-800 text-yellow-400 border border-zinc-700 hover:bg-zinc-700' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Simulate $50.00 Payment
            </button>
          </div>
        </div>
      )}

      {/* Transactions List */}
      <div className="space-y-4">
        <h3 className={`text-lg font-bold ${isDarkMode ? 'text-yellow-400' : 'text-gray-900'}`}>Transaction History</h3>
        
        {transactions.length === 0 ? (
          <div className={`text-center py-12 rounded-2xl border-2 border-dashed ${
            isDarkMode ? 'border-zinc-800 bg-zinc-900/30' : 'border-gray-200 bg-gray-50'
          }`}>
            <div className={`text-sm ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>No transactions yet</div>
          </div>
        ) : (
          <div className="space-y-3">
            {transactions.map((transaction) => (
              <div
                key={transaction.id}
                className={`rounded-xl p-4 border transition-all ${
                  isDarkMode 
                    ? 'bg-zinc-900 border-zinc-800' 
                    : 'bg-white border-gray-200'
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
                        {transaction.type === 'received' ? 'Received' : 'Auto-Transfer'}
                      </div>
                      <div className={`text-xs ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>
                        {formatDate(transaction.timestamp)}
                      </div>
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
                      className={`text-[10px] px-2 py-0.5 rounded-full inline-block font-bold uppercase tracking-wider ${
                        transaction.status === 'completed'
                          ? (isDarkMode ? 'bg-green-400/20 text-green-400' : 'bg-green-100 text-green-700')
                          : (isDarkMode ? 'bg-amber-400/20 text-amber-400' : 'bg-amber-100 text-amber-700')
                      }`}
                    >
                      {transaction.status}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Summary */}
      {transactions.length > 0 && (
        <div className={`${
          isDarkMode ? 'bg-zinc-900 border-zinc-800' : 'bg-gradient-to-r from-purple-50 to-blue-50 border-purple-100'
        } rounded-xl p-5 border`}>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className={`text-xs uppercase font-bold tracking-wider mb-1 ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>
                Total Received
              </div>
              <div className={`text-xl font-bold ${isDarkMode ? 'text-green-400' : 'text-green-600'}`}>
                ${transactions
                  .filter((t) => t.type === 'received')
                  .reduce((sum, t) => sum + t.amount, 0)
                  .toFixed(2)}
              </div>
            </div>
            <div>
              <div className={`text-xs uppercase font-bold tracking-wider mb-1 ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>
                Total Pushed
              </div>
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
      
      {!wallet.isExpired && activeQR && (
         <div className="pt-4 pb-8">
            <button
              onClick={onExpired}
              className={`w-full py-4 rounded-xl font-bold transition-all border ${
                isDarkMode 
                  ? 'border-red-500/30 text-red-400 hover:bg-red-500/10' 
                  : 'border-red-200 text-red-600 hover:bg-red-50'
              }`}
            >
              Force Expire & Transfer
            </button>
         </div>
      )}
    </div>
  );
}