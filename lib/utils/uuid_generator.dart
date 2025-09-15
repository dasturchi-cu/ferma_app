import 'dart:math';

class UuidGenerator {
  static final Random _random = Random.secure();
  
  /// Generates a UUID v4 string
  static String generateUuid() {
    // Generate 16 random bytes
    var bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10
    
    // Convert to hex string with hyphens
    var hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
  
  /// Validates if a string is a valid UUID format
  static bool isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(uuid);
  }
  
  /// Generates a short readable ID (for display purposes)
  static String generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}