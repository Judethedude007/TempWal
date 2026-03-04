import { Wallet, ArrowRight, QrCode, Shield, Plus } from 'lucide-react';
import type { TempWallet } from '@/app/App';

interface DashboardProps {
  realBalance: number;
  tempWallets: TempWallet[];
  expiredWallets: TempWallet[];
  totalTempBalance: number;
  onGenerateQR: () => void;
  onViewHistory: () => void;
  onManageWallets: () => void;
  hasActiveQR: boolean;
  onViewActiveQR: () => void;
  onTransferWallet: (walletId: string) => void;
  onViewWalletTransactions?: (walletId: string) => void;
  isDarkMode?: boolean;
}

export function Dashboard({
  realBalance,
  tempWallets,
  expiredWallets,
  totalTempBalance,
  onGenerateQR,
  onManageWallets,
  onViewWalletTransactions,
  isDarkMode,
}: DashboardProps) {
  return (
    <div className="p-6 space-y-6">
      {/* Real Account Balance Card */}
      <div className={`${
        isDarkMode 
          ? 'bg-zinc-800 border border-zinc-700' 
          : 'bg-gradient-to-br from-purple-600 to-blue-600'
      } rounded-2xl p-6 text-white shadow-lg`}>
        <div className="flex items-center gap-2 mb-4">
          <Wallet className="w-5 h-5 text-yellow-400" />
          <span className={`text-sm ${isDarkMode ? 'text-zinc-400' : 'opacity-90'}`}>Main Account</span>
        </div>
        <div className="space-y-1">
          <div className={`text-4xl font-bold ${isDarkMode ? 'text-yellow-400' : 'text-white'}`}>
            ${realBalance.toFixed(2)}
          </div>
          <div className={`text-sm ${isDarkMode ? 'text-zinc-500' : 'opacity-75'}`}>Available Balance</div>
        </div>
      </div>

      {/* Temporary Wallets Section */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className={`w-5 h-5 ${isDarkMode ? 'text-yellow-400' : 'text-amber-600'}`} />
            <span className={`font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Temporary Wallets</span>
          </div>
          <button
            onClick={onManageWallets}
            className={`flex items-center gap-1 text-sm font-medium ${
              isDarkMode ? 'text-yellow-400 hover:text-yellow-300' : 'text-purple-600 hover:text-purple-700'
            }`}
          >
            <Plus className="w-4 h-4" />
            Manage
          </button>
        </div>

        {/* Total Balance Summary */}
        <div className={`${
          isDarkMode ? 'bg-zinc-800/50 border border-zinc-700' : 'bg-amber-50 border-2 border-amber-200'
        } rounded-xl p-4`}>
          <div className={`text-sm mb-1 ${isDarkMode ? 'text-zinc-400' : 'text-amber-800'}`}>Total in Temporary Wallets</div>
          <div className={`text-2xl font-bold ${isDarkMode ? 'text-yellow-400' : 'text-amber-900'}`}>
            ${totalTempBalance.toFixed(2)}
          </div>
        </div>

        {/* Individual Active Wallets */}
        <div className="space-y-2">
          {tempWallets.length > 0 ? (
            tempWallets.map((wallet) => (
              <button
                key={wallet.id}
                onClick={() => onViewWalletTransactions?.(wallet.id)}
                className={`w-full rounded-xl p-4 shadow-sm border transition-all text-left flex items-center justify-between ${
                  isDarkMode 
                    ? 'bg-zinc-900 border-zinc-800 hover:border-yellow-400/50' 
                    : 'bg-white border-gray-200 hover:border-purple-300 hover:shadow-md'
                }`}
              >
                <div className="flex-1">
                  <div className={`font-medium ${isDarkMode ? 'text-zinc-100' : 'text-gray-900'}`}>{wallet.name}</div>
                  <div className={`text-lg font-bold mt-1 ${isDarkMode ? 'text-yellow-400' : 'text-purple-600'}`}>
                    ${wallet.balance.toFixed(2)}
                  </div>
                </div>
                <ArrowRight className={`w-5 h-5 ${isDarkMode ? 'text-zinc-600' : 'text-gray-400'}`} />
              </button>
            ))
          ) : (
            <div className={`text-center py-6 text-sm ${isDarkMode ? 'text-zinc-500' : 'text-gray-400'}`}>
              No active temporary wallets
            </div>
          )}
        </div>
      </div>

      {/* Expired Wallets Section */}
      {expiredWallets.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <div className={`w-1.5 h-1.5 rounded-full ${isDarkMode ? 'bg-zinc-600' : 'bg-gray-400'}`}></div>
            <span className={`text-sm font-semibold uppercase tracking-wider ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>
              Expired Wallets
            </span>
          </div>
          <div className="space-y-2 opacity-75">
            {expiredWallets.map((wallet) => (
              <button
                key={wallet.id}
                onClick={() => onViewWalletTransactions?.(wallet.id)}
                className={`w-full rounded-xl p-4 border transition-all text-left flex items-center justify-between ${
                  isDarkMode 
                    ? 'bg-zinc-950 border-zinc-800' 
                    : 'bg-gray-50 border-gray-200'
                }`}
              >
                <div className="flex-1">
                  <div className={`font-medium ${isDarkMode ? 'text-zinc-400' : 'text-gray-600'}`}>{wallet.name}</div>
                  <div className="text-xs text-zinc-500 mt-1 flex items-center gap-2">
                    <span>Expired</span>
                    <span>•</span>
                    <span>View History</span>
                  </div>
                </div>
                <ArrowRight className={`w-5 h-5 ${isDarkMode ? 'text-zinc-700' : 'text-gray-400'}`} />
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Add New Wallet Button */}
      <button
        onClick={onManageWallets}
        className={`w-full py-4 rounded-xl font-semibold flex items-center justify-center gap-2 transition-all shadow-lg ${
          isDarkMode 
            ? 'bg-yellow-400 text-black hover:bg-yellow-300' 
            : 'bg-gradient-to-r from-purple-600 to-blue-600 text-white hover:from-purple-700 hover:to-blue-700'
        }`}
      >
        <Plus className="w-5 h-5" />
        Add New Wallet
      </button>

      {/* Info Section */}
      <div className={`${
        isDarkMode ? 'bg-zinc-900 border-zinc-800' : 'bg-gradient-to-r from-purple-50 to-blue-50 border-purple-100'
      } rounded-xl p-5 border`}>
        <h3 className={`font-semibold mb-2 ${isDarkMode ? 'text-yellow-400' : 'text-gray-900'}`}>How it works</h3>
        <ul className={`space-y-2 text-sm ${isDarkMode ? 'text-zinc-400' : 'text-gray-700'}`}>
          <li className="flex gap-2">
            <span className={isDarkMode ? 'text-yellow-400' : 'text-purple-600'}>1.</span>
            <span>Create named wallets for different causes (Emergency, Disaster Relief, etc.)</span>
          </li>
          <li className="flex gap-2">
            <span className={isDarkMode ? 'text-yellow-400' : 'text-purple-600'}>2.</span>
            <span>Generate QR codes linked to specific wallets - multiple people can pay</span>
          </li>
          <li className="flex gap-2">
            <span className={isDarkMode ? 'text-yellow-400' : 'text-purple-600'}>3.</span>
            <span>All funds auto-transfer to main account when limits are reached</span>
          </li>
        </ul>
      </div>
    </div>
  );
}