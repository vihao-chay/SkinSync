import 'dart:io';

import 'package:flutter/foundation.dart';

import 'skin_progress_models.dart';
import 'skin_progress_repository.dart';

class SkinProgressController extends ChangeNotifier {
  SkinProgressController(this._repository);

  final SkinProgressRepository _repository;
  bool _isDisposed = false;

  String periodType = 'monthly';
  DateTime anchorDate = DateTime.now();
  SkinProgressDashboard? dashboard;
  List<SkinProgressPhoto> photos = const [];
  List<SkinProgressReportSummary> reports = const [];
  bool isLoading = false;
  bool isUploading = false;
  bool isComparing = false;
  bool isGeneratingReport = false;
  String? errorMessage;

  Future<void> loadInitial() async {
    await Future.wait([refresh(), loadReports()]);
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    _notifySafely();
    try {
      await _loadDashboardAndPhotos();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      _notifySafely();
    }
  }

  Future<void> loadReports() async {
    try {
      reports = await _repository.fetchReports();
    } catch (_) {
      reports = const [];
    }
    _notifySafely();
  }

  Future<void> setPeriodType(String value) async {
    if (periodType == value) {
      return;
    }
    periodType = value;
    await refresh();
  }

  Future<void> setAnchorDate(DateTime value) async {
    anchorDate = value;
    await refresh();
  }

  Future<void> uploadAndAnalyze(File file, {String? note}) async {
    isUploading = true;
    errorMessage = null;
    _notifySafely();
    try {
      final photo = await _repository.uploadPhoto(imageFile: file, note: note);
      await _repository.analyzePhoto(photo.photoId);
      await refresh();
      await loadReports();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isUploading = false;
      _notifySafely();
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      await _repository.deletePhoto(photoId);
      await refresh();
    } catch (error) {
      errorMessage = error.toString();
      _notifySafely();
      rethrow;
    }
  }

  Future<SkinProgressComparison> compareCurrentJourney() async {
    final before = dashboard?.visualJourney.beforePhoto;
    final after = dashboard?.visualJourney.afterPhoto;
    if (before == null || after == null) {
      throw Exception('Add another photo to compare progress.');
    }

    isComparing = true;
    errorMessage = null;
    _notifySafely();
    try {
      return await _repository.comparePhotos(
        beforePhotoId: before.photoId,
        afterPhotoId: after.photoId,
      );
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isComparing = false;
      _notifySafely();
    }
  }

  Future<SkinProgressReportDetail> generateCurrentReport() async {
    final period = _resolvePeriod();
    isGeneratingReport = true;
    errorMessage = null;
    _notifySafely();
    try {
      final report = await _repository.generateReport(
        periodType: periodType,
        periodStart: period.$1,
        periodEnd: period.$2,
      );
      await refresh();
      await loadReports();
      return report;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isGeneratingReport = false;
      _notifySafely();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<SkinProgressReportDetail> openReport(String reportId) {
    return _repository.fetchReport(reportId);
  }

  (DateTime, DateTime) _resolvePeriod() {
    if (periodType == 'weekly') {
      final start = anchorDate.subtract(Duration(days: anchorDate.weekday - 1));
      final normalized = DateTime(start.year, start.month, start.day);
      return (normalized, normalized.add(const Duration(days: 6)));
    }

    if (periodType == 'yearly') {
      return (
        DateTime(anchorDate.year, 1, 1),
        DateTime(anchorDate.year, 12, 31),
      );
    }

    return (
      DateTime(anchorDate.year, anchorDate.month, 1),
      DateTime(anchorDate.year, anchorDate.month + 1, 0),
    );
  }

  Future<void> _loadDashboardAndPhotos() async {
    dashboard = await _repository.fetchDashboard(
      periodType: periodType,
      anchorDate: anchorDate,
    );
    photos = await _repository.fetchPhotos();

    if (photos.isEmpty || dashboard?.hasPhotos == true) {
      return;
    }

    final latestPhotoDate = photos.first.photoDate;
    if (_isDateInCurrentPeriod(latestPhotoDate)) {
      return;
    }

    anchorDate = latestPhotoDate;
    dashboard = await _repository.fetchDashboard(
      periodType: periodType,
      anchorDate: anchorDate,
    );
  }

  bool _isDateInCurrentPeriod(DateTime value) {
    final period = _resolvePeriod();
    final normalized = DateTime(value.year, value.month, value.day);
    return !normalized.isBefore(period.$1) && !normalized.isAfter(period.$2);
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }
}
