import '../services/api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Helper class to fix image URLs
/// Handles relative URLs and converts them to full URLs
class ImageUrlHelper {
  /// Get the base URL for images (without /api)
  /// Uses current base URL (may have switched from local to production)
  static String get imageBaseUrl {
    // Use currentBaseUrl to get the actual current URL (may have switched)
    final apiBaseUrl = ApiService.currentBaseUrl;
    // Remove /api from the end if present
    if (apiBaseUrl.endsWith('/api')) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - 4);
    }
    return apiBaseUrl;
  }

  /// Fix image URL - converts relative URLs to full URLs
  /// Handles:
  /// - Relative URLs starting with /uploads/...
  /// - Relative URLs starting with uploads/...
  /// - Already full URLs (returns as is)
  static String fixImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // If already a full URL (starts with http:// or https://), return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // No need to log - already correct
      return imageUrl;
    }

    // Handle relative URLs
    String path = imageUrl.trim();
    
    // Remove leading slash if present (we'll add it back)
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Ensure base URL doesn't have trailing slash
    String base = imageBaseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    // Construct full URL - ensure proper format
    final fullUrl = '$base/$path';
    
    // Validate the URL
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      if (kDebugMode) {
        print('❌ ERROR: Fixed URL is not a valid HTTP/HTTPS URL: $fullUrl');
      }
      return ''; // Return empty string if URL is invalid
    }
    
    return fullUrl;
  }

  /// Fix multiple image URLs
  static List<String> fixImageUrls(List<String> imageUrls) {
    return imageUrls.map((url) => fixImageUrl(url)).toList();
  }
}

