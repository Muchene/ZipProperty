import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment.dart';
import '../../services/mpesa_service.dart';
import '../../theme/app_theme.dart';

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;
  final bool enabled;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.enabled = true,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ...PaymentMethod.values.map((method) {
          return RadioListTile<PaymentMethod>(
            value: method,
            groupValue: widget.selectedMethod,
            onChanged: widget.enabled
                ? (value) {
                    if (value != null) {
                      widget.onMethodSelected(value);
                    }
                  }
                : null,
            title: Row(
              children: [
                _getPaymentMethodIcon(method),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      method.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          );
        }),
      ],
    );
  }

  Widget _getPaymentMethodIcon(PaymentMethod method) {
    IconData iconData;
    Color color = AppTheme.primaryColor;

    switch (method) {
      case PaymentMethod.cash:
        iconData = Icons.money;
        break;
      case PaymentMethod.check:
        iconData = Icons.receipt_long;
        break;
      case PaymentMethod.bankTransfer:
        iconData = Icons.account_balance;
        break;
      case PaymentMethod.creditCard:
        iconData = Icons.credit_card;
        break;
      case PaymentMethod.debitCard:
        iconData = Icons.payment;
        break;
      case PaymentMethod.mpesa:
        iconData = Icons.phone_android;
        color = const Color(0xFF00A651); // M-Pesa green
        break;
      case PaymentMethod.online:
        iconData = Icons.computer;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }
}

class MpesaPaymentForm extends StatefulWidget {
  final double amount;
  final String paymentId;
  final String accountReference;
  final Function(String mpesaReceiptNumber) onPaymentSuccess;
  final VoidCallback? onCancel;

  const MpesaPaymentForm({
    super.key,
    required this.amount,
    required this.paymentId,
    required this.accountReference,
    required this.onPaymentSuccess,
    this.onCancel,
  });

  @override
  State<MpesaPaymentForm> createState() => _MpesaPaymentFormState();
}

class _MpesaPaymentFormState extends State<MpesaPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _mpesaService = MpesaService();

  bool _isLoading = false;
  String? _error;
  String? _checkoutRequestId;
  bool _isCheckingStatus = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _mpesaService.initiatePayment(
        phoneNumber: _phoneController.text.trim(),
        amount: widget.amount,
        paymentId: widget.paymentId,
        accountReference: widget.accountReference,
      );

      if (response.isSuccessful) {
        setState(() {
          _checkoutRequestId = response.checkoutRequestId;
          _isLoading = false;
          _isCheckingStatus = true;
        });

        _showPaymentDialog(response.customerMessage);
        _pollPaymentStatus();
      } else {
        setState(() {
          _error = response.responseDescription;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pollPaymentStatus() async {
    if (_checkoutRequestId == null) return;

    int attempts = 0;
    const maxAttempts = 30; // 30 seconds
    const pollInterval = Duration(seconds: 1);

    while (attempts < maxAttempts && _isCheckingStatus) {
      try {
        final status = await _mpesaService.checkPaymentStatus(
          _checkoutRequestId!,
        );

        if (status.isCompleted) {
          setState(() {
            _isCheckingStatus = false;
          });
          Navigator.of(context).pop(); // Close dialog
          widget.onPaymentSuccess(status.mpesaReceiptNumber ?? '');
          return;
        } else if (status.isFailed) {
          setState(() {
            _isCheckingStatus = false;
            _error = status.responseDescription;
          });
          Navigator.of(context).pop(); // Close dialog
          return;
        }

        attempts++;
        await Future.delayed(pollInterval);
      } catch (e) {
        // Continue polling on error
        attempts++;
        await Future.delayed(pollInterval);
      }
    }

    // Timeout
    if (_isCheckingStatus) {
      setState(() {
        _isCheckingStatus = false;
        _error = 'Payment timeout. Please try again.';
      });
      Navigator.of(context).pop(); // Close dialog
    }
  }

  void _showPaymentDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.phone_android, color: Color(0xFF00A651)),
              SizedBox(width: 8),
              Text('M-Pesa Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A651)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your M-Pesa PIN on your phone to complete the payment.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isCheckingStatus = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A651).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      color: Color(0xFF00A651),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'M-Pesa Payment',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Pay KES ${widget.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Phone number input
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: '0712345678 or +254712345678',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s()]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your M-Pesa phone number';
                  }
                  if (!_mpesaService.isValidKenyanPhoneNumber(value)) {
                    return 'Please enter a valid Kenyan phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive an M-Pesa prompt on your phone. Enter your PIN to complete the payment.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Buttons
              Row(
                children: [
                  if (widget.onCancel != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _initiatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A651),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Pay with M-Pesa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
