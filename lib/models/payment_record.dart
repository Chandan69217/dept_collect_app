class PaymentRecord {
  final String id;
  final String customerId;
  final String customerName;
  final String agentId;
  final String agentName;
  final double amount;
  final String paymentMethod; // 'Cash', 'UPI', 'Card'
  final String transactionReference;
  final String? receiptImagePath;
  final DateTime timestamp;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'

  const PaymentRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.agentId,
    required this.agentName,
    required this.amount,
    required this.paymentMethod,
    required this.transactionReference,
    this.receiptImagePath,
    required this.timestamp,
    required this.status,
  });

  PaymentRecord copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? agentId,
    String? agentName,
    double? amount,
    String? paymentMethod,
    String? transactionReference,
    String? receiptImagePath,
    DateTime? timestamp,
    String? status,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
