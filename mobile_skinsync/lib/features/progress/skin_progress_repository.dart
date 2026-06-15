import 'dart:io';

import 'skin_progress_models.dart';

class SkinProgressRepository {
  Future<SkinProgressDashboard> fetchDashboard({
    required String periodType,
    required DateTime anchorDate,
  }) {
    throw UnimplementedError('SkinProgressRepository.fetchDashboard');
  }

  Future<List<SkinProgressPhoto>> fetchPhotos() {
    throw UnimplementedError('SkinProgressRepository.fetchPhotos');
  }

  Future<SkinProgressReportDetail> fetchReport(String reportId) {
    throw UnimplementedError('SkinProgressRepository.fetchReport');
  }

  Future<List<SkinProgressReportSummary>> fetchReports() {
    throw UnimplementedError('SkinProgressRepository.fetchReports');
  }

  Future<SkinProgressPhoto> uploadPhoto({
    required File imageFile,
    String? note,
  }) {
    throw UnimplementedError('SkinProgressRepository.uploadPhoto');
  }

  Future<void> analyzePhoto(String photoId) {
    throw UnimplementedError('SkinProgressRepository.analyzePhoto');
  }

  Future<void> deletePhoto(String photoId) {
    throw UnimplementedError('SkinProgressRepository.deletePhoto');
  }

  Future<SkinProgressComparison> comparePhotos({
    required String beforePhotoId,
    required String afterPhotoId,
  }) {
    throw UnimplementedError('SkinProgressRepository.comparePhotos');
  }

  Future<SkinProgressReportDetail> generateReport({
    required String periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    throw UnimplementedError('SkinProgressRepository.generateReport');
  }
}
