import { useState } from 'react';
import { Dashboard } from '@/app/components/Dashboard';
import { GenerateQR } from '@/app/components/GenerateQR';
import { ActiveQR } from '@/app/components/ActiveQR';
import { TransactionHistory } from '@/app/components/TransactionHistory';
import { ManageWallets } from '@/app/components/ManageWallets';
import { WalletTransactions } from '@/app/components/WalletTransactions';
import { Scanner } from '@/app/components/Scanner';
import { Settings, ScanLine } from 'lucide-react';

export interface TempWallet {
  id: string;
  name: string;
  balance: number;
  createdAt: Date;
  isExpired?: boolean;
}

export interface Transaction {
  id: string;
  type: 'received' | 'transferred';
  amount: number;
  timestamp: Date;
  status: 'pending' | 'completed';
  walletId: string;
  walletName: string;
}

export interface ActiveQRData {
  id: string;
  qrValue: string;
  limitType: 'time' | 'amount';
  timeLimit?: number; // in seconds
  amountLimit?: number;
  createdAt: Date;
  expiresAt?: Date;
  currentAmount: number;
  walletId: string;
  walletName: string;
}

export default function App() {
  const [realAccountBalance, setRealAccountBalance] = useState(5420.50);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [tempWallets, setTempWallets] = useState<TempWallet[]>([
    { id: 'wallet-1', name: 'Emergency Fund', balance: 0, createdAt: new Date() }
  ]);
  const [activeQR, setActiveQR] = useState<ActiveQRData | null>(null);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [currentView, setCurrentView] = useState<'dashboard' | 'generate' | 'active' | 'history' | 'wallets' | 'wallet-transactions' | 'scanner'>('dashboard');
  const [selectedWalletId, setSelectedWalletId] = useState<string | null>(null);

  const toggleTheme = () => setIsDarkMode(!isDarkMode);

  const handleAddWallet = (name: string) => {
    const newWallet: TempWallet = {
      id: `wallet-${Date.now()}`,
      name,
      balance: 0,
      createdAt: new Date(),
    };
    setTempWallets(prev => [...prev, newWallet]);
  };

  const handleDeleteWallet = (walletId: string) => {
    const wallet = tempWallets.find(w => w.id === walletId);
    if (wallet && wallet.balance > 0) {
      // Transfer remaining balance to main account before deleting
      handleTransferWalletToRealAccount(walletId);
    }
    setTempWallets(prev => prev.filter(w => w.id !== walletId));
  };

  const handleGenerateQR = (limitType: 'time' | 'amount', value: number, walletId: string) => {
    const wallet = tempWallets.find(w => w.id === walletId);
    if (!wallet) return;

    const qrId = `QR-${Date.now()}`;
    const qrData: ActiveQRData = {
      id: qrId,
      qrValue: qrId,
      limitType,
      timeLimit: limitType === 'time' ? value * 60 : undefined,
      amountLimit: limitType === 'amount' ? value : undefined,
      createdAt: new Date(),
      expiresAt: limitType === 'time' ? new Date(Date.now() + value * 60 * 1000) : undefined,
      currentAmount: 0,
      walletId: wallet.id,
      walletName: wallet.name,
    };
    setActiveQR(qrData);
    setSelectedWalletId(walletId);
    setCurrentView('wallet-transactions'); // Show the wallet with the QR immediately
  };

  const handleSimulatePayment = (amount: number) => {
    if (!activeQR) return;

    const newTransaction: Transaction = {
      id: `TXN-${Date.now()}`,
      type: 'received',
      amount,
      timestamp: new Date(),
      status: 'pending',
      walletId: activeQR.walletId,
      walletName: activeQR.walletName,
    };

    setTransactions(prev => [newTransaction, ...prev]);
    
    // Update specific wallet balance
    setTempWallets(prev => prev.map(wallet => 
      wallet.id === activeQR.walletId 
        ? { ...wallet, balance: wallet.balance + amount }
        : wallet
    ));

    const updatedQR = {
      ...activeQR,
      currentAmount: activeQR.currentAmount + amount,
    };
    setActiveQR(updatedQR);

    // Check if amount limit is reached
    if (activeQR.limitType === 'amount' && updatedQR.currentAmount >= (activeQR.amountLimit || 0)) {
      handleTransferWalletToRealAccount(activeQR.walletId);
      handleQRExpired();
    }
  };

  const handleQRExpired = () => {
    if (activeQR) {
      const walletId = activeQR.walletId;
      const wallet = tempWallets.find(w => w.id === walletId);
      
      // Transfer funds
      if (wallet && wallet.balance > 0) {
        handleTransferWalletToRealAccount(walletId);
      }

      // Mark wallet as expired
      setTempWallets(prev => prev.map(w => 
        w.id === walletId ? { ...w, isExpired: true } : w
      ));
    }
    setActiveQR(null);
    setCurrentView('dashboard');
  };

  const handleScannerPayment = (qrId: string, amount: number) => {
    const qr = activeQR;
    if (!qr || qr.id !== qrId) return;

    // Deduct from main balance
    setRealAccountBalance(prev => prev - amount);

    // Add to wallet
    setTempWallets(prev => prev.map(wallet => 
      wallet.id === qr.walletId 
        ? { ...wallet, balance: wallet.balance + amount }
        : wallet
    ));

    // Create transaction
    const newTransaction: Transaction = {
      id: `TXN-${Date.now()}`,
      type: 'received',
      amount,
      timestamp: new Date(),
      status: 'pending',
      walletId: qr.walletId,
      walletName: qr.walletName,
    };
    setTransactions(prev => [newTransaction, ...prev]);

    // Update QR current amount
    const updatedQR = {
      ...qr,
      currentAmount: qr.currentAmount + amount,
    };
    setActiveQR(updatedQR);

    // Check if amount limit is reached
    if (qr.limitType === 'amount' && updatedQR.currentAmount >= (qr.amountLimit || 0)) {
      handleTransferWalletToRealAccount(qr.walletId);
      handleQRExpired();
    }

    // Go back to dashboard
    setCurrentView('dashboard');
  };

  const handleTransferWalletToRealAccount = (walletId: string) => {
    const wallet = tempWallets.find(w => w.id === walletId);
    if (!wallet || wallet.balance <= 0) return;

    const transferAmount = wallet.balance;
    
    const transferTransaction: Transaction = {
      id: `TXN-${Date.now()}`,
      type: 'transferred',
      amount: transferAmount,
      timestamp: new Date(),
      status: 'completed',
      walletId: wallet.id,
      walletName: wallet.name,
    };

    setTransactions(prev => {
      const updatedTransactions = prev.map(txn => 
        txn.walletId === walletId && txn.status === 'pending' 
          ? { ...txn, status: 'completed' as const } 
          : txn
      );
      return [transferTransaction, ...updatedTransactions];
    });

    setRealAccountBalance(prev => prev + transferAmount);
    setTempWallets(prev => prev.map(w => 
      w.id === walletId ? { ...w, balance: 0 } : w
    ));
    
    // We don't nullify activeQR here unless it's expired, 
    // but the requirement said transfers only happen when conditions are met.
  };

  const getTotalTempBalance = () => {
    return tempWallets
      .filter(w => !w.isExpired)
      .reduce((sum, wallet) => sum + wallet.balance, 0);
  };

  const getCurrentWallet = () => {
    if (!activeQR) return null;
    return tempWallets.find(w => w.id === activeQR.walletId);
  };

  const handleViewWalletTransactions = (walletId: string) => {
    setSelectedWalletId(walletId);
    setCurrentView('wallet-transactions');
  };

  const activeWallets = tempWallets.filter(w => !w.isExpired);
  const expiredWallets = tempWallets.filter(w => w.isExpired);

  return (
    <div className={`min-h-screen transition-colors duration-300 ${
      isDarkMode 
        ? 'bg-black text-white' 
        : 'bg-gradient-to-br from-purple-900 via-blue-900 to-purple-800'
    }`}>
      {/* Mobile App Container */}
      <div className={`max-w-md mx-auto min-h-screen shadow-2xl flex flex-col transition-colors duration-300 ${
        isDarkMode ? 'bg-zinc-900' : 'bg-white'
      }`}>
        {/* Header */}
        <div className={`${
          isDarkMode 
            ? 'bg-zinc-900 border-b border-zinc-800' 
            : 'bg-gradient-to-r from-purple-600 to-blue-600'
        } text-white p-6 pb-8`}>
          <div className="flex justify-between items-center mb-6">
            <h1 className={`text-2xl font-bold ${isDarkMode ? 'text-yellow-400' : 'text-white'}`}>TempWal</h1>
            <button 
              onClick={toggleTheme}
              className={`p-2 rounded-full transition-colors ${
                isDarkMode ? 'hover:bg-zinc-800 text-yellow-400' : 'hover:bg-white/20 text-white'
              }`}
            >
              <Settings className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className={`flex-1 -mt-4 transition-colors duration-300 ${
          isDarkMode ? 'bg-black' : 'bg-gray-50'
        } rounded-t-3xl overflow-hidden`}>
          {currentView === 'dashboard' && (
            <Dashboard
              realBalance={realAccountBalance}
              tempWallets={activeWallets}
              expiredWallets={expiredWallets}
              totalTempBalance={getTotalTempBalance()}
              onGenerateQR={() => setCurrentView('generate')}
              onViewHistory={() => setCurrentView('history')}
              onManageWallets={() => setCurrentView('wallets')}
              hasActiveQR={!!activeQR}
              onViewActiveQR={() => setCurrentView('active')}
              onTransferWallet={handleTransferWalletToRealAccount}
              onViewWalletTransactions={handleViewWalletTransactions}
              isDarkMode={isDarkMode}
            />
          )}

          {currentView === 'generate' && (
            <GenerateQR
              wallets={activeWallets}
              onGenerate={handleGenerateQR}
              onBack={() => setCurrentView('dashboard')}
              isDarkMode={isDarkMode}
            />
          )}

          {currentView === 'active' && activeQR && (
            <ActiveQR
              qrData={activeQR}
              onExpired={handleQRExpired}
              onSimulatePayment={handleSimulatePayment}
              onBack={() => setCurrentView('dashboard')}
              onTransfer={() => handleTransferWalletToRealAccount(activeQR.walletId)}
              currentWallet={getCurrentWallet()}
              isDarkMode={isDarkMode}
            />
          )}

          {currentView === 'history' && (
            <TransactionHistory
              transactions={transactions}
              onBack={() => setCurrentView('dashboard')}
              isDarkMode={isDarkMode}
            />
          )}

          {currentView === 'wallets' && (
            <ManageWallets
              wallets={activeWallets}
              onAddWallet={handleAddWallet}
              onDeleteWallet={handleDeleteWallet}
              onBack={() => setCurrentView('dashboard')}
              onViewTransactions={handleViewWalletTransactions}
              isDarkMode={isDarkMode}
            />
          )}

          {currentView === 'wallet-transactions' && selectedWalletId && (
            <WalletTransactions
              wallet={tempWallets.find(w => w.id === selectedWalletId)!}
              activeQR={activeQR?.walletId === selectedWalletId ? activeQR : null}
              transactions={transactions.filter(txn => txn.walletId === selectedWalletId)}
              onBack={() => setCurrentView('dashboard')}
              onExpired={handleQRExpired}
              onSimulatePayment={handleSimulatePayment}
              isDarkMode={isDarkMode}
            />
          )}

          {currentView === 'scanner' && (
            <Scanner
              availableQRCodes={activeQR ? [activeQR] : []}
              mainBalance={realAccountBalance}
              onPayment={handleScannerPayment}
              onBack={() => setCurrentView('dashboard')}
              isDarkMode={isDarkMode}
            />
          )}
        </div>

        {/* Floating Scanner Button - Only on Dashboard */}
        {currentView === 'dashboard' && (
          <div className="relative">
            <div className="absolute left-1/2 -translate-x-1/2 -top-8 z-10">
              <button
                onClick={() => setCurrentView('scanner')}
                className={`w-16 h-16 rounded-full shadow-2xl flex items-center justify-center transition-all hover:scale-110 ${
                  isDarkMode 
                    ? 'bg-yellow-400 text-black hover:bg-yellow-300' 
                    : 'bg-gradient-to-br from-purple-600 to-blue-600 text-white hover:from-purple-700 hover:to-blue-700'
                }`}
              >
                <ScanLine className="w-8 h-8" />
              </button>
            </div>
          </div>
        )}

        {/* Bottom Navigation */}
        <div className={`border-t p-4 grid grid-cols-3 gap-2 transition-colors duration-300 ${
          isDarkMode ? 'bg-zinc-900 border-zinc-800' : 'bg-white border-gray-200'
        }`}>
          <button
            onClick={() => setCurrentView('dashboard')}
            className={`p-3 rounded-lg transition-colors ${
              currentView === 'dashboard'
                ? (isDarkMode ? 'bg-yellow-400/10 text-yellow-400' : 'bg-purple-100 text-purple-600')
                : (isDarkMode ? 'text-zinc-400 hover:bg-zinc-800' : 'text-gray-600 hover:bg-gray-100')
            }`}
          >
            <div className="flex flex-col items-center gap-1">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span className="text-xs font-medium">Home</span>
            </div>
          </button>
          <button
            onClick={() => setCurrentView('generate')}
            className={`p-3 rounded-lg transition-colors ${
              currentView === 'generate'
                ? (isDarkMode ? 'bg-yellow-400/10 text-yellow-400' : 'bg-purple-100 text-purple-600')
                : (isDarkMode ? 'text-zinc-400 hover:bg-zinc-800' : 'text-gray-600 hover:bg-gray-100')
            }`}
          >
            <div className="flex flex-col items-center gap-1">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              <span className="text-xs font-medium">Generate</span>
            </div>
          </button>
          <button
            onClick={() => setCurrentView('history')}
            className={`p-3 rounded-lg transition-colors ${
              currentView === 'history'
                ? (isDarkMode ? 'bg-yellow-400/10 text-yellow-400' : 'bg-purple-100 text-purple-600')
                : (isDarkMode ? 'text-zinc-400 hover:bg-zinc-800' : 'text-gray-600 hover:bg-gray-100')
            }`}
          >
            <div className="flex flex-col items-center gap-1">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="text-xs font-medium">History</span>
            </div>
          </button>
        </div>
      </div>
    </div>
  );
}