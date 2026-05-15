import 'dart:convert';

enum PaymentType { rent, securityDeposit, lateFee, maintenanceFee, other }

enum PaymentMethod {
  cash,
  check,
  bankTransfer,
  creditCard,
  debitCard,
  mpesa,
  online
}

enum PaymentStatus { pending, paid, overdue, cancelled }

class Payment {
  final String id;
  final String tenantId;
  final String propertyId;
  final double amount;
  final PaymentType paymentType;
  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.amount,
    required this.paymentType,
    this.paymentMethod,
    required this.paymentStatus,
    required this.dueDate,
    this.paidDate,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      propertyId: map['property_id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentType: PaymentType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            map['payment_type']?.toString().toLowerCase(),
        orElse: () => PaymentType.rent,
      ),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) =>
                  e.name.toLowerCase() ==
                  map['payment_method']?.toString().toLowerCase(),
              orElse: () => PaymentMethod.cash,
            )
          : null,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            map['payment_status']?.toString().toLowerCase(),
        orElse: () => PaymentStatus.pending,
      ),
      dueDate: DateTime.parse(map['due_date']),
      paidDate:
          map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  factory Payment.fromJson(String source) =>
      Payment.fromMap(json.decode(source));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'property_id': propertyId,
      'amount': amount,
      'payment_type': paymentType.name.toLowerCase(),
      'payment_method': paymentMethod?.name.toLowerCase(),
      'payment_status': paymentStatus.name.toLowerCase(),
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Payment(id: $id, tenantId: $tenantId, amount: $amount, paymentType: $paymentType, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.propertyId == propertyId &&
        other.amount == amount &&
        other.paymentType == paymentType &&
        other.paymentMethod == paymentMethod &&
        other.paymentStatus == paymentStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tenantId.hashCode ^
        propertyId.hashCode ^
        amount.hashCode ^
        paymentType.hashCode ^
        paymentMethod.hashCode ^
        paymentStatus.hashCode;
  }
}

class CreatePaymentRequest {
  final String tenantId;
  final String propertyId;
  final double amount;
  final PaymentType paymentType;
  final DateTime dueDate;
  final String? description;

  CreatePaymentRequest({
    required this.tenantId,
    required this.propertyId,
    required this.amount,
    required this.paymentType,
    required this.dueDate,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'property_id': propertyId,
      'amount': amount,
      'payment_type': paymentType.name.toLowerCase(),
      'due_date': dueDate.toIso8601String(),
      'description': description,
    };
  }

  String toJson() => json.encode(toMap());
}

class ProcessPaymentRequest {
  final PaymentMethod paymentMethod;
  final DateTime paidDate;
  final String? mpesaTransactionId; // For M-Pesa payments
  final String? mpesaReceiptNumber; // For M-Pesa payments

  ProcessPaymentRequest({
    required this.paymentMethod,
    required this.paidDate,
    this.mpesaTransactionId,
    this.mpesaReceiptNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'payment_method': paymentMethod.name.toLowerCase(),
      'paid_date': paidDate.toIso8601String(),
      if (mpesaTransactionId != null)
        'mpesa_transaction_id': mpesaTransactionId,
      if (mpesaReceiptNumber != null)
        'mpesa_receipt_number': mpesaReceiptNumber,
    };
  }

  String toJson() => json.encode(toMap());
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.online:
        return 'Online';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cash:
        return 'Physical cash payment';
      case PaymentMethod.check:
        return 'Bank check payment';
      case PaymentMethod.bankTransfer:
        return 'Direct bank transfer';
      case PaymentMethod.creditCard:
        return 'Credit card payment';
      case PaymentMethod.debitCard:
        return 'Debit card payment';
      case PaymentMethod.mpesa:
        return 'M-Pesa mobile money payment';
      case PaymentMethod.online:
        return 'Online payment platform';
    }
  }
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.rent:
        return 'Monthly Rent';
      case PaymentType.securityDeposit:
        return 'Security Deposit';
      case PaymentType.lateFee:
        return 'Late Fee';
      case PaymentType.maintenanceFee:
        return 'Maintenance Fee';
      case PaymentType.other:
        return 'Other';
    }
  }
}
