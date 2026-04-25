// lib/services/topup_service.dart
import '../models/student.dart';
import '../models/mutation.dart';
import '../models/topup_request.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class TopupService {
  TopupService._();
  static final TopupService instance = TopupService._();

  final _api = ApiClient.instance;

  // ── Guru: ambil daftar siswa (dengan opsional pencarian) ───────
  Future<List<Student>> getStudents({String? search, int page = 1}) async {
    final params = <String, String>{'page': '$page', 'limit': '30'};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _api.get(
      AppConstants.studentsListEndpoint,
      queryParams: params,
    );
    final data = response['data'] as List<dynamic>;
    return data.map((s) => Student.fromJson(s as Map<String, dynamic>)).toList();
  }

  // ── Guru: top-up saldo siswa ───────────────────────────────────
  Future<Map<String, dynamic>> topupStudent({
    required String studentId,
    required int amount,
  }) async {
    final response = await _api.post(
      '${AppConstants.studentsListEndpoint}/$studentId/topup',
      {'amount': amount},
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Siswa: kirim permintaan top-up ────────────────────────────
  Future<void> requestTopup({required int amount, String? notes}) async {
    await _api.post(
      AppConstants.topupRequestEndpoint,
      <String, dynamic>{
        'amount': amount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  // ── Siswa: ambil riwayat mutasi (pembelian + top-up) ──────────
  Future<List<Mutation>> getMutations({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      AppConstants.mutationsEndpoint,
      queryParams: {'page': '$page', 'limit': '$limit'},
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((m) => Mutation.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // ── Guru: ambil daftar permintaan top-up siswa ────────────────
  Future<List<TopupRequest>> getTopupRequests({
    String status = 'PENDING',
    int page = 1,
  }) async {
    final response = await _api.get(
      AppConstants.topupRequestsEndpoint,
      queryParams: {'status': status, 'page': '$page', 'limit': '30'},
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((r) => TopupRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Guru: setujui permintaan top-up ──────────────────────────
  Future<Map<String, dynamic>> approveTopupRequest(String requestId) async {
    final response = await _api.post(
      '${AppConstants.topupRequestsEndpoint}/$requestId/approve',
      {},
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  // ── Guru: tolak permintaan top-up ────────────────────────────
  Future<void> rejectTopupRequest(String requestId) async {
    await _api.post(
      '${AppConstants.topupRequestsEndpoint}/$requestId/reject',
      {},
    );
  }

  // ── Siswa: cari penerima transfer berdasarkan NISN ────────────
  Future<Map<String, dynamic>> lookupStudent(String nisn) async {
    final response = await _api.get(
      AppConstants.studentLookupEndpoint,
      queryParams: {'nisn': nisn},
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Siswa: transfer saldo ke siswa lain ───────────────────────
  Future<Map<String, dynamic>> transferBalance({
    required String receiverNisn,
    required int amount,
    String? note,
  }) async {
    final response = await _api.post(
      AppConstants.transferEndpoint,
      <String, dynamic>{
        'receiverNisn': receiverNisn,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return response['data'] as Map<String, dynamic>;
  }
}
