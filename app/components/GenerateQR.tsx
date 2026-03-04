import { useState } from 'react';
import { ArrowLeft, Clock, DollarSign, Wallet } from 'lucide-react';
import type { TempWallet } from '@/app/App';

interface GenerateQRProps {
  wallets: TempWallet[];
  onGenerate: (limitType: 'time' | 'amount', value: number, walletId: string) => void;
  onBack: () => void;
  isDarkMode?: boolean;
}

export function GenerateQR({ wallets, onGenerate, onBack, isDarkMode }: GenerateQRProps) {
  const [limitType, setLimitType] = useState<'time' | 'amount'>('time');
  const [timeValue, setTimeValue] = useState(5); // in minutes
  const [amountValue, setAmountValue] = useState(100);
  const [selectedWalletId, setSelectedWalletId] = useState(wallets[0]?.id || '');

  const handleGenerate = () => {
    if (!selectedWalletId) return;
    const value = limitType === 'time' ? timeValue : amountValue;
    onGenerate(limitType, value, selectedWalletId);
  };

  const selectedWallet = wallets.find(w => w.id === selectedWalletId);

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
        <h2 className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Generate QR Code</h2>
      </div>

      {/* Wallet Selection */}
      <div className="space-y-3">
        <label className={`block text-sm font-medium flex items-center gap-2 ${isDarkMode ? 'text-zinc-400' : 'text-gray-700'}`}>
          <Wallet className="w-4 h-4" />
          Select Temporary Wallet
        </label>
        <div className="space-y-2">
          {wallets.map((wallet) => (
            <button
              key={wallet.id}
              onClick={() => setSelectedWalletId(wallet.id)}
              className={`w-full p-4 rounded-xl border-2 transition-all text-left ${
                selectedWalletId === wallet.id
                  ? (isDarkMode ? 'border-yellow-400 bg-yellow-400/10' : 'border-purple-500 bg-purple-50')
                  : (isDarkMode ? 'border-zinc-800 bg-zinc-900 hover:border-zinc-700' : 'border-gray-200 bg-white hover:border-gray-300')
              }`}
            >
              <div className="flex items-center justify-between">
                <div>
                  <div className={`font-semibold ${
                    selectedWalletId === wallet.id 
                      ? (isDarkMode ? 'text-yellow-400' : 'text-purple-900') 
                      : (isDarkMode ? 'text-zinc-100' : 'text-gray-900')
                  }`}>
                    {wallet.name}
                  </div>
                  <div className={`text-sm mt-1 ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>
                    Current balance: ${wallet.balance.toFixed(2)}
                  </div>
                </div>
                {selectedWalletId === wallet.id && (
                  <div className={`w-5 h-5 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-yellow-400' : 'bg-purple-500'}`}>
                    <svg className={`w-3 h-3 ${isDarkMode ? 'text-black' : 'text-white'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                )}
              </div>
            </button>
          ))}
        </div>
        <div className={`rounded-lg p-3 text-xs border ${
          isDarkMode ? 'bg-zinc-900/50 border-zinc-800 text-zinc-500' : 'bg-amber-50 border-amber-200 text-amber-900'
        }`}>
          💡 The selected wallet name will appear on the QR code
        </div>
      </div>

      {/* Limit Type Selection */}
      <div className="space-y-3">
        <label className={`block text-sm font-medium ${isDarkMode ? 'text-zinc-400' : 'text-gray-700'}`}>Select Limit Type</label>
        <div className="grid grid-cols-2 gap-3">
          <button
            onClick={() => setLimitType('time')}
            className={`p-4 rounded-xl border-2 transition-all ${
              limitType === 'time'
                ? (isDarkMode ? 'border-yellow-400 bg-yellow-400/10' : 'border-purple-500 bg-purple-50')
                : (isDarkMode ? 'border-zinc-800 bg-zinc-900 hover:border-zinc-700' : 'border-gray-200 bg-white hover:border-gray-300')
            }`}
          >
            <div className="flex flex-col items-center gap-2">
              <div
                className={`p-3 rounded-full ${
                  limitType === 'time' 
                    ? (isDarkMode ? 'bg-yellow-400' : 'bg-purple-500') 
                    : (isDarkMode ? 'bg-zinc-800' : 'bg-gray-200')
                }`}
              >
                <Clock className={`w-6 h-6 ${
                  limitType === 'time' 
                    ? (isDarkMode ? 'text-black' : 'text-white') 
                    : (isDarkMode ? 'text-zinc-400' : 'text-gray-600')
                }`} />
              </div>
              <span className={`font-medium ${
                limitType === 'time' 
                  ? (isDarkMode ? 'text-yellow-400' : 'text-purple-900') 
                  : (isDarkMode ? 'text-zinc-500' : 'text-gray-700')
              }`}>
                Time Limit
              </span>
            </div>
          </button>

          <button
            onClick={() => setLimitType('amount')}
            className={`p-4 rounded-xl border-2 transition-all ${
              limitType === 'amount'
                ? (isDarkMode ? 'border-yellow-400 bg-yellow-400/10' : 'border-purple-500 bg-purple-50')
                : (isDarkMode ? 'border-zinc-800 bg-zinc-900 hover:border-zinc-700' : 'border-gray-200 bg-white hover:border-gray-300')
            }`}
          >
            <div className="flex flex-col items-center gap-2">
              <div
                className={`p-3 rounded-full ${
                  limitType === 'amount' 
                    ? (isDarkMode ? 'bg-yellow-400' : 'bg-purple-500') 
                    : (isDarkMode ? 'bg-zinc-800' : 'bg-gray-200')
                }`}
              >
                <DollarSign
                  className={`w-6 h-6 ${
                    limitType === 'amount' 
                      ? (isDarkMode ? 'text-black' : 'text-white') 
                      : (isDarkMode ? 'text-zinc-400' : 'text-gray-600')
                  }`}
                />
              </div>
              <span className={`font-medium ${
                limitType === 'amount' 
                  ? (isDarkMode ? 'text-yellow-400' : 'text-purple-900') 
                  : (isDarkMode ? 'text-zinc-500' : 'text-gray-700')
              }`}>
                Amount Limit
              </span>
            </div>
          </button>
        </div>
      </div>

      {/* Settings Panel */}
      <div className={`rounded-xl p-6 border space-y-4 ${
        isDarkMode ? 'bg-zinc-900 border-zinc-800' : 'bg-white border-gray-200'
      }`}>
        <label className={`block text-sm font-medium ${isDarkMode ? 'text-zinc-400' : 'text-gray-700'}`}>
          {limitType === 'time' ? 'Duration (minutes)' : 'Maximum Amount ($)'}
        </label>
        <input
          type="range"
          min={limitType === 'time' ? "1" : "10"}
          max={limitType === 'time' ? "60" : "1000"}
          step={limitType === 'time' ? "1" : "10"}
          value={limitType === 'time' ? timeValue : amountValue}
          onChange={(e) => limitType === 'time' ? setTimeValue(Number(e.target.value)) : setAmountValue(Number(e.target.value))}
          className={`w-full h-2 rounded-lg appearance-none cursor-pointer ${
            isDarkMode ? 'bg-zinc-800 accent-yellow-400' : 'bg-purple-200 accent-purple-600'
          }`}
        />
        <div className="text-center">
          <div className={`text-4xl font-bold ${isDarkMode ? 'text-yellow-400' : 'text-purple-600'}`}>
            {limitType === 'time' ? timeValue : `$${amountValue}`}
          </div>
          <div className={`text-sm ${isDarkMode ? 'text-zinc-500' : 'text-gray-600'}`}>
            {limitType === 'time' ? 'minutes' : 'maximum'}
          </div>
        </div>
        <div className={`rounded-lg p-3 text-sm ${
          isDarkMode ? 'bg-zinc-800/50 text-zinc-400' : 'bg-purple-50 text-gray-700'
        }`}>
          {limitType === 'time' ? (
            <span>QR code will expire after <strong>{timeValue} minutes</strong>. Funds will auto-transfer on expiry.</span>
          ) : (
            <span>Accept multiple payments until <strong>${amountValue}</strong> is reached. Auto-transfer triggered at limit.</span>
          )}
        </div>
      </div>

      {/* Generate Button */}
      <button
        onClick={handleGenerate}
        disabled={!selectedWalletId}
        className={`w-full py-4 rounded-xl font-semibold transition-all shadow-lg disabled:opacity-50 disabled:cursor-not-allowed ${
          isDarkMode 
            ? 'bg-yellow-400 text-black hover:bg-yellow-300' 
            : 'bg-gradient-to-r from-purple-600 to-blue-600 text-white hover:from-purple-700 hover:to-blue-700'
        }`}
      >
        {selectedWallet ? `Generate QR for "${selectedWallet.name}"` : 'Generate QR Code'}
      </button>
    </div>
  );
}