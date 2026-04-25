// lib/services/student_service.dart
import '../models/student.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'dart:convert';

class StudentService {
  StudentService._();
  static final StudentService instance = StudentService._();

  final _api     = ApiClient.instance;
  final _storage = TokenStorage.instance;

  // ── Ambil profil & saldo terbaru ──────────────────────────────
  Future<Student> getProfile() async {
    final response = await _api.get(AppConstants.profileEndpoint);
    final student = Student.fromJson(
      response['data'] as Map<String, dynamic>,
    );
    // Update cache lokal
    await _storage.saveStudentData(json.encode(student.toJson()));
    return student;
  }

  // ── Daftarkan kartu NFC baru ──────────────────────────────────
  Future<String> registerNfcCard(String uid) async {
    final response = await _api.post(
      AppConstants.nfcCardsEndpoint,
      {'uid': uid},
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['uidMasked'] as String;
  }
}
