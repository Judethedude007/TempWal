import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'models/models.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? userName;
  String? userPin;
  String? localProfilePath;

  double realAccountBalance = 5420.50;
  bool isDarkMode = false;
  bool isSoundEnabled = true;
  
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  List<TempWallet> tempWallets = [
    TempWallet(
      id: 'wallet-1',
      name: 'Emergency Fund',
      balance: 0,
      createdAt: DateTime.now(),
    ),
  ];
  ActiveQRData? activeQR;
  String qrStatus = 'idle';
  
  final List<WalletTransaction> transactions = [];
  String currentView = 'dashboard';
  String? selectedWalletId;
  StreamSubscription? _qrSubscription;
  StreamSubscription? _authSubscription;

  Future<void> _init() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      }
      notifyListeners();
    });
    await _loadFromCache();
  }

  Future<void> _speak(String text) async {
    if (!isSoundEnabled) return;
    await _flutterTts.speak(text);
  }

  Future<void> _playTadingSound() async {
    if (!isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/payment_success.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  // --- Profile Pic Logic ---
  Future<void> updateProfilePicture() async {
    if (_user == null) return;
    
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final File localImage = await File(image.path).copy('$path/profile_${_user!.uid}.jpg');
      
      localProfilePath = localImage.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('localProfilePath_${_user!.uid}', localProfilePath!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile pic: $e');
    }
  }

  // --- PIN Logic ---
  Future<void> setPin(String pin) async {
    userPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPin', pin);
    if (_user != null) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'pin': pin});
    }
    notifyListeners();
  }

  bool verifyPin(String pin) {
    return userPin == pin;
  }

  // --- Auth Logic ---
  
  Future<void> signUp(String email, String password, String name) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        userName = name;
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'balance': 5000.0,
          'email': email,
          'name': name,
          'pin': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
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
    userName = null;
    userPin = null;
    localProfilePath = null;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        realAccountBalance = (data['balance'] as num).toDouble();
        userName = data['name'] ?? 'User';
        userPin = data['pin'];
      }
      
      final prefs = await SharedPreferences.getInstance();
      localProfilePath = prefs.getString('localProfilePath_$uid');

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
      isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
      userPin = prefs.getString('userPin');
      
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
    await prefs.setBool('isSoundEnabled', isSoundEnabled);
    if (userPin != null) await prefs.setString('userPin', userPin!);
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
        if (data != null) {
          qrStatus = data['status'] ?? 'pending';
          
          if (qrStatus == 'completed') {
            final amount = (data['amount'] as num).toDouble();
            final senderName = data['senderName'] ?? 'Someone';
            final txnId = data['transactionId'] ?? 'CLD-${DateTime.now().millisecondsSinceEpoch}';
            if (!transactions.any((t) => t.id == txnId)) {
              _processIncomingPayment(amount, senderName, txnId);
            }
          }
          notifyListeners();
        }
      }
    });
  }

  void _processIncomingPayment(double amount, String senderName, String txnId) {
    if (activeQR == null) return;
    
    _speak("Credited ${amount.toInt()} rupees from $senderName");

    transactions.insert(0, WalletTransaction(
      id: txnId, 
      type: TransactionType.received, 
      amount: amount, 
      timestamp: DateTime.now(), 
      status: TransactionStatus.completed,
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

  void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
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
    final walletIndex = tempWallets.indexWhere((w) => w.id == walletId);
    if (walletIndex == -1) return;
    if (tempWallets[walletIndex].balance > 0) transferWalletToRealAccount(walletId);
    tempWallets = tempWallets.where((w) => w.id != walletId).toList();
    _saveToCache();
    notifyListeners();
  }

  Future<void> generateQR(LimitType limitType, double value, String walletId) async {
    final wallet = tempWallets.firstWhere((w) => w.id == walletId);
    final qrId = 'QR-${DateTime.now().millisecondsSinceEpoch}';
    
    DateTime? expiresAt;
    if (limitType == LimitType.time) {
      expiresAt = DateTime.now().add(Duration(minutes: value.round()));
    }

    activeQR = ActiveQRData(
      id: qrId, 
      qrValue: qrId, 
      limitType: limitType, 
      timeLimit: limitType == LimitType.time ? (value * 60).round() : null, 
      amountLimit: limitType == LimitType.amount ? value : null, 
      createdAt: DateTime.now(), 
      expiresAt: expiresAt,
      currentAmount: 0, 
      walletId: wallet.id, 
      walletName: wallet.name
    );
    qrStatus = 'pending';

    try {
      await FirebaseFirestore.instance.collection('payments').doc(qrId).set({
        'id': qrId, 
        'walletName': wallet.name, 
        'walletId': wallet.id, 
        'limitType': limitType.index, 
        'amountLimit': activeQR!.amountLimit, 
        'status': 'pending', 
        'receiverId': _user?.uid,
        'receiverName': userName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt?.toIso8601String(),
      });
      _listenToQR(qrId);
    } catch (e) { debugPrint('Firebase upload failed: $e'); }
    
    selectedWalletId = walletId;
    currentView = 'active';
    _saveToCache();
    notifyListeners();
  }

  Future<void> notifyScanning(String qrId) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(qrId).update({'status': 'scanning'});
    } catch (e) { debugPrint('Update status to scanning failed: $e'); }
  }

  Future<void> scannerPayment(String qrId, double amount) async {
    if (_user == null) return;
    
    if (realAccountBalance < amount) {
      _addFailedTransaction('Insufficient Balance', amount);
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('payments').doc(qrId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final receiverName = data['receiverName'] ?? 'User';
      
      if (data['expiresAt'] != null) {
        final expiry = DateTime.parse(data['expiresAt']);
        if (DateTime.now().isAfter(expiry)) {
          _addFailedTransaction('QR Code Expired', amount, receiver: receiverName);
          return;
        }
      }

      realAccountBalance -= amount;
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'balance': realAccountBalance});
      
      await docRef.update({
        'status': 'completed', 
        'amount': amount, 
        'senderName': userName ?? 'User',
        'senderId': _user!.uid, 
        'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}'
      });

      _playTadingSound();

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

  void _addFailedTransaction(String reason, double amount, {String? receiver}) {
    transactions.insert(0, WalletTransaction(
      id: 'FAIL-${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.sent,
      amount: amount,
      timestamp: DateTime.now(),
      status: TransactionStatus.failed,
      walletId: 'EXTERNAL',
      walletName: receiver != null ? 'Payment to $receiver' : 'External Payment',
      failureReason: reason,
      otherPartyName: receiver,
    ));
    _saveToCache();
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
    
    if (auto) {
      _speak("Limit reached. ${transferAmount.toInt()} rupees auto transferred to main account.");
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
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
