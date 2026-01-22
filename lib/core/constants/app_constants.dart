/// Application constants
final class AppConstants {
  AppConstants._();

  static const String appName = 'Rider Map POC';
  static const String appVersion = '1.0.0';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);

  // Map
  static const double defaultMapZoom = 15.0;
  static const double minMapZoom = 10.0;
  static const double maxMapZoom = 20.0;

  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // Rider Simulation
  static const Duration riderUpdateInterval = Duration(milliseconds: 500);
}
