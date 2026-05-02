// lib/utils/app_constants.dart

class AppConstants {
  AppConstants._();

  // Base URL
  // Menggunakan Cloudflare Tunnel agar koneksi stabil dan global
  static const String baseUrl = 'https://utilization-paxil-suffering-asking.trycloudflare.com/api';

  // Auth
  static const String loginEndpoint        = '/auth/login';
  static const String nfcLoginEndpoint     = '/auth/nfc-login';
  static const String guruLoginEndpoint    = '/auth/admin/login';
  static const String refreshEndpoint      = '/auth/refresh';
  static const String logoutEndpoint       = '/auth/logout';

  // Menu
  static const String menuEndpoint         = '/menu';
  static const String categoriesEndpoint   = '/menu/categories';

  // Transaction
  static const String transactionsEndpoint = '/transactions';

  // Student
  static const String profileEndpoint      = '/students/me';
  static const String nfcCardsEndpoint     = '/students/nfc-cards';
  static const String studentsListEndpoint = '/students';
  static const String mutationsEndpoint       = '/students/me/mutations';
  static const String topupRequestEndpoint    = '/students/me/topup-request';
  static const String topupRequestsEndpoint   = '/students/topup-requests';
  static const String studentLookupEndpoint   = '/students/lookup';
  static const String transferEndpoint        = '/students/me/transfer';

  // IoT
  static const String devicesEndpoint      = '/iot/devices';
  static const String heartbeatEndpoint    = '/iot/heartbeat';

  // Local storage keys
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyStudentData  = 'student_data';
  static const String keyGuruData     = 'guru_data';
  static const String keyUserRole     = 'user_role';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
