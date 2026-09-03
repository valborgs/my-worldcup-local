/// Versioned contract shared by Dart, Android, and iOS channel messages.
abstract final class NearbyProtocol {
  static const int version = 1;

  /// The only source of truth for the service ID. Both native implementations
  /// receive this value in every operation instead of defining their own IDs.
  static const String serviceId = 'org.comon.my_worldcup_local.nearby';

  static const String methodChannel =
      'org.comon.my_worldcup_local/nearby_transfer/methods';
  static const String eventChannel =
      'org.comon.my_worldcup_local/nearby_transfer/events';

  /// First 12 bytes of SHA-256(serviceId), uppercase hex, as required by the
  /// Google Nearby Swift setup guide.
  static const String bonjourServiceType = '_D0D7E2C1A414781E73C5F15B._tcp';
}
