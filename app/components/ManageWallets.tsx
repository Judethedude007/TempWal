import { useState } from 'react';
import { ArrowLeft, Plus, Trash2, Shield, AlertCircle, Eye } from 'lucide-react';
import type { TempWallet } from '@/app/App';

interface ManageWalletsProps {
  wallets: TempWallet[];
  onAddWallet: (name: string) => void;
  onDeleteWallet: (walletId: string) => void;
  onBack: () => void;
  onViewTransactions: (walletId: string) => void;
  isDarkMode?: boolean;
}

export function ManageWallets({ wallets, onAddWallet, onDeleteWallet, onBack, onViewTransactions, isDarkMode }: ManageWalletsProps) {
  const [showAddForm, setShowAddForm] = useState(false);
  const [newWalletName, setNewWalletName] = useState('');

  const handleAddWallet = () => {
    if (newWalletName.trim()) {
      onAddWallet(newWalletName.trim());
      setNewWalletName('');
      setShowAddForm(false);
    }
  };

  const suggestedNames = [
    'Emergency Fund',
    'Disaster Relief',
    'Medical Emergency',
    'Water Relief',
    'Food Aid',
    'Education Fund',
    'Housing Support',
    'Community Fund',
  ];

  return (
    <div className={`p-6 space-y-6 min-h-full ${isDarkMode ? 'bg-black text-white' : 'bg-gray-50'}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          className={`p-2 rounded-full transition-colors ${
            isDarkMode ? 'hover:bg-zinc-800 text-yellow-400' : 'hover:bg-gray-100 text-gray-700'
          }`}
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h2 className={`text-xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Manage Wallets</h2>
        <div className="w-10"></div>
      </div>

      {/* Add Wallet Button */}
      {!showAddForm && (
        <button
          onClick={() => setShowAddForm(true)}
          className={`w-full py-4 rounded-xl font-semibold flex items-center justify-center gap-2 transition-all shadow-lg ${
            isDarkMode 
              ? 'bg-yellow-400 text-black hover:bg-yellow-300' 
              : 'bg-gradient-to-r from-purple-600 to-blue-600 text-white hover:from-purple-700 hover:to-blue-700'
          }`}
        >
          <Plus className="w-5 h-5" />
          Add New Wallet
        </button>
      )}

      {/* Add Wallet Form */}
      {showAddForm && (
        <div className={`rounded-2xl p-6 shadow-md border-2 space-y-4 ${
          isDarkMode ? 'bg-zinc-900 border-yellow-400/30' : 'bg-white border-purple-200'
        }`}>
          <div>
            <label className={`block text-sm font-semibold mb-2 ${isDarkMode ? 'text-zinc-300' : 'text-gray-900'}`}>
              Wallet Name / Cause
            </label>
            <input
              type="text"
              value={newWalletName}
              onChange={(e) => setNewWalletName(e.target.value)}
              placeholder="e.g., Emergency Fund"
              className={`w-full px-4 py-3 border-2 rounded-xl focus:outline-none transition-colors ${
                isDarkMode 
                  ? 'bg-black border-zinc-800 focus:border-yellow-400 text-white' 
                  : 'bg-white border-gray-300 focus:border-purple-500 text-gray-900'
              }`}
              autoFocus
            />
          </div>

          {/* Suggested Names */}
          <div>
            <div className={`text-xs mb-2 ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>Quick suggestions:</div>
            <div className="flex flex-wrap gap-2">
              {suggestedNames.map((name) => (
                <button
                  key={name}
                  onClick={() => setNewWalletName(name)}
                  className={`px-3 py-1.5 text-xs rounded-lg border transition-colors ${
                    isDarkMode 
                      ? 'bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border-zinc-700' 
                      : 'bg-purple-50 hover:bg-purple-100 text-purple-700 border-purple-200'
                  }`}
                >
                  {name}
                </button>
              ))}
            </div>
          </div>

          <div className="flex gap-2 pt-2">
            <button
              onClick={handleAddWallet}
              disabled={!newWalletName.trim()}
              className={`flex-1 py-3 rounded-xl font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                isDarkMode 
                  ? 'bg-yellow-400 text-black hover:bg-yellow-300' 
                  : 'bg-purple-600 text-white hover:bg-purple-700'
              }`}
            >
              Create Wallet
            </button>
            <button
              onClick={() => {
                setShowAddForm(false);
                setNewWalletName('');
              }}
              className={`px-6 py-3 rounded-xl font-semibold transition-colors ${
                isDarkMode 
                  ? 'bg-zinc-800 text-zinc-400 hover:bg-zinc-700' 
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Info Box */}
      <div className={`rounded-xl p-4 flex gap-3 border ${
        isDarkMode ? 'bg-zinc-900/50 border-zinc-800 text-zinc-400' : 'bg-blue-50 border-blue-200 text-blue-900'
      }`}>
        <AlertCircle className={`w-5 h-5 flex-shrink-0 mt-0.5 ${isDarkMode ? 'text-yellow-400' : 'text-blue-600'}`} />
        <div className="text-sm">
          <p className={`font-medium mb-1 ${isDarkMode ? 'text-white' : ''}`}>Multiple Wallets for Different Causes</p>
          <p className={isDarkMode ? 'text-zinc-500' : 'text-blue-700'}>
            Create separate wallets for different emergencies or fundraising campaigns. 
            Each wallet can have its own QR code, and all funds eventually transfer to your main account.
          </p>
        </div>
      </div>

      {/* Wallets List */}
      <div className="space-y-3">
        <h3 className={`font-semibold flex items-center gap-2 ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
          <Shield className={`w-5 h-5 ${isDarkMode ? 'text-yellow-400' : 'text-amber-600'}`} />
          Your Temporary Wallets ({wallets.length})
        </h3>

        {wallets.length === 0 ? (
          <div className={`border-2 border-dashed rounded-xl p-8 text-center ${
            isDarkMode ? 'bg-zinc-900/30 border-zinc-800' : 'bg-gray-50 border-gray-300'
          }`}>
            <Shield className={`w-12 h-12 mx-auto mb-3 ${isDarkMode ? 'text-zinc-800' : 'text-gray-400'}`} />
            <p className={`font-medium ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>No wallets yet</p>
            <p className={`text-sm mt-1 ${isDarkMode ? 'text-zinc-600' : 'text-gray-500'}`}>Create your first temporary wallet to get started</p>
          </div>
        ) : (
          <div className="space-y-2">
            {wallets.map((wallet) => (
              <div
                key={wallet.id}
                className={`rounded-xl p-5 shadow-sm border transition-colors ${
                  isDarkMode 
                    ? 'bg-zinc-900 border-zinc-800 hover:border-yellow-400/30' 
                    : 'bg-white border-gray-200 hover:border-purple-300'
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1">
                    <div className={`font-semibold text-lg ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{wallet.name}</div>
                    <div className={`text-2xl font-bold mt-1 ${isDarkMode ? 'text-yellow-400' : 'text-purple-600'}`}>
                      ${wallet.balance.toFixed(2)}
                    </div>
                    <div className={`text-xs mt-2 ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>
                      Created {wallet.createdAt.toLocaleDateString()}
                    </div>
                    {wallet.balance > 0 && (
                      <div className={`mt-2 inline-block px-2 py-1 text-xs rounded font-medium ${
                        isDarkMode ? 'bg-yellow-400/20 text-yellow-400' : 'bg-amber-100 text-amber-800'
                      }`}>
                        Has pending funds
                      </div>
                    )}
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => onViewTransactions(wallet.id)}
                      className={`p-2 rounded-lg transition-colors group ${isDarkMode ? 'hover:bg-zinc-800' : 'hover:bg-gray-100'}`}
                    >
                      <Eye className={`w-5 h-5 ${isDarkMode ? 'text-zinc-600 group-hover:text-yellow-400' : 'text-gray-400 group-hover:text-gray-600'}`} />
                    </button>
                    <button
                      onClick={() => {
                        if (wallet.balance > 0) {
                          if (confirm(`This wallet has $${wallet.balance.toFixed(2)}. Funds will be transferred to your main account before deletion. Continue?`)) {
                            onDeleteWallet(wallet.id);
                          }
                        } else {
                          if (confirm(`Delete "${wallet.name}" wallet?`)) {
                            onDeleteWallet(wallet.id);
                          }
                        }
                      }}
                      className={`p-2 rounded-lg transition-colors group ${isDarkMode ? 'hover:bg-red-900/20' : 'hover:bg-red-50'}`}
                    >
                      <Trash2 className={`w-5 h-5 ${isDarkMode ? 'text-zinc-600 group-hover:text-red-400' : 'text-gray-400 group-hover:text-red-600'}`} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}