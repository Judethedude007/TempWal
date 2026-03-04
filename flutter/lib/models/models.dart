class TempWallet {
  TempWallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
    this.isExpired = false,
  });

  final String id;
  final String name;
  final double balance;
  final DateTime createdAt;
  final bool isExpired;

  TempWallet copyWith({
    String? id,
    String? name,
    double? balance,
    DateTime? createdAt,
    bool? isExpired,
  }) {
    return TempWallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balance': balance,
    'createdAt': createdAt.toIso8601String(),
    'isExpired': isExpired,
  };

  factory TempWallet.fromJson(Map<String, dynamic> json) => TempWallet(
    id: json['id'],
    name: json['name'],
    balance: json['balance'],
    createdAt: DateTime.parse(json['createdAt']),
    isExpired: json['isExpired'] ?? false,
  );
}

enum TransactionType { received, sent, transferred, autoTransferred }

enum TransactionStatus { pending, completed, failed }

enum LimitType { time, amount }

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.walletId,
    required this.walletName,
    this.otherPartyName,
    this.failureReason,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final TransactionStatus status;
  final String walletId;
  final String walletName;
  final String? otherPartyName;
  final String? failureReason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
    'walletId': walletId,
    'walletName': walletName,
    'otherPartyName': otherPartyName,
    'failureReason': failureReason,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    id: json['id'],
    type: TransactionType.values[json['type']],
    amount: json['amount'],
    timestamp: DateTime.parse(json['timestamp']),
    status: TransactionStatus.values[json['status']],
    walletId: json['walletId'],
    walletName: json['walletName'],
    otherPartyName: json['otherPartyName'],
    failureReason: json['failureReason'],
  );
}

class ActiveQRData {
  ActiveQRData({
    required this.id,
    required this.qrValue,
    required this.limitType,
    this.timeLimit,
    this.amountLimit,
    required this.createdAt,
    this.expiresAt,
    required this.currentAmount,
    required this.walletId,
    required this.walletName,
  });

  final String id;
  final String qrValue;
  final LimitType limitType;
  final int? timeLimit;
  final double? amountLimit;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final double currentAmount;
  final String walletId;
  final String walletName;

  ActiveQRData copyWith({
    String? id,
    String? qrValue,
    LimitType? limitType,
    int? timeLimit,
    double? amountLimit,
    DateTime? createdAt,
    DateTime? expiresAt,
    double? currentAmount,
    String? walletId,
    String? walletName,
  }) {
    return ActiveQRData(
      id: id ?? this.id,
      qrValue: qrValue ?? this.qrValue,
      limitType: limitType ?? this.limitType,
      timeLimit: timeLimit ?? this.timeLimit,
      amountLimit: amountLimit ?? this.amountLimit,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      currentAmount: currentAmount ?? this.currentAmount,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'qrValue': qrValue,
    'limitType': limitType.index,
    'timeLimit': timeLimit,
    'amountLimit': amountLimit,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'currentAmount': currentAmount,
    'walletId': walletId,
    'walletName': walletName,
  };

  factory ActiveQRData.fromJson(Map<String, dynamic> json) => ActiveQRData(
    id: json['id'],
    qrValue: json['qrValue'],
    limitType: LimitType.values[json['limitType']],
    timeLimit: json['timeLimit'],
    amountLimit: json['amountLimit'],
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    currentAmount: json['currentAmount'],
    walletId: json['walletId'],
    walletName: json['walletName'],
  );
}
