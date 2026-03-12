class BidModel {
  final int id;
  final int productId;
  final int userId;
  final double amount;
  final DateTime createdAt;
  final String? bidderName;
  final String? bidderEmail;
  final String? bidderPhone;
  final String? productTitle;
  final String? productImage;
  final String? productStatus;
  final DateTime? auctionEndTime;
  final double? hoursLeft;
  final String? auctionStatus;

  BidModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.amount,
    required this.createdAt,
    this.bidderName,
    this.bidderEmail,
    this.bidderPhone,
    this.productTitle,
    this.productImage,
    this.productStatus,
    this.auctionEndTime,
    this.hoursLeft,
    this.auctionStatus,
  });

  // Helper function to safely parse numeric values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return double.tryParse(value.toString());
  }

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      userId: json['user_id'] as int,
      amount: _parseDouble(json['amount']) ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      bidderName: json['bidder_name'] as String?,
      bidderEmail: json['bidder_email'] as String?,
      bidderPhone: json['bidder_phone'] as String?,
      productTitle: json['product_title'] as String?,
      productImage: json['product_image'] as String?,
      productStatus: json['product_status'] as String?,
      auctionEndTime: json['auction_end_time'] != null
          ? DateTime.parse(json['auction_end_time'] as String)
          : null,
      hoursLeft: _parseDouble(json['hours_left']),
      auctionStatus: json['auction_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'bidder_name': bidderName,
      'bidder_email': bidderEmail,
      'bidder_phone': bidderPhone,
      'product_title': productTitle,
      'product_image': productImage,
      'product_status': productStatus,
      'auction_end_time': auctionEndTime?.toIso8601String(),
      'hours_left': hoursLeft,
      'auction_status': auctionStatus,
    };
  }
}

