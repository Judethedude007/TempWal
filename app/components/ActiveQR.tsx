import { useState, useEffect, useRef } from 'react';
import QRCode from 'react-qr-code';
import { ArrowLeft, Clock, DollarSign, ArrowRight, Zap, Share2 } from 'lucide-react';
import type { ActiveQRData, TempWallet } from '@/app/App';

interface ActiveQRProps {
  qrData: ActiveQRData;
  onExpired: () => void;
  onSimulatePayment: (amount: number) => void;
  onBack: () => void;
  onTransfer: () => void;
  currentWallet: TempWallet | null | undefined;
}

export function ActiveQR({ qrData, onExpired, onSimulatePayment, onBack, onTransfer, currentWallet }: ActiveQRProps) {
  const [timeRemaining, setTimeRemaining] = useState<number>(0);
  const [showPaymentSimulator, setShowPaymentSimulator] = useState(false);
  const [simulatedAmount, setSimulatedAmount] = useState(25);
  const qrContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (qrData.limitType === 'time' && qrData.timeLimit) {
      const interval = setInterval(() => {
        const elapsed = Math.floor((Date.now() - qrData.createdAt.getTime()) / 1000);
        const remaining = Math.max(0, (qrData.timeLimit || 0) - elapsed);
        setTimeRemaining(remaining);

        if (remaining === 0) {
          clearInterval(interval);
          onExpired();
        }
      }, 1000);

      return () => clearInterval(interval);
    }
  }, [qrData, onExpired]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getProgress = () => {
    if (qrData.limitType === 'time' && qrData.timeLimit) {
      return ((qrData.timeLimit - timeRemaining) / qrData.timeLimit) * 100;
    } else if (qrData.limitType === 'amount' && qrData.amountLimit) {
      return (qrData.currentAmount / qrData.amountLimit) * 100;
    }
    return 0;
  };

  const handleSimulatePayment = () => {
    onSimulatePayment(simulatedAmount);
    setShowPaymentSimulator(false);
  };

  const handleShare = async () => {
    const shareText = `Payment QR Code\nWallet: ${qrData.walletName}\nID: ${qrData.qrValue}\n\nScan to pay securely via SecurePay TempWallet`;
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'SecurePay QR Code',
          text: shareText,
        });
      } catch (err) {
        // User cancelled or share failed
        console.log('Share cancelled');
      }
    } else {
      // Fallback: copy to clipboard
      try {
        await navigator.clipboard.writeText(shareText);
        alert('QR Code details copied to clipboard!');
      } catch (err) {
        alert('Could not copy to clipboard');
      }
    }
  };

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          className="p-2 hover:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft className="w-6 h-6 text-gray-700" />
        </button>
        <h2 className="text-xl font-bold text-gray-900">Active QR Code</h2>
        <div className="w-10"></div>
      </div>

      {/* Status Card */}
      <div className="bg-gradient-to-br from-purple-600 to-blue-600 rounded-2xl p-6 text-white">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            {qrData.limitType === 'time' ? (
              <Clock className="w-5 h-5" />
            ) : (
              <DollarSign className="w-5 h-5" />
            )}
            <span className="text-sm opacity-90">
              {qrData.limitType === 'time' ? 'Time Remaining' : 'Amount Received'}
            </span>
          </div>
          <div className="px-3 py-1 bg-white/20 rounded-full text-xs font-medium">Active</div>
        </div>
        {/* Wallet Name Badge */}
        <div className="mb-3 inline-block px-3 py-1 bg-amber-400 text-amber-900 rounded-full text-sm font-semibold">
          {qrData.walletName}
        </div>
        <div className="text-3xl font-bold mb-2">
          {qrData.limitType === 'time' 
            ? formatTime(timeRemaining)
            : `$${qrData.currentAmount.toFixed(2)} / $${qrData.amountLimit?.toFixed(2)}`
          }
        </div>
        <div className="w-full bg-white/20 rounded-full h-2 overflow-hidden">
          <div
            className="bg-white h-full transition-all duration-500"
            style={{ width: `${getProgress()}%` }}
          />
        </div>
      </div>

      {/* QR Code Display with Watermark */}
      <div className="space-y-3">
        {/* QR Code Card */}
        <div className="bg-white rounded-2xl p-6 shadow-md border-2 border-purple-200">
          {/* TempVal Branding Header */}
          <div className="flex items-center justify-center gap-2 mb-4 pb-4 border-b border-gray-200">
            <div className="bg-amber-500 p-1.5 rounded-lg">
              <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
              </svg>
            </div>
            <div className="text-left">
              <div className="text-xs text-gray-500 font-medium">TempVal</div>
              <div className="text-sm font-bold text-purple-600">{qrData.walletName}</div>
            </div>
          </div>
          
          {/* QR Code */}
          <div className="flex justify-center">
            <div className="relative inline-block">
              <div className="bg-white p-4">
                <QRCode value={qrData.qrValue} size={200} />
              </div>
              
              {/* Watermark Overlay */}
              <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                <div className="bg-white/95 px-3 py-1.5 rounded-lg shadow-lg border-2 border-amber-400">
                  <div className="text-purple-600 font-bold text-xs text-center whitespace-nowrap">
                    {qrData.walletName}
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          {/* QR ID */}
          <div className="text-center mt-4">
            <div className="text-xs text-gray-500 mb-1">Payment ID</div>
            <div className="font-mono text-xs font-medium text-gray-900 bg-gray-100 px-3 py-2 rounded-lg inline-block">
              {qrData.qrValue}
            </div>
          </div>
        </div>

        {/* Share Button */}
        <button
          onClick={handleShare}
          className="w-full bg-gradient-to-r from-purple-600 to-blue-600 text-white py-3 rounded-xl font-semibold flex items-center justify-center gap-2 hover:from-purple-700 hover:to-blue-700 transition-all shadow-md"
        >
          <Share2 className="w-5 h-5" />
          Share QR Code
        </button>
      </div>

      {/* Temporary Wallet Balance */}
      <div className="bg-amber-50 border-2 border-amber-200 rounded-xl p-4">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-sm text-amber-800">{qrData.walletName}</div>
            <div className="text-2xl font-bold text-amber-900">
              ${currentWallet?.balance.toFixed(2) || '0.00'}
            </div>
          </div>
          {currentWallet && currentWallet.balance > 0 && (
            <button
              onClick={onTransfer}
              className="bg-amber-500 hover:bg-amber-600 text-white px-4 py-2 rounded-lg font-medium flex items-center gap-2 transition-colors"
            >
              Transfer Now
              <ArrowRight className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* Payment Simulator (for demo purposes) */}
      <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-4 space-y-3">
        <div className="flex items-center gap-2 text-blue-900">
          <Zap className="w-5 h-5" />
          <span className="font-semibold">Payment Simulator</span>
          <span className="text-xs bg-blue-200 px-2 py-0.5 rounded">Demo</span>
        </div>
        <div className="text-xs text-blue-700 bg-blue-100 rounded p-2">
          Simulate multiple payments from different people scanning this QR code
        </div>
        
        {!showPaymentSimulator ? (
          <button
            onClick={() => setShowPaymentSimulator(true)}
            className="w-full bg-blue-500 hover:bg-blue-600 text-white py-3 rounded-lg font-medium transition-colors"
          >
            Simulate Incoming Payment
          </button>
        ) : (
          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-blue-900 mb-2">Payment amount from one person ($)</label>
              <input
                type="number"
                value={simulatedAmount}
                onChange={(e) => setSimulatedAmount(Number(e.target.value))}
                className="w-full px-4 py-2 border-2 border-blue-300 rounded-lg focus:outline-none focus:border-blue-500"
                min="1"
                max="1000"
              />
            </div>
            {qrData.limitType === 'amount' && qrData.amountLimit && (
              <div className="text-xs text-blue-700 bg-blue-100 rounded p-2">
                Remaining to reach limit: ${(qrData.amountLimit - qrData.currentAmount).toFixed(2)}
              </div>
            )}
            <div className="flex gap-2">
              <button
                onClick={handleSimulatePayment}
                className="flex-1 bg-blue-500 hover:bg-blue-600 text-white py-2 rounded-lg font-medium transition-colors"
              >
                Receive ${simulatedAmount}
              </button>
              <button
                onClick={() => setShowPaymentSimulator(false)}
                className="px-4 bg-gray-200 hover:bg-gray-300 text-gray-700 py-2 rounded-lg font-medium transition-colors"
              >
                Cancel
              </button>
            </div>
          </div>
        )}
        
        {/* Quick amount buttons */}
        {!showPaymentSimulator && (
          <div className="grid grid-cols-4 gap-2">
            {[10, 25, 50, 100].map((amount) => (
              <button
                key={amount}
                onClick={() => {
                  setSimulatedAmount(amount);
                  handleSimulatePayment();
                }}
                className="bg-white border-2 border-blue-300 hover:bg-blue-100 text-blue-900 py-2 rounded-lg font-medium transition-colors text-sm"
              >
                ${amount}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Info */}
      <div className="bg-gray-50 rounded-xl p-4 text-sm text-gray-600 space-y-2">
        <p>
          {qrData.limitType === 'time' 
            ? `This QR code will expire when the timer reaches zero. All accumulated funds will be automatically transferred to your main account.`
            : `This QR code accepts multiple payments from different people. When the total reaches $${qrData.amountLimit}, all accumulated funds will be automatically transferred to your main account.`
          }
        </p>
        {qrData.limitType === 'amount' && (
          <div className="bg-purple-50 border border-purple-200 rounded p-3 text-xs">
            <strong>💡 How it works:</strong> Different people can scan this QR and pay any amount. 
            The payments accumulate in the <strong>{qrData.walletName}</strong> wallet until the total reaches ${qrData.amountLimit?.toFixed(2)}, 
            then everything transfers to your main account automatically.
          </div>
        )}
      </div>
    </div>
  );
}