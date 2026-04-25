// lib/services/auth_service.dart
import 'dart:convert';
import '../models/student.dart';
import '../models/guru.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api     = ApiClient.instance;
  final _storage = TokenStorage.instance;

  // Login siswa dengan NISN + PIN
  Future<Student> loginWithPin({
    required String nisn,
    required String pin,
  }) async {
    final response = await _api.post(
      AppConstants.loginEndpoint,
      {'nisn': nisn, 'pin': pin},
      withAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final student = Student.fromJson(data['student'] as Map<String, dynamic>);

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _storage.saveStudentData(json.encode(student.toJson()));
    await _storage.saveUserRole('student');

    return student;
  }

  // Login siswa dengan tap kartu NFC
  Future<Student> loginWithNfc(String uid) async {
    final response = await _api.post(
      AppConstants.nfcLoginEndpoint,
      {'uid': uid},
      withAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final student = Student.fromJson(data['student'] as Map<String, dynamic>);

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _storage.saveStudentData(json.encode(student.toJson()));
    await _storage.saveUserRole('student');

    return student;
  }

  // Login guru dengan username + password
  Future<Guru> loginWithPinGuru({
    required String username,
    required String password,
  }) async {
    final response = await _api.post(
      AppConstants.guruLoginEndpoint,
      {'username': username, 'password': password},
      withAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final guru = Guru.fromJson(data['admin'] as Map<String, dynamic>);

    // Admin login hanya mengembalikan accessToken (tanpa refreshToken)
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: '',
    );
    await _storage.saveGuruData(json.encode(guru.toJson()));
    await _storage.saveUserRole('guru');

    return guru;
  }

  // Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _api.post(
          AppConstants.logoutEndpoint,
          {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Tetap hapus token lokal meski request gagal
    } finally {
      await _storage.clearAll();
    }
  }

  // Cek apakah sudah login
  Future<bool> isLoggedIn() => _storage.hasToken();

  // Ambil role tersimpan
  Future<String?> getUserRole() => _storage.getUserRole();

  // Ambil data siswa tersimpan lokal
  Future<Student?> getCachedStudent() async {
    final raw = await _storage.getStudentData();
    if (raw == null) return null;
    try {
      return Student.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Ambil data guru tersimpan lokal
  Future<Guru?> getCachedGuru() async {
    final raw = await _storage.getGuruData();
    if (raw == null) return null;
    try {
      return Guru.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
