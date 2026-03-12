import 'dart:convert';

/// Utility class for JWT token operations
class JwtUtils {
  /// Decode JWT token and extract payload
  /// Returns null if token is invalid or cannot be decoded
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      // JWT tokens have 3 parts separated by dots: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed (base64 requires padding)
      String normalizedPayload = payload;
      final padding = 4 - (payload.length % 4);
      if (padding != 4) {
        normalizedPayload = payload + '=' * padding;
      }

      // Decode base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      
      // Parse JSON
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error decoding JWT token: $e');
      return null;
    }
  }

  /// Extract role from JWT token
  /// Returns null if token is invalid or role is missing
  static String? getRoleFromToken(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;
    
    // Role might be stored as 'role' in the payload
    final role = payload['role'] as String?;
    return role?.toLowerCase();
  }

  /// Extract user ID from JWT token
  /// Returns null if token is invalid or ID is missing
  static int? getUserIdFromToken(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;
    
    final id = payload['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  /// Check if token role matches expected role
  static bool tokenRoleMatches(String token, String expectedRole) {
    final tokenRole = getRoleFromToken(token);
    if (tokenRole == null) return false;
    
    // Normalize both roles to lowercase for comparison
    return tokenRole.toLowerCase() == expectedRole.toLowerCase();
  }
}












