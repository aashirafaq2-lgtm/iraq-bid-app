import 'dart:convert';
import '../utils/image_url_helper.dart';

class ProductModel {
  final int id;
  final int? sellerId;
  final String title;
  final String? description;
  final String? imageUrl;
  final double startingPrice;
  final double? startingBid;
  final double? currentPrice;
  final double? currentBid;
  final String status;
  final DateTime? auctionEndTime;
  final int? totalBids;
  final int? highestBidderId;
  final int? categoryId;
  final String? sellerName;
  final String? sellerEmail;
  final String? sellerPhone;
  final String? categoryName;
  final String? highestBidderName;
  final double? hoursLeft;
  final String? auctionStatus;
  final String? condition; // New / Used / Working

  ProductModel({
    required this.id,
    this.sellerId,
    required this.title,
    this.description,
    this.imageUrl,
    required this.startingPrice,
    this.startingBid,
    this.currentPrice,
    this.currentBid,
    required this.status,
    this.auctionEndTime,
    this.totalBids,
    this.highestBidderId,
    this.categoryId,
    this.sellerName,
    this.sellerEmail,
    this.sellerPhone,
    this.categoryName,
    this.highestBidderName,
    this.hoursLeft,
    this.auctionStatus,
    this.condition,
  });

  // Helper function to safely parse numeric values from JSON
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return int.tryParse(value.toString());
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse seller information from nested object or flat fields
    final seller = json['seller'] as Map<String, dynamic>? ?? {};
    
    // Safely parse starting_price with fallback
    final startingPriceValue = json['starting_price'] ?? json['starting_bid'] ?? 0.0;
    final startingPrice = _parseDouble(startingPriceValue) ?? 0.0;
    
    // Safely parse auction_end_time
    DateTime? auctionEndTime;
    if (json['auction_end_time'] != null) {
      try {
        final timeValue = json['auction_end_time'];
        if (timeValue is String) {
          auctionEndTime = DateTime.parse(timeValue);
        } else if (timeValue is DateTime) {
          auctionEndTime = timeValue;
        }
      } catch (e) {
        print('Warning: Failed to parse auction_end_time: ${json['auction_end_time']}');
        auctionEndTime = null;
      }
    }
    
    return ProductModel(
      id: json['id'] as int,
      sellerId: json['seller_id'] as int?,
      title: json['title'] as String? ?? 'Untitled Product',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      startingPrice: startingPrice,
      startingBid: _parseDouble(json['starting_bid']),
      currentPrice: _parseDouble(json['current_price']),
      currentBid: _parseDouble(json['current_bid']),
      status: json['status'] as String? ?? 'pending',
      auctionEndTime: auctionEndTime,
      totalBids: _parseInt(json['total_bids']) ?? 0,
      highestBidderId: json['highest_bidder_id'] as int?,
      categoryId: json['category_id'] as int?,
      sellerName: json['seller_name'] as String? ?? seller['name'] as String?,
      sellerEmail: seller['email'] as String? ?? json['seller_email'] as String?,
      sellerPhone: seller['phone'] as String? ?? json['seller_phone'] as String?,
      categoryName: json['category_name'] as String?,
      highestBidderName: json['highest_bidder_name'] as String?,
      hoursLeft: _parseDouble(json['hours_left']),
      auctionStatus: json['auction_status'] as String?,
      condition: json['condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'starting_price': startingPrice,
      'starting_bid': startingBid,
      'current_price': currentPrice,
      'current_bid': currentBid,
      'status': status,
      'auction_end_time': auctionEndTime?.toIso8601String(),
      'total_bids': totalBids,
      'highest_bidder_id': highestBidderId,
      'category_id': categoryId,
      'seller_name': sellerName,
      'seller_email': sellerEmail,
      'seller_phone': sellerPhone,
      'category_name': categoryName,
      'highest_bidder_name': highestBidderName,
      'hours_left': hoursLeft,
      'auction_status': auctionStatus,
      'condition': condition,
    };
  }

  // Helper method to get image URLs as list (with fixed URLs)
  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return [];
    }
    
    try {
      // Try to parse as JSON array
      final parsed = jsonDecode(imageUrl!);
      if (parsed is List) {
        final urls = parsed.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
        // Fix all URLs (convert relative to full URLs)
        return ImageUrlHelper.fixImageUrls(urls).where((url) => url.isNotEmpty).toList();
      }
    } catch (e) {
      // If not JSON, treat as single URL string
      final url = imageUrl!.trim();
      if (url.isEmpty) return [];
      // Fix URL (convert relative to full URL)
      final fixedUrl = ImageUrlHelper.fixImageUrl(url);
      return fixedUrl.isEmpty ? [] : [fixedUrl];
    }
    
    // Fallback: treat as single URL string
    final url = imageUrl!.trim();
    if (url.isEmpty) return [];
    final fixedUrl = ImageUrlHelper.fixImageUrl(url);
    return fixedUrl.isEmpty ? [] : [fixedUrl];
  }
}

