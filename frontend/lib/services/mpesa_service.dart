import 'package:dio/dio.dart';
import '../config/app_config.dart';

class MpesaService {
  final Dio _dio = Dio();

  MpesaService() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = AppConfig.connectTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;
  }

  /// Initiate M-Pesa STK Push payment
  Future<MpesaPaymentResponse> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String paymentId,
    required String accountReference,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/mpesa/initiate',
        data: {
          'phone_number': _formatPhoneNumber(phoneNumber),
          'amount': amount,
          'payment_id': paymentId,
          'account_reference': accountReference,
        },
      );

      if (response.statusCode == 200) {
        return MpesaPaymentResponse.fromMap(response.data);
      } else {
        throw Exception('Failed to initiate M-Pesa payment');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid payment details');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Phone number format invalid');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Check M-Pesa payment status
  Future<MpesaPaymentStatus> checkPaymentStatus(
      String checkoutRequestId) async {
    try {
      final response = await _dio.get(
        '/payments/mpesa/status/$checkoutRequestId',
      );

      if (response.statusCode == 200) {
        return MpesaPaymentStatus.fromMap(response.data);
      } else {
        throw Exception('Failed to check payment status');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Format phone number for M-Pesa (ensure it starts with 254)
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle different formats
    if (cleaned.startsWith('254')) {
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') || cleaned.startsWith('1')) {
      return '254$cleaned';
    } else {
      throw Exception('Invalid phone number format');
    }
  }

  /// Validate Kenyan phone number
  bool isValidKenyanPhoneNumber(String phoneNumber) {
    try {
      String formatted = _formatPhoneNumber(phoneNumber);
      // Kenyan mobile numbers: 254700000000 to 254799999999, 254100000000 to 254199999999
      return RegExp(r'^254[71]\d{8}$').hasMatch(formatted);
    } catch (e) {
      return false;
    }
  }
}

class MpesaPaymentResponse {
  final String merchantRequestId;
  final String checkoutRequestId;
  final String responseCode;
  final String responseDescription;
  final String customerMessage;

  MpesaPaymentResponse({
    required this.merchantRequestId,
    required this.checkoutRequestId,
    required this.responseCode,
    required this.responseDescription,
    required this.customerMessage,
  });

  factory MpesaPaymentResponse.fromMap(Map<String, dynamic> map) {
    return MpesaPaymentResponse(
      merchantRequestId: map['merchant_request_id'] ?? '',
      checkoutRequestId: map['checkout_request_id'] ?? '',
      responseCode: map['response_code'] ?? '',
      responseDescription: map['response_description'] ?? '',
      customerMessage: map['customer_message'] ?? '',
    );
  }

  bool get isSuccessful => responseCode == '0';
}

class MpesaPaymentStatus {
  final String responseCode;
  final String responseDescription;
  final String? mpesaReceiptNumber;
  final String? transactionDate;
  final double? amount;
  final String? phoneNumber;

  MpesaPaymentStatus({
    required this.responseCode,
    required this.responseDescription,
    this.mpesaReceiptNumber,
    this.transactionDate,
    this.amount,
    this.phoneNumber,
  });

  factory MpesaPaymentStatus.fromMap(Map<String, dynamic> map) {
    return MpesaPaymentStatus(
      responseCode: map['response_code'] ?? '',
      responseDescription: map['response_description'] ?? '',
      mpesaReceiptNumber: map['mpesa_receipt_number'],
      transactionDate: map['transaction_date'],
      amount: map['amount']?.toDouble(),
      phoneNumber: map['phone_number'],
    );
  }

  bool get isCompleted => responseCode == '0';
  bool get isPending => responseCode == '1037'; // Request pending
  bool get isFailed => !isCompleted && !isPending;
}
