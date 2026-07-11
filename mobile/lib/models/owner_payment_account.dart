import '../utils/json_int.dart';

class OwnerFeeInvoice {
  const OwnerFeeInvoice({
    required this.id,
    required this.amount,
    required this.totalHours,
    required this.status,
    required this.title,
    required this.createdAt,
    this.paidAt,
    required this.bookingCount,
  });

  final int id;
  final int amount;
  final int totalHours;
  final String status;
  final String title;
  final DateTime createdAt;
  final DateTime? paidAt;
  final int bookingCount;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';

  factory OwnerFeeInvoice.fromJson(Map<String, dynamic> json) => OwnerFeeInvoice(
        id: asInt(json['id']) ?? 0,
        amount: asInt(json['amount']) ?? 0,
        totalHours: asInt(json['totalHours']) ?? 0,
        status: json['status'] as String? ?? 'pending',
        title: json['title'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'] as String) : null,
        bookingCount: asInt(json['bookingCount']) ?? 0,
      );
}

class OwnerPaymentRecord {
  const OwnerPaymentRecord({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.gateway,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
  });

  final int id;
  final int invoiceId;
  final int amount;
  final String gateway;
  final String status;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  factory OwnerPaymentRecord.fromJson(Map<String, dynamic> json) => OwnerPaymentRecord(
        id: asInt(json['id']) ?? 0,
        invoiceId: asInt(json['invoiceId']) ?? 0,
        amount: asInt(json['amount']) ?? 0,
        gateway: json['gateway'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt'] as String) : null,
      );
}

class OwnerPaymentAccount {
  const OwnerPaymentAccount({
    required this.outstandingAmount,
    required this.outstandingHours,
    required this.totalPaid,
    required this.pendingInvoices,
    required this.paidInvoices,
    required this.recentPayments,
  });

  final int outstandingAmount;
  final int outstandingHours;
  final int totalPaid;
  final List<OwnerFeeInvoice> pendingInvoices;
  final List<OwnerFeeInvoice> paidInvoices;
  final List<OwnerPaymentRecord> recentPayments;

  factory OwnerPaymentAccount.fromJson(Map<String, dynamic> json) => OwnerPaymentAccount(
        outstandingAmount: asInt(json['outstandingAmount']) ?? 0,
        outstandingHours: asInt(json['outstandingHours']) ?? 0,
        totalPaid: asInt(json['totalPaid']) ?? 0,
        pendingInvoices: (json['pendingInvoices'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OwnerFeeInvoice.fromJson)
            .toList(),
        paidInvoices: (json['paidInvoices'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OwnerFeeInvoice.fromJson)
            .toList(),
        recentPayments: (json['recentPayments'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OwnerPaymentRecord.fromJson)
            .toList(),
      );
}

class PaymentInitiation {
  const PaymentInitiation({
    required this.transactionToken,
    required this.gateway,
    required this.amount,
    this.checkoutUrl,
  });

  final String transactionToken;
  final String gateway;
  final int amount;
  final String? checkoutUrl;

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) => PaymentInitiation(
        transactionToken: json['transactionToken'] as String? ?? '',
        gateway: json['gateway'] as String? ?? 'card',
        amount: asInt(json['amount']) ?? 0,
        checkoutUrl: json['checkoutUrl'] as String?,
      );
}

class PaymentVerification {
  const PaymentVerification({
    required this.success,
    required this.status,
    this.invoiceId,
    required this.outstandingAmount,
    required this.message,
  });

  final bool success;
  final String status;
  final int? invoiceId;
  final int outstandingAmount;
  final String message;

  factory PaymentVerification.fromJson(Map<String, dynamic> json) => PaymentVerification(
        success: json['success'] as bool? ?? false,
        status: json['status'] as String? ?? '',
        invoiceId: asInt(json['invoiceId']),
        outstandingAmount: asInt(json['outstandingAmount']) ?? 0,
        message: json['message'] as String? ?? '',
      );
}
