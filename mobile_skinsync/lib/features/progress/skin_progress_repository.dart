import 'dart:io';

import '../../core/services/api_client.dart';
import 'skin_progress_models.dart';

class SkinProgressRepository {
  SkinProgressRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<SkinProgressDashboard> fetchDashboard({
    required String periodType,
    required DateTime anchorDate,
  }) async {
    final query = <String, dynamic>{'periodType': periodType};
    if (periodType == 'weekly') {
      final weekStart = anchorDate.subtract(Duration(days: anchorDate.weekday - 1));
      query['weekStart'] = _dateOnly(weekStart);
    } else if (periodType == 'yearly') {
      query['year'] = anchorDate.year;
    } else {
      query['month'] =
          '${anchorDate.year.toString().padLeft(4, '0')}-${anchorDate.month.toString().padLeft(2, '0')}';
    }

    final response = await _apiClient.get('/api/skin-progress/dashboard', query: query);
    return SkinProgressDashboard.fromJson(response);
  }

  Future<List<SkinProgressPhoto>> fetchPhotos() async {
    final response = await _apiClient.get('/api/skin-progress/photos');
    final items = (response['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SkinProgressPhoto.fromJson)
        .toList();
  }

  Future<SkinProgressPhoto> uploadPhoto({
    required File imageFile,
    DateTime? photoDate,
    String? note,
  }) async {
    final response = await _apiClient.multipart(
      '/api/skin-progress/photos',
      file: imageFile,
      fields: {
        'photoDate': _dateOnly(photoDate ?? DateTime.now()),
        'timeOfDay': _timeOfDay(DateTime.now()),
        'lightingCondition': 'unknown',
        'faceAngle': 'front',
        'note': note?.trim() ?? '',
      },
    );
    return SkinProgressPhoto.fromJson(response);
  }

  Future<void> deletePhoto(String photoId) {
    return _apiClient.delete('/api/skin-progress/photos/$photoId');
  }

  Future<void> analyzePhoto(String photoId) async {
    final response = await _apiClient.post(
      '/api/ai/skin-progress/analyze',
      body: {'photoId': photoId},
    );
    _readAiData(response);
  }

  Future<SkinProgressComparison> comparePhotos({
    required String beforePhotoId,
    required String afterPhotoId,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/skin-progress/compare',
      body: {
        'beforePhotoId': beforePhotoId,
        'afterPhotoId': afterPhotoId,
      },
    );
    return SkinProgressComparison.fromJson(_readAiData(response));
  }

  Future<SkinProgressReportDetail> generateReport({
    required String periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/skin-progress/report',
      body: {
        'periodType': periodType,
        'periodStart': _dateOnly(periodStart),
        'periodEnd': _dateOnly(periodEnd),
      },
    );
    return SkinProgressReportDetail.fromJson(_readAiData(response));
  }

  Future<List<SkinProgressReportSummary>> fetchReports() async {
    final response = await _apiClient.get('/api/skin-progress/reports');
    final items = (response['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SkinProgressReportSummary.fromJson)
        .toList();
  }

  Future<SkinProgressReportDetail> fetchReport(String reportId) async {
    final response = await _apiClient.get('/api/skin-progress/reports/$reportId');
    return SkinProgressReportDetail.fromJson(response);
  }

  Map<String, dynamic> _readAiData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return response;
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _timeOfDay(DateTime value) {
    if (value.hour < 12) {
      return 'morning';
    }
    if (value.hour < 18) {
      return 'afternoon';
    }
    return 'night';
  }
}
