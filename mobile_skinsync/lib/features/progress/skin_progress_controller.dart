import 'dart:io';

import 'package:flutter/foundation.dart';

import 'skin_progress_models.dart';
import 'skin_progress_repository.dart';

class SkinProgressController extends ChangeNotifier {
  SkinProgressController(this._repository);

  final SkinProgressRepository _repository;

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
    notifyListeners();
    try {
      dashboard = await _repository.fetchDashboard(
        periodType: periodType,
        anchorDate: anchorDate,
      );
      photos = await _repository.fetchPhotos();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReports() async {
    try {
      reports = await _repository.fetchReports();
    } catch (_) {
      reports = const [];
    }
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      await _repository.deletePhoto(photoId);
      await refresh();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
    }
  }

  Future<SkinProgressReportDetail> generateCurrentReport() async {
    final period = _resolvePeriod();
    isGeneratingReport = true;
    errorMessage = null;
    notifyListeners();
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
      notifyListeners();
    }
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
}
