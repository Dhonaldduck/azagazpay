// lib/services/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  // Simpan token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, accessToken);
    if (refreshToken.isNotEmpty) {
      await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
    }
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, token);
  }

  // Ambil token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Simpan data siswa
  Future<void> saveStudentData(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyStudentData, jsonString);
  }

  Future<String?> getStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyStudentData);
  }

  // Simpan data guru
  Future<void> saveGuruData(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyGuruData, jsonString);
  }

  Future<String?> getGuruData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyGuruData);
  }

  // Simpan & ambil role pengguna
  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserRole, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserRole);
  }

  // Hapus semua (logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyStudentData);
    await prefs.remove(AppConstants.keyGuruData);
    await prefs.remove(AppConstants.keyUserRole);
  }
}
