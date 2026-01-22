/// Key constants for storage and identifiers
final class KeyConstants {
  KeyConstants._();

  // SharedPreferences keys
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String isFirstLaunch = 'is_first_launch';
  static const String selectedLanguage = 'selected_language';

  // Hive box names
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // Widget keys
  static const String materialAppMain = 'material_app_main';
}
