import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/models.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  double realAccountBalance = 5420.50;
  bool isDarkMode = false;
  List<TempWallet> tempWallets = [
    TempWallet(
      id: 'wallet-1',
      name: 'Emergency Fund',
      balance: 0,
      createdAt: DateTime.now(),
    ),
  ];
  ActiveQRData? activeQR;
  final List<WalletTransaction> transactions = [];
  String currentView = 'dashboard';
  String? selectedWalletId;
  StreamSubscription? _qrSubscription;
  StreamSubscription? _authSubscription;

  Future<void> _init() async {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      }
      notifyListeners();
    });
    await _loadFromCache();
  }

  // --- Auth Logic ---
  
  Future<void> signUp(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        realAccountBalance = (data['balance'] as num).toDouble();
      } else {
        realAccountBalance = 5000.0;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'balance': 5000.0,
          'email': _user?.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // --- Persistence Logic ---

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      
      final walletsJson = prefs.getString('tempWallets');
      if (walletsJson != null) {
        final List<dynamic> decoded = jsonDecode(walletsJson);
        tempWallets = decoded.map((item) => TempWallet.fromJson(item)).toList();
      }

      final activeQrJson = prefs.getString('activeQR');
      if (activeQrJson != null) {
        activeQR = ActiveQRData.fromJson(jsonDecode(activeQrJson));
        _listenToQR(activeQR!.id);
      }

      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        transactions.clear();
        transactions.addAll(decoded.map((item) => WalletTransaction.fromJson(item)));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setString('tempWallets', jsonEncode(tempWallets.map((w) => w.toJson()).toList()));
    await prefs.setString('transactions', jsonEncode(transactions.map((t) => t.toJson()).toList()));
    if (activeQR != null) {
      await prefs.setString('activeQR', jsonEncode(activeQR!.toJson()));
    } else {
      await prefs.remove('activeQR');
    }
  }

  // --- Real-time Logic ---

  void _listenToQR(String qrId) {
    _qrSubscription?.cancel();
    _qrSubscription = FirebaseFirestore.instance.collection('payments').doc(qrId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['status'] == 'completed') {
          final amount = (data['amount'] as num).toDouble();
          final senderName = data['senderName'] ?? 'Someone';
          final txnId = data['transactionId'] ?? 'CLD-${DateTime.now().millisecondsSinceEpoch}';
          if (!transactions.any((t) => t.id == txnId)) {
            _processIncomingPayment(amount, senderName, txnId);
          }
        }
      }
    });
  }

  void _processIncomingPayment(double amount, String senderName, String txnId) {
    if (activeQR == null) return;
    transactions.insert(0, WalletTransaction(
      id: txnId, 
      type: TransactionType.received, 
      amount: amount, 
      timestamp: DateTime.now(), 
      status: TransactionStatus.completed, // Received payments are instant
      walletId: activeQR!.walletId, 
      walletName: activeQR!.walletName,
      otherPartyName: senderName,
    ));
    tempWallets = tempWallets.map((wallet) => wallet.id == activeQR!.walletId ? wallet.copyWith(balance: wallet.balance + amount) : wallet).toList();
    activeQR = activeQR!.copyWith(currentAmount: activeQR!.currentAmount + amount);
    if (activeQR!.limitType == LimitType.amount && (activeQR!.amountLimit ?? 0) <= activeQR!.currentAmount) {
      transferWalletToRealAccount(activeQR!.walletId, auto: true);
      expireQR();
    }
    _saveToCache();
    notifyListeners();
  }

  // --- Actions ---

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    _saveToCache();
    notifyListeners();
  }

  void setView(String view) {
    currentView = view;
    notifyListeners();
  }

  void addWallet(String name) {
    tempWallets = [...tempWallets, TempWallet(id: 'wallet-${DateTime.now().millisecondsSinceEpoch}', name: name, balance: 0, createdAt: DateTime.now())];
    _saveToCache();
    notifyListeners();
  }

  void deleteWallet(String walletId) {
    final wallet = tempWallets.firstWhere((w) => w.id == walletId, orElse: () => tempWallets.first);
    if (wallet.balance > 0) transferWalletToRealAccount(walletId);
    tempWallets = tempWallets.where((w) => w.id != walletId).toList();
    _saveToCache();
    notifyListeners();
  }

  Future<void> generateQR(LimitType limitType, double value, String walletId) async {
    final wallet = tempWallets.firstWhere((w) => w.id == walletId);
    final qrId = 'QR-${DateTime.now().millisecondsSinceEpoch}';
    activeQR = ActiveQRData(id: qrId, qrValue: qrId, limitType: limitType, timeLimit: limitType == LimitType.time ? (value * 60).round() : null, amountLimit: limitType == LimitType.amount ? value : null, createdAt: DateTime.now(), expiresAt: limitType == LimitType.time ? DateTime.now().add(Duration(minutes: value.round())) : null, currentAmount: 0, walletId: wallet.id, walletName: wallet.name);
    try {
      await FirebaseFirestore.instance.collection('payments').doc(qrId).set({
        'id': qrId, 
        'walletName': wallet.name, 
        'walletId': wallet.id, 
        'limitType': limitType.index, 
        'amountLimit': activeQR!.amountLimit, 
        'status': 'pending', 
        'receiverId': _user?.uid,
        'receiverName': _user?.email ?? 'TempWal User',
        'createdAt': FieldValue.serverTimestamp()
      });
      _listenToQR(qrId);
    } catch (e) { debugPrint('Firebase upload failed: $e'); }
    selectedWalletId = walletId;
    currentView = 'active';
    _saveToCache();
    notifyListeners();
  }

  Future<void> scannerPayment(String qrId, double amount) async {
    if (_user == null) return;
    
    // Check local balance
    if (realAccountBalance < amount) {
      transactions.insert(0, WalletTransaction(
        id: 'FAIL-${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.sent,
        amount: amount,
        timestamp: DateTime.now(),
        status: TransactionStatus.failed,
        walletId: 'EXTERNAL',
        walletName: 'External Payment',
        failureReason: 'Insufficient Balance',
      ));
      _saveToCache();
      notifyListeners();
      return;
    }

    realAccountBalance -= amount;
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'balance': realAccountBalance});
    
    try {
      final docRef = FirebaseFirestore.instance.collection('payments').doc(qrId);
      final doc = await docRef.get();
      String receiverName = 'Unknown';
      if (doc.exists) {
        receiverName = doc.data()?['receiverName'] ?? 'User';
        await docRef.update({
          'status': 'completed', 
          'amount': amount, 
          'senderName': _user?.email ?? 'TempWal User', 
          'senderId': _user!.uid, 
          'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}'
        });
      }

      transactions.insert(0, WalletTransaction(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}', 
        type: TransactionType.sent, 
        amount: amount, 
        timestamp: DateTime.now(), 
        status: TransactionStatus.completed, 
        walletId: 'EXTERNAL', 
        walletName: 'Payment to $receiverName',
        otherPartyName: receiverName,
      ));
    } catch (e) { 
      debugPrint('Firebase payment failed: $e');
    }
    
    _saveToCache();
    currentView = 'dashboard';
    notifyListeners();
  }

  void transferWalletToRealAccount(String walletId, {bool auto = false}) async {
    final walletIndex = tempWallets.indexWhere((w) => w.id == walletId);
    if (walletIndex == -1) return;
    final wallet = tempWallets[walletIndex];
    final transferAmount = wallet.balance;
    if (transferAmount <= 0) return;
    
    tempWallets[walletIndex] = wallet.copyWith(balance: 0);
    realAccountBalance += transferAmount;
    
    if (_user != null) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'balance': realAccountBalance});
    }
    
    transactions.insert(0, WalletTransaction(
      id: 'TRF-${DateTime.now().millisecondsSinceEpoch}', 
      type: auto ? TransactionType.autoTransferred : TransactionType.transferred, 
      amount: transferAmount, 
      timestamp: DateTime.now(), 
      status: TransactionStatus.completed, 
      walletId: wallet.id, 
      walletName: wallet.name
    ));
    _saveToCache();
    notifyListeners();
  }

  List<TempWallet> get activeWallets => tempWallets.where((wallet) => !wallet.isExpired).toList();
  List<TempWallet> get expiredWallets => tempWallets.where((wallet) => wallet.isExpired).toList();
  
  void viewWalletTransactions(String walletId) {
    selectedWalletId = walletId;
    currentView = 'wallet-transactions';
    notifyListeners();
  }

  void qrExpired() {
    _qrSubscription?.cancel();
    activeQR = null;
    currentView = 'dashboard';
    _saveToCache();
    notifyListeners();
  }

  void simulatePayment(double amount) {
    if (activeQR == null) return;
    _processIncomingPayment(amount, 'Simulator', 'SIM-${DateTime.now().millisecondsSinceEpoch}');
  }

  double getTotalTempBalance() => tempWallets.where((wallet) => !wallet.isExpired).fold(0, (sum, wallet) => sum + wallet.balance);

  TempWallet? getCurrentWallet() {
    if (selectedWalletId == null) return null;
    return tempWallets.firstWhere((w) => w.id == selectedWalletId, orElse: () => tempWallets.first);
  }

  void expireQR() {
    _qrSubscription?.cancel();
    activeQR = null;
    currentView = 'dashboard';
    _saveToCache();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _qrSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
