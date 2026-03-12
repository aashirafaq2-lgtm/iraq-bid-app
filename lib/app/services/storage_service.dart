import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/jwt_utils.dart';

class StorageService {
  static const String _keyToken = 'auth_token'; // Legacy - kept for backward compatibility
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyReferralCode = 'user_referral_code';
  static const String _keyRewardBalance = 'user_reward_balance';
  static const String _keyWishlist = 'wishlist';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveToken(String token) async {
    // Legacy method - saves as access token
    await saveAccessToken(token);
  }

  static Future<String?> getToken() async {
    // Legacy method - returns access token
    return await getAccessToken();
  }

  static Future<void> clearToken() async {
    await clearAllTokens();
  }

  // Access token management
  static Future<void> saveAccessToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAccessToken, token);
    await prefs.setString(_keyToken, token); // Keep for backward compatibility
    
    if (kDebugMode) {
      print('✅ [TOKEN STORAGE] Access token saved successfully');
      print('   Token length: ${token.length}');
      // Verify it was saved
      final saved = await prefs.getString(_keyAccessToken);
      if (saved != null && saved == token) {
        print('   ✅ Token verified in storage');
      } else {
        print('   ⚠️ Warning: Token may not have been saved correctly');
      }
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(_keyAccessToken) ?? prefs.getString(_keyToken); // Fallback to legacy
    
    // 🔍 DEEP TRACE: Log token retrieval (only when token exists or for debugging)
    if (kDebugMode && token != null) {
      print('🔍 [DEEP TRACE] StorageService.getAccessToken() called');
      print('   Token length: ${token.length}');
      print('   Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      
      // Try to decode and log role
      try {
        final role = JwtUtils.getRoleFromToken(token);
        final userId = JwtUtils.getUserIdFromToken(token);
        print('   🔍 Decoded token role: $role');
        print('   🔍 Decoded token userId: $userId');
        
        // Compare with stored role
        final storedRole = await getUserRole();
        print('   🔍 Stored role in SharedPreferences: $storedRole');
        if (role != null && storedRole != null && role != storedRole) {
          print('   ⚠️⚠️⚠️ ROLE MISMATCH DETECTED! ⚠️⚠️⚠️');
          print('   ⚠️ Token role: $role');
          print('   ⚠️ Stored role: $storedRole');
          print('   ⚠️ STACK TRACE:');
          print(StackTrace.current);
        }
      } catch (e) {
        print('   ⚠️ Could not decode token: $e');
      }
    }
    // Removed "NO TOKEN FOUND" log - this is normal for public endpoints like send-otp
    // No need to log when user is not logged in (expected behavior)
    
    return token;
  }
  

  // Refresh token management
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyRefreshToken, token);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyRefreshToken);
  }

  // Save both tokens
  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyToken, accessToken); // Keep for backward compatibility
    
    if (kDebugMode) {
      print('✅ [TOKEN STORAGE] Both tokens saved successfully');
      print('   Access token length: ${accessToken.length}');
      print('   Refresh token length: ${refreshToken.length}');
      // Verify tokens were saved
      final savedAccess = await prefs.getString(_keyAccessToken);
      final savedRefresh = await prefs.getString(_keyRefreshToken);
      if (savedAccess != null && savedAccess == accessToken && 
          savedRefresh != null && savedRefresh == refreshToken) {
        print('   ✅ Both tokens verified in storage');
      } else {
        print('   ⚠️ Warning: Tokens may not have been saved correctly');
      }
    }
  }

  // Clear all tokens
  static Future<void> clearAllTokens() async {
    final prefs = await _prefs;
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyToken);
  }

  // User data management
  static Future<void> saveUserData({
    required int userId,
    required String role,
    required String phone,
    String? name,
    String? email,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserPhone, phone);
    if (name != null) {
      await prefs.setString(_keyUserName, name);
    }
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    }
  }

  static Future<int?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyUserId);
  }

  static Future<String?> getUserRole() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserRole);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserPhone);
  }

  static Future<String?> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserEmail);
  }

  // Clear all user data
  // Referral code and reward balance
  static Future<void> saveReferralCode(String referralCode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyReferralCode, referralCode);
  }

  static Future<String?> getReferralCode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyReferralCode);
  }

  static Future<void> saveRewardBalance(double balance) async {
    final prefs = await _prefs;
    await prefs.setDouble(_keyRewardBalance, balance);
  }

  static Future<double> getRewardBalance() async {
    final prefs = await _prefs;
    return prefs.getDouble(_keyRewardBalance) ?? 0.0;
  }

  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await clearAllTokens();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyReferralCode);
    await prefs.remove(_keyRewardBalance);
    // Clear wishlist when user logs out
    await clearWishlist();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Wishlist management - User-specific wishlist
  static Future<String> _getWishlistKey() async {
    final userId = await getUserId();
    // Use user-specific key to prevent wishlist sharing between users
    return userId != null ? '${_keyWishlist}_$userId' : _keyWishlist;
  }

  static Future<void> addToWishlist(int productId) async {
    final prefs = await _prefs;
    final wishlistKey = await _getWishlistKey();
    final wishlist = await getWishlist();
    if (!wishlist.contains(productId)) {
      wishlist.add(productId);
      await prefs.setStringList(wishlistKey, wishlist.map((id) => id.toString()).toList());
    }
  }

  static Future<void> removeFromWishlist(int productId) async {
    final prefs = await _prefs;
    final wishlistKey = await _getWishlistKey();
    final wishlist = await getWishlist();
    wishlist.remove(productId);
    await prefs.setStringList(wishlistKey, wishlist.map((id) => id.toString()).toList());
  }

  static Future<List<int>> getWishlist() async {
    final prefs = await _prefs;
    final wishlistKey = await _getWishlistKey();
    final wishlistStrings = prefs.getStringList(wishlistKey) ?? [];
    return wishlistStrings.map((id) => int.tryParse(id) ?? 0).where((id) => id > 0).toList();
  }

  static Future<bool> isInWishlist(int productId) async {
    final wishlist = await getWishlist();
    return wishlist.contains(productId);
  }

  static Future<void> toggleWishlist(int productId) async {
    if (await isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  static Future<void> clearWishlist() async {
    final prefs = await _prefs;
    // Clear current user's wishlist
    final wishlistKey = await _getWishlistKey();
    await prefs.remove(wishlistKey);
    // Also clear legacy wishlist key for backward compatibility
    await prefs.remove(_keyWishlist);
  }
}

