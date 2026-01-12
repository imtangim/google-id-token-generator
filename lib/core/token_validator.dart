import 'dart:convert';

/// Utility class for validating JWT tokens and checking expiration.
class TokenValidator {
  /// Decodes a JWT token and extracts the payload.
  /// Returns null if the token is invalid or cannot be decoded.
  static Map<String, dynamic>? decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed for base64 decoding
      String normalizedPayload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (normalizedPayload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = utf8.decode(base64Decode(normalizedPayload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Gets the expiration time from a JWT token.
  /// Returns null if the token cannot be decoded or doesn't have an exp claim.
  static DateTime? getExpirationTime(String token) {
    final payload = decodeJWT(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null) return null;

    // JWT exp is in seconds since epoch
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    if (exp is double) {
      return DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt(), isUtc: true);
    }
    return null;
  }

  /// Checks if a token is expired.
  /// Returns true if expired, false if valid, null if cannot be determined.
  static bool? isExpired(String token) {
    final expiration = getExpirationTime(token);
    if (expiration == null) return null;
    return expiration.isBefore(DateTime.now().toUtc());
  }

  /// Gets the time remaining until expiration.
  /// Returns null if the expiration cannot be determined.
  static Duration? getTimeUntilExpiration(String token) {
    final expiration = getExpirationTime(token);
    if (expiration == null) return null;
    return expiration.difference(DateTime.now().toUtc());
  }

  /// Checks if a token will expire within the specified duration.
  /// Useful for proactive refresh before expiration.
  static bool willExpireWithin(String token, Duration duration) {
    final timeRemaining = getTimeUntilExpiration(token);
    if (timeRemaining == null) return false;
    return timeRemaining <= duration;
  }

  /// Formats the expiration time as a human-readable string.
  static String? formatExpirationTime(String token) {
    final expiration = getExpirationTime(token);
    if (expiration == null) return null;
    return expiration.toLocal().toString().split('.')[0];
  }

  /// Formats the time remaining until expiration as a human-readable string.
  static String? formatTimeRemaining(String token) {
    final duration = getTimeUntilExpiration(token);
    if (duration == null) return null;

    if (duration.isNegative) {
      return 'Expired ${_formatDuration(duration.abs())} ago';
    }

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s remaining';
    } else {
      return '${duration.inSeconds}s remaining';
    }
  }

  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

