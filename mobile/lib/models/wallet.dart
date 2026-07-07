class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.typeLabel,
    required this.description,
    this.bookingId,
    this.bookingReference,
    this.adminNote,
    required this.createdAt,
  });

  final int id;
  final int amount;
  final String type;
  final String typeLabel;
  final String description;
  final int? bookingId;
  final String? bookingReference;
  final String? adminNote;
  final DateTime createdAt;

  bool get isCredit => amount > 0;

  bool get isCommissionDebit => type == 'commission_debit';

  bool get isAdminCredit => type == 'admin_credit';

  bool get isSystemAdjustment => type == 'system_adjustment';

  String get displayReason {
    if (isAdminCredit && adminNote != null && adminNote!.isNotEmpty) return adminNote!;
    return description;
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as int,
        amount: json['amount'] as int? ?? 0,
        type: json['type'] as String? ?? '',
        typeLabel: json['typeLabel'] as String? ?? json['type'] as String? ?? '',
        description: json['description'] as String? ?? '',
        bookingId: json['bookingId'] as int?,
        bookingReference: json['bookingReference'] as String?,
        adminNote: json['adminNote'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class WalletStatus {
  const WalletStatus({
    required this.ownerId,
    required this.balance,
    required this.status,
    this.message,
  });

  final int ownerId;
  final double balance;
  final String status;
  final String? message;

  bool get isBlocked => status == 'blocked';

  factory WalletStatus.fromJson(Map<String, dynamic> json) => WalletStatus(
        ownerId: json['ownerId'] as int? ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'active',
        message: json['message'] as String?,
      );
}

class WalletDetail {
  const WalletDetail({
    required this.walletId,
    required this.ownerId,
    required this.balance,
    required this.status,
    required this.lastUpdated,
    required this.transactions,
  });

  final int walletId;
  final int ownerId;
  final double balance;
  final String status;
  final DateTime lastUpdated;
  final List<WalletTransaction> transactions;

  bool get isBlocked => status == 'blocked';

  factory WalletDetail.fromJson(Map<String, dynamic> json) => WalletDetail(
        walletId: json['walletId'] as int? ?? 0,
        ownerId: json['ownerId'] as int? ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'active',
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
        transactions: (json['transactions'] as List<dynamic>? ?? [])
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum WalletTxFilter { all, credits, debits }
