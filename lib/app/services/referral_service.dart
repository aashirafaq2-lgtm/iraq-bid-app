import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to handle referral code storage and retrieval
class ReferralService {
  static const String _keyReferralCode = 'pending_referral_code';
  static const String _keyReferralCodeTimestamp = 'pending_referral_code_timestamp';
  
  // Referral code expires after 24 hours
  static const Duration _referralCodeExpiry = Duration(hours: 24);

  /// Save referral code temporarily (until OTP verification)
  static Future<void> savePendingReferralCode(String referralCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReferralCode, referralCode);
    await prefs.setInt(_keyReferralCodeTimestamp, DateTime.now().millisecondsSinceEpoch);
    
    if (kDebugMode) {
      print('✅ Referral code saved: $referralCode');
    }
  }

  /// Get pending referral code if it exists and hasn't expired
  static Future<String?> getPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyReferralCode);
    final timestamp = prefs.getInt(_keyReferralCodeTimestamp);
    
    if (code == null || timestamp == null) {
      return null;
    }
    
    // Check if code has expired
    final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(savedTime);
    
    if (difference > _referralCodeExpiry) {
      // Code expired, clear it
      await clearPendingReferralCode();
      if (kDebugMode) {
        print('⚠️ Referral code expired, cleared');
      }
      return null;
    }
    
    return code;
  }

  /// Clear pending referral code (after successful OTP verification)
  static Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReferralCode);
    await prefs.remove(_keyReferralCodeTimestamp);
    
    if (kDebugMode) {
      print('✅ Pending referral code cleared');
    }
  }

  /// Extract referral code from URL
  /// Supports formats:
  /// - https://yourapp.com/signup?ref=XXXXXX
  /// - yourapp://signup?ref=XXXXXX
  /// - ?ref=XXXXXX
  static String? extractReferralCodeFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final ref = uri.queryParameters['ref'];
      
      if (ref != null && ref.isNotEmpty) {
        // Validate referral code format (6 alphanumeric characters)
        if (ref.length == 6 && RegExp(r'^[A-Z0-9]+$').hasMatch(ref.toUpperCase())) {
          return ref.toUpperCase();
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error extracting referral code from URL: $e');
      }
      return null;
    }
  }

  /// Handle deep link URL and extract referral code
  static Future<void> handleDeepLink(String url) async {
    if (kDebugMode) {
      print('🔗 Deep link received: $url');
    }
    
    final referralCode = extractReferralCodeFromUrl(url);
    
    if (referralCode != null) {
      await savePendingReferralCode(referralCode);
      if (kDebugMode) {
        print('✅ Referral code extracted and saved: $referralCode');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No valid referral code found in URL');
      }
    }
  }
}



