import 'dart:convert';
import '../utils/image_url_helper.dart';

class ProductModel {
  final int id;
  final int? sellerId;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<String> images;
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
  final bool defectAlert;
  final String? defectDetails;
  final List<String> defectImages;

  final double? buyNowPrice;
  final double? originalRetailPrice;
  final double? realPrice;
  final String? originalBarcode;
  final String? specialDescription;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    this.sellerId,
    required this.title,
    this.description,
    this.imageUrl,
    this.images = const [],
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
    this.defectAlert = false,
    this.defectDetails,
    this.defectImages = const [],
    this.buyNowPrice,
    this.originalRetailPrice,
    this.realPrice,
    this.originalBarcode,
    this.specialDescription,
    this.createdAt,
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
    
    // Parse images array
    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages = (json['images'] as List)
            .map((e) => e.toString().trim())
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (json['images'] is String) {
        try {
          final decoded = jsonDecode(json['images'] as String);
          if (decoded is List) {
            parsedImages = decoded.map((e) => e.toString().trim()).where((url) => url.isNotEmpty).toList();
          }
        } catch (_) {}
      }
    }

    return ProductModel(
      id: json['id'] as int,
      sellerId: json['seller_id'] as int?,
      title: json['title'] as String? ?? 'Untitled Product',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      images: parsedImages,
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
      defectAlert: json['defect_alert'] == true || json['defect_alert'] == 'true',
      defectDetails: json['defect_details'] as String?,
      defectImages: json['defect_images'] != null
          ? List<String>.from((json['defect_images'] as List).map((e) => e.toString()))
          : const [],
      buyNowPrice: _parseDouble(json['buy_now_price'] ?? json['buyNowPrice']),
      originalRetailPrice: _parseDouble(json['original_retail_price'] ?? json['originalRetailPrice'] ?? json['real_price'] ?? json['realPrice']),
      realPrice: _parseDouble(json['real_price'] ?? json['realPrice'] ?? json['original_retail_price'] ?? json['originalRetailPrice']),
      originalBarcode: json['barcode'] as String? ?? json['item_barcode'] as String?,
      specialDescription: json['special_description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
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
      'barcode': originalBarcode,
    };
  }

  ProductModel copyWith({
    int? id,
    int? sellerId,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? images,
    double? startingPrice,
    double? startingBid,
    double? currentPrice,
    double? currentBid,
    String? status,
    DateTime? auctionEndTime,
    int? totalBids,
    int? highestBidderId,
    int? categoryId,
    String? sellerName,
    String? sellerEmail,
    String? sellerPhone,
    String? categoryName,
    String? highestBidderName,
    double? hoursLeft,
    String? auctionStatus,
    String? condition,
    bool? defectAlert,
    String? defectDetails,
    List<String>? defectImages,
    double? buyNowPrice,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      startingPrice: startingPrice ?? this.startingPrice,
      startingBid: startingBid ?? this.startingBid,
      currentPrice: currentPrice ?? this.currentPrice,
      currentBid: currentBid ?? this.currentBid,
      status: status ?? this.status,
      auctionEndTime: auctionEndTime ?? this.auctionEndTime,
      totalBids: totalBids ?? this.totalBids,
      highestBidderId: highestBidderId ?? this.highestBidderId,
      categoryId: categoryId ?? this.categoryId,
      sellerName: sellerName ?? this.sellerName,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      categoryName: categoryName ?? this.categoryName,
      highestBidderName: highestBidderName ?? this.highestBidderName,
      hoursLeft: hoursLeft ?? this.hoursLeft,
      auctionStatus: auctionStatus ?? this.auctionStatus,
      condition: condition ?? this.condition,
      defectAlert: defectAlert ?? this.defectAlert,
      defectDetails: defectDetails ?? this.defectDetails,
      defectImages: defectImages ?? this.defectImages,
      buyNowPrice: buyNowPrice ?? this.buyNowPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to get image URLs as list (with fixed URLs)
  List<String> get imageUrls {
    final List<String> result = [];

    // 1. First priority: images array
    if (images.isNotEmpty) {
      for (final img in images) {
        if (img.trim().isNotEmpty) {
          result.add(ImageUrlHelper.fixImageUrl(img.trim()));
        }
      }
    }

    // 2. If images array had nothing, fallback to imageUrl
    if (result.isEmpty && imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final trimmed = imageUrl!.trim();
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is List) {
          for (final item in parsed) {
            final u = item.toString().trim();
            if (u.isNotEmpty) {
              result.add(ImageUrlHelper.fixImageUrl(u));
            }
          }
        } else {
          result.add(ImageUrlHelper.fixImageUrl(trimmed));
        }
      } catch (_) {
        result.add(ImageUrlHelper.fixImageUrl(trimmed));
      }
    }

    return result.where((u) => u.isNotEmpty).toList();
  }
}

