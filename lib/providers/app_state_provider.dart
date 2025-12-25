import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

import '../models/app_settings.dart';
import '../models/upload_log.dart';
import '../services/file_watcher_service.dart';
import '../services/upload_service.dart';
import '../services/file_manager_service.dart';
import '../services/logging_service.dart';

class AppStateProvider extends ChangeNotifier {
  // Services
  final FileWatcherService _fileWatcher = FileWatcherService();
  final UploadService _uploadService = UploadService();
  final FileManagerService _fileManager = FileManagerService();
  final LoggingService _loggingService = LoggingService();

  // State
  AppSettings _settings = AppSettings.empty();
  bool _isMonitoring = false;
  bool _isInitialized = false;
  StreamSubscription? _fileWatcherSubscription;

  // Getters
  AppSettings get settings => _settings;

  bool get isMonitoring => _isMonitoring;

  bool get isInitialized => _isInitialized;

  List<UploadLog> get logs => _loggingService.logs;

  // Statistics
  int get totalUploads => _loggingService.getTotalUploads();

  int get uploadsToday => _loggingService.getUploadsFromTodayCount();

  double get successRate => _loggingService.getSuccessRate();

  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loggingService.initialize();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('app_settings');

      if (settingsJson != null) {
        _settings = AppSettings.fromJson(json.decode(settingsJson));
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', json.encode(_settings.toJson()));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    // If monitoring folder changed and currently monitoring, stop first
    if (_isMonitoring &&
        newSettings.monitoredFolderPath != _settings.monitoredFolderPath) {
      await stopMonitoring();
    }

    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // Start monitoring
  Future<bool> startMonitoring() async {
    if (_isMonitoring) return true;

    if (!_settings.isValid) {
      return false;
    }

    try {
      await _fileWatcher.startWatching(_settings.monitoredFolderPath!);

      // Subscribe to new file events
      _fileWatcherSubscription = _fileWatcher.newFileStream.listen(
        (file) => _handleNewFile(file),
        onError: (error) {
          print('File watcher error: $error');
        },
      );

      _isMonitoring = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error starting monitoring: $e');
      return false;
    }
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    await _fileWatcherSubscription?.cancel();
    _fileWatcherSubscription = null;
    await _fileWatcher.stopWatching();

    _isMonitoring = false;
    notifyListeners();
  }

  // Handle new file detected
  Future<void> _handleNewFile(File file) async {
    await uploadFile(file);
  }

  // Upload a file
  Future<void> uploadFile(File file) async {
    if (!_settings.isValid) return;

    // Create initial log entry
    final logId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileSize = await _fileManager.getFileSize(file);

    final log = UploadLog(
      id: logId,
      fileName: path.basename(file.path),
      filePath: file.path,
      timestamp: DateTime.now(),
      status: UploadStatus.inProgress,
      fileSizeBytes: fileSize,
    );

    await _loggingService.addLog(log);
    notifyListeners();

    // Perform upload
    final result = await _uploadService.uploadFile(file, _settings.uploadUrl!);

    // Update log with result
    final updatedLog = log.copyWith(
      status: result.success ? UploadStatus.success : UploadStatus.failure,
      errorMessage: result.errorMessage,
    );

    await _loggingService.updateLog(logId, updatedLog);

    // Move file to uploaded folder if successful
    if (result.success) {
      await _fileManager.moveToUploadedFolder(
        file,
        _settings.monitoredFolderPath!,
      );
    }

    notifyListeners();
  }

  // Upload file manually
  Future<bool> uploadFileManually(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return false;
      }

      await uploadFile(file);
      return true;
    } catch (e) {
      print('Error uploading file manually: $e');
      return false;
    }
  }

  // Filter logs by status
  List<UploadLog> getLogsByStatus(UploadStatus? status) {
    if (status == null) return logs;
    return _loggingService.getLogsByStatus(status);
  }

  // Search logs
  List<UploadLog> searchLogs(String query) {
    return _loggingService.searchLogs(query);
  }

  // Clear all logs
  Future<void> clearAllLogs() async {
    await _loggingService.clearAllLogs();
    notifyListeners();
  }

  // Export logs
  String exportLogs() {
    return _loggingService.exportLogsToJson();
  }

  @override
  void dispose() {
    _fileWatcherSubscription?.cancel();
    _fileWatcher.dispose();
    _uploadService.dispose();
    super.dispose();
  }
}
