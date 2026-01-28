import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastAuthTime = 'last_auth_time';
  static const String _keyAuthRetryLimit = 'auth_retry_limit';
  static const String _keyRequireAuthExport = 'require_auth_export';
  static const String _keyRequireAuthRestore = 'require_auth_restore';

  static final PreferencesService _instance = PreferencesService._internal();
  static SharedPreferences? _prefs;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  /// Initialize SharedPreferences (call once on app startup)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  static Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  // Biometric Lock Settings
  Future<bool> isBiometricEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyBiometricEnabled) ?? true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    print('Biometric lock ${enabled ? 'enabled' : 'disabled'}');
  }

  // Last Authentication Time
  Future<DateTime?> getLastAuthTime() async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getInt(_keyLastAuthTime);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLastAuthTime(DateTime dateTime) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyLastAuthTime, dateTime.millisecondsSinceEpoch);
  }

  // Authentication Retry Limit (3-10)
  Future<int> getAuthRetryLimit() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyAuthRetryLimit) ?? 5;
  }

  Future<void> setAuthRetryLimit(int limit) async {
    final prefs = await _getPrefs();
    // Clamp between 3 and 10
    final clampedLimit = limit.clamp(3, 10);
    await prefs.setInt(_keyAuthRetryLimit, clampedLimit);
    print('Auth retry limit set to: $clampedLimit');
  }

  // Require Auth for Export
  Future<bool> requireAuthForExport() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyRequireAuthExport) ?? false;
  }

  Future<void> setRequireAuthForExport(bool required) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyRequireAuthExport, required);
    print('Auth for export ${required ? 'enabled' : 'disabled'}');
  }

  // Require Auth for Restore
  Future<bool> requireAuthForRestore() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyRequireAuthRestore) ?? true;
  }

  Future<void> setRequireAuthForRestore(bool required) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyRequireAuthRestore, required);
    print('Auth for restore ${required ? 'enabled' : 'disabled'}');
  }

  // Clear all security settings (for testing only)
  Future<void> clearAllSecuritySettings() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keyLastAuthTime);
    await prefs.remove(_keyAuthRetryLimit);
    await prefs.remove(_keyRequireAuthExport);
    await prefs.remove(_keyRequireAuthRestore);
    print('All security settings cleared');
  }

  // Get formatted last auth time
  Future<String> getFormattedLastAuthTime() async {
    final prefs = await _getPrefs();
    final lastAuth = prefs.getInt(_keyLastAuthTime);
    if (lastAuth == null) {
      return 'Never';
    }
    final dateTime = DateTime.fromMillisecondsSinceEpoch(lastAuth);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}
