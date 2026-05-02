import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class ServerConfigService {
  static const String _keyBaseUrl = 'custom_base_url';
  
  ServerConfigService._();
  static final ServerConfigService instance = ServerConfigService._();

  /// Ambil URL server dari storage, jika kosong pakai default dari AppConstants
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? AppConstants.baseUrl;
  }

  /// Simpan URL server baru
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Pastikan format benar (tidak diakhiri slash)
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await prefs.setString(_keyBaseUrl, cleanUrl);
  }

  /// Reset ke IP awal
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
  }
}
