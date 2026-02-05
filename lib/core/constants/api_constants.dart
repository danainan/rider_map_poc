/// API constants for the application
class ApiConstants {
  ApiConstants._();

  /// Google Maps API Key
  /// For POC: Using dart-define or fallback to hardcoded key
  /// Run with: flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String longDoMapApiKey = '';
}
