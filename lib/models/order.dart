class Order {
  final String orderId;
  final String custId;
  final DateTime orderDate;
  final String orderStatus;
  final double? totalAmount;
  final Map<String, dynamic> rawData;

  Order({
    required this.orderId,
    required this.custId,
    required this.orderDate,
    required this.orderStatus,
    required this.totalAmount,
    required this.rawData,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final dynamic total = json['total_amt'];
    double? parsedTotal;
    if (total is num) {
      parsedTotal = total.toDouble();
    } else if (total is String) {
      parsedTotal = double.tryParse(total);
    }

    return Order(
      orderId: json['order_id']?.toString() ?? '',
      custId: json['cust_id']?.toString() ?? '',
      orderDate: DateTime.tryParse(json['order_date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      orderStatus: json['order_status']?.toString() ?? '',
      totalAmount: parsedTotal,
      rawData: Map<String, dynamic>.from(json),
    );
  }
}

