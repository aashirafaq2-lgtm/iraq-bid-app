import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to handle unique referral links and automatic attribution
/// Zero manual referral code entry required.
class ReferralService {
  static const String _keyReferralToken = 'pending_referral_token';
  static const String _keyReferralSource = 'pending_referral_source';
  static const String _keyReferralTimestamp = 'pending_referral_timestamp';
  
  // Referral token expires after 48 hours if unverified
  static const Duration _referralExpiry = Duration(hours: 48);

  /// Save referral token and source temporarily (until OTP verification)
  static Future<void> savePendingReferral({
    required String token,
    String source = 'challenge',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyReferralToken, token.trim().toUpperCase());
      await prefs.setString(_keyReferralSource, source.trim().toLowerCase());
      await prefs.setInt(_keyReferralTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('✅ Referral saved: token=$token, source=$source');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving pending referral: $e');
      }
    }
  }

  /// Get pending referral token if it exists and hasn't expired
  static Future<String?> getPendingReferralToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyReferralToken);
      final timestamp = prefs.getInt(_keyReferralTimestamp);
      
      if (token == null || timestamp == null) {
        return null;
      }
      
      // Check if token has expired
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final difference = DateTime.now().difference(savedTime);
      
      if (difference > _referralExpiry) {
        await clearPendingReferral();
        return null;
      }
      
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Get pending referral source ('challenge' or 'wheel')
  static Future<String> getPendingReferralSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyReferralSource) ?? 'challenge';
    } catch (e) {
      return 'challenge';
    }
  }

  /// Clear pending referral (called after successful OTP verification)
  static Future<void> clearPendingReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyReferralToken);
      await prefs.remove(_keyReferralSource);
      await prefs.remove(_keyReferralTimestamp);
      if (kDebugMode) {
        print('✅ Pending referral cleared after successful verification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing pending referral: $e');
      }
    }
  }

  /// Legacy compatibility helpers
  static Future<void> savePendingReferralCode(String code) => savePendingReferral(token: code);
  static Future<String?> getPendingReferralCode() => getPendingReferralToken();
  static Future<void> clearPendingReferralCode() => clearPendingReferral();

  /// Handle deep link or referral landing URL
  /// Supported formats:
  /// - https://iraqbid.net/join?ref=IQB123&source=challenge
  /// - iraqbid://join?ref=IQB123&source=wheel
  /// - ?ref=IQB123
  static Future<void> handleDeepLink(String url) async {
    if (kDebugMode) {
      print('🔗 Deep link received: $url');
    }
    
    try {
      final uri = Uri.parse(url);
      final ref = uri.queryParameters['ref'] ?? uri.queryParameters['referral'];
      final source = uri.queryParameters['source'] ?? 'challenge';
      
      if (ref != null && ref.trim().isNotEmpty) {
        await savePendingReferral(token: ref.trim(), source: source.trim());
        if (kDebugMode) {
          print('✅ Referral attributed from link: ref=$ref, source=$source');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error extracting referral link: $e');
      }
    }
  }
}
