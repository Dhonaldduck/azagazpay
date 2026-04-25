// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/guru.dart';
import '../services/auth_service.dart';
import '../utils/app_exceptions.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

enum UserRole { student, guru }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status   = AuthStatus.initial;
  UserRole   _userRole = UserRole.student;
  Student?   _student;
  Guru?      _guru;
  String?    _errorMessage;

  final _authService = AuthService.instance;

  AuthStatus get status       => _status;
  UserRole   get userRole     => _userRole;
  Student?   get student      => _student;
  Guru?      get guru         => _guru;
  String?    get errorMessage => _errorMessage;
  bool       get isLoading    => _status == AuthStatus.loading;
  bool       get isLoggedIn   => _status == AuthStatus.authenticated;
  bool       get isGuru       => _userRole == UserRole.guru;

  // Init: cek token tersimpan
  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        final role = await _authService.getUserRole();
        if (role == 'guru') {
          _userRole = UserRole.guru;
          _guru = await _authService.getCachedGuru();
          _status = _guru != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
        } else {
          _userRole = UserRole.student;
          _student = await _authService.getCachedStudent();
          _status = _student != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Login siswa NISN + PIN
  Future<bool> loginWithPin({
    required String nisn,
    required String pin,
  }) async {
    _setLoading();
    try {
      _student  = await _authService.loginWithPin(nisn: nisn, pin: pin);
      _userRole = UserRole.student;
      _status   = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } on NetworkException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan, coba lagi');
      return false;
    }
  }

  // Login siswa NFC
  Future<bool> loginWithNfc(String uid) async {
    _setLoading();
    try {
      _student  = await _authService.loginWithNfc(uid);
      _userRole = UserRole.student;
      _status   = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } on NetworkException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Kartu tidak dikenali');
      return false;
    }
  }

  // Login guru username + password
  Future<bool> loginWithPinGuru({
    required String username,
    required String password,
  }) async {
    _setLoading();
    try {
      _guru     = await _authService.loginWithPinGuru(username: username, password: password);
      _userRole = UserRole.guru;
      _status   = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } on NetworkException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan, coba lagi');
      return false;
    }
  }

  // Update saldo setelah transaksi
  void updateBalance(int newBalance) {
    if (_student == null) return;
    _student = _student!.copyWith(balance: newBalance);
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _student  = null;
    _guru     = null;
    _userRole = UserRole.student;
    _status   = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Helpers
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
