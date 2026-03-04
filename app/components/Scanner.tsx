import { useState } from 'react';
import { ArrowLeft, ScanLine, Wallet, DollarSign } from 'lucide-react';
import type { ActiveQRData } from '@/app/App';

interface ScannerProps {
  availableQRCodes: ActiveQRData[];
  mainBalance: number;
  onPayment: (qrId: string, amount: number) => void;
  onBack: () => void;
  isDarkMode?: boolean;
}

export function Scanner({
  availableQRCodes,
  mainBalance,
  onPayment,
  onBack,
  isDarkMode,
}: ScannerProps) {
  const [selectedQR, setSelectedQR] = useState<ActiveQRData | null>(null);
  const [amount, setAmount] = useState('');
  const [error, setError] = useState('');

  const handlePayment = () => {
    if (!selectedQR) {
      setError('Please select a QR code to scan');
      return;
    }

    const paymentAmount = parseFloat(amount);
    if (isNaN(paymentAmount) || paymentAmount <= 0) {
      setError('Please enter a valid amount');
      return;
    }

    if (paymentAmount > mainBalance) {
      setError('Insufficient balance in main account');
      return;
    }

    if (selectedQR.limitType === 'amount') {
      const remaining = (selectedQR.amountLimit || 0) - selectedQR.currentAmount;
      if (paymentAmount > remaining) {
        setError(`This QR can only accept $${remaining.toFixed(2)} more`);
        return;
      }
    }

    onPayment(selectedQR.id, paymentAmount);
    setAmount('');
    setSelectedQR(null);
    setError('');
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="p-6 border-b border-opacity-20">
        <button
          onClick={onBack}
          className={`flex items-center gap-2 mb-4 ${
            isDarkMode ? 'text-yellow-400 hover:text-yellow-300' : 'text-purple-600 hover:text-purple-700'
          }`}
        >
          <ArrowLeft className="w-5 h-5" />
          Back
        </button>
        <div className="flex items-center gap-3">
          <div className={`p-3 rounded-xl ${isDarkMode ? 'bg-yellow-400/10' : 'bg-purple-100'}`}>
            <ScanLine className={`w-6 h-6 ${isDarkMode ? 'text-yellow-400' : 'text-purple-600'}`} />
          </div>
          <div>
            <h2 className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
              Scan & Pay
            </h2>
            <p className={`text-sm ${isDarkMode ? 'text-zinc-400' : 'text-gray-600'}`}>
              Pay to temporary wallet QR codes
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-6 space-y-6">
        {/* Main Balance Display */}
        <div className={`${
          isDarkMode ? 'bg-zinc-800 border border-zinc-700' : 'bg-gradient-to-br from-purple-600 to-blue-600'
        } rounded-2xl p-5 text-white`}>
          <div className="flex items-center gap-2 mb-2">
            <Wallet className="w-5 h-5 text-yellow-400" />
            <span className="text-sm opacity-90">Available Balance</span>
          </div>
          <div className={`text-3xl font-bold ${isDarkMode ? 'text-yellow-400' : 'text-white'}`}>
            ${mainBalance.toFixed(2)}
          </div>
        </div>

        {/* Available QR Codes */}
        <div className="space-y-3">
          <h3 className={`font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
            Active QR Codes
          </h3>
          
          {availableQRCodes.length > 0 ? (
            <div className="space-y-2">
              {availableQRCodes.map((qr) => {
                const isExpired = qr.expiresAt && qr.expiresAt < new Date();
                const isComplete = qr.limitType === 'amount' && qr.currentAmount >= (qr.amountLimit || 0);
                const isDisabled = isExpired || isComplete;
                
                return (
                  <button
                    key={qr.id}
                    onClick={() => !isDisabled && setSelectedQR(qr)}
                    disabled={isDisabled}
                    className={`w-full p-4 rounded-xl border-2 text-left transition-all ${
                      selectedQR?.id === qr.id
                        ? (isDarkMode 
                            ? 'border-yellow-400 bg-yellow-400/10' 
                            : 'border-purple-600 bg-purple-50')
                        : (isDarkMode 
                            ? 'border-zinc-800 bg-zinc-900 hover:border-zinc-700' 
                            : 'border-gray-200 bg-white hover:border-purple-200')
                    } ${isDisabled ? 'opacity-50 cursor-not-allowed' : ''}`}
                  >
                    <div className="flex justify-between items-start mb-2">
                      <div>
                        <div className={`font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                          {qr.walletName}
                        </div>
                        <div className={`text-sm ${isDarkMode ? 'text-zinc-400' : 'text-gray-600'}`}>
                          {qr.limitType === 'time' ? 'Time-based' : 'Amount-based'} QR
                        </div>
                      </div>
                      {selectedQR?.id === qr.id && (
                        <div className={`w-6 h-6 rounded-full flex items-center justify-center ${
                          isDarkMode ? 'bg-yellow-400' : 'bg-purple-600'
                        }`}>
                          <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        </div>
                      )}
                    </div>
                    {qr.limitType === 'amount' && (
                      <div className="mt-2">
                        <div className={`text-xs mb-1 ${isDarkMode ? 'text-zinc-500' : 'text-gray-500'}`}>
                          Progress: ${qr.currentAmount.toFixed(2)} / ${qr.amountLimit?.toFixed(2)}
                        </div>
                        <div className={`h-2 rounded-full overflow-hidden ${isDarkMode ? 'bg-zinc-800' : 'bg-gray-200'}`}>
                          <div
                            className={`h-full ${isDarkMode ? 'bg-yellow-400' : 'bg-purple-600'}`}
                            style={{ width: `${Math.min(100, (qr.currentAmount / (qr.amountLimit || 1)) * 100)}%` }}
                          />
                        </div>
                      </div>
                    )}
                    {isDisabled && (
                      <div className={`text-xs mt-2 ${isDarkMode ? 'text-red-400' : 'text-red-600'}`}>
                        {isExpired ? 'Expired' : 'Target reached'}
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          ) : (
            <div className={`text-center py-8 rounded-xl ${
              isDarkMode ? 'bg-zinc-900 text-zinc-500' : 'bg-gray-50 text-gray-400'
            }`}>
              <ScanLine className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>No active QR codes available</p>
              <p className="text-sm mt-1">Generate a QR code from a wallet first</p>
            </div>
          )}
        </div>

        {/* Payment Amount */}
        {selectedQR && (
          <div className="space-y-3">
            <label className={`block font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
              Payment Amount
            </label>
            <div className="relative">
              <DollarSign className={`absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 ${
                isDarkMode ? 'text-zinc-500' : 'text-gray-400'
              }`} />
              <input
                type="number"
                value={amount}
                onChange={(e) => {
                  setAmount(e.target.value);
                  setError('');
                }}
                placeholder="0.00"
                step="0.01"
                className={`w-full pl-10 pr-4 py-3 rounded-xl border-2 transition-colors ${
                  isDarkMode 
                    ? 'bg-zinc-900 border-zinc-800 text-white placeholder-zinc-600 focus:border-yellow-400' 
                    : 'bg-white border-gray-300 text-gray-900 placeholder-gray-400 focus:border-purple-600'
                } focus:outline-none`}
              />
            </div>
            {error && (
              <p className={`text-sm ${isDarkMode ? 'text-red-400' : 'text-red-600'}`}>
                {error}
              </p>
            )}
          </div>
        )}
      </div>

      {/* Pay Button */}
      {selectedQR && (
        <div className={`p-6 border-t ${isDarkMode ? 'border-zinc-800' : 'border-gray-200'}`}>
          <button
            onClick={handlePayment}
            className={`w-full py-4 rounded-xl font-semibold transition-all ${
              isDarkMode 
                ? 'bg-yellow-400 text-black hover:bg-yellow-300' 
                : 'bg-gradient-to-r from-purple-600 to-blue-600 text-white hover:from-purple-700 hover:to-blue-700'
            }`}
          >
            Pay ${amount || '0.00'}
          </button>
        </div>
      )}
    </div>
  );
}
