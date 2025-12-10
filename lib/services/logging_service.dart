import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/upload_log.dart';

class LoggingService {
  static const String _logsKey = 'upload_logs';
  static const int maxLogs = 1000;

  final List<UploadLog> _logs = [];
  SharedPreferences? _prefs;

  // Get all logs
  List<UploadLog> get logs => List.unmodifiable(_logs);

  // Initialize and load logs from storage
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLogs();
  }

  // Load logs from storage
  Future<void> _loadLogs() async {
    try {
      final logsJson = _prefs?.getStringList(_logsKey) ?? [];
      _logs.clear();

      for (final logJson in logsJson) {
        try {
          final log = UploadLog.fromJson(json.decode(logJson));
          _logs.add(log);
        } catch (e) {
          print('Error parsing log: $e');
        }
      }

      // Sort by timestamp (newest first)
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading logs: $e');
    }
  }

  // Save logs to storage
  Future<void> _saveLogs() async {
    try {
      final logsJson = _logs.map((log) => json.encode(log.toJson())).toList();
      await _prefs?.setStringList(_logsKey, logsJson);
    } catch (e) {
      print('Error saving logs: $e');
    }
  }

  // Add a new log entry
  Future<void> addLog(UploadLog log) async {
    _logs.insert(0, log); // Add to beginning (newest first)

    // Limit the number of logs
    if (_logs.length > maxLogs) {
      _logs.removeRange(maxLogs, _logs.length);
    }

    await _saveLogs();
  }

  // Update an existing log
  Future<void> updateLog(String id, UploadLog updatedLog) async {
    final index = _logs.indexWhere((log) => log.id == id);
    if (index != -1) {
      _logs[index] = updatedLog;
      await _saveLogs();
    }
  }

  // Get logs by status
  List<UploadLog> getLogsByStatus(UploadStatus status) {
    return _logs.where((log) => log.status == status).toList();
  }

  // Get logs from today
  List<UploadLog> getLogsFromToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _logs.where((log) {
      final logDate = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      return logDate.isAtSameMomentAs(today);
    }).toList();
  }

  // Get success rate
  double getSuccessRate() {
    if (_logs.isEmpty) return 0.0;

    final successCount = _logs
        .where((log) => log.status == UploadStatus.success)
        .length;
    return (successCount / _logs.length) * 100;
  }

  // Get total uploads count
  int getTotalUploads() {
    return _logs.where((log) => log.status != UploadStatus.inProgress).length;
  }

  // Get uploads count from today
  int getUploadsFromTodayCount() {
    return getLogsFromToday()
        .where((log) => log.status != UploadStatus.inProgress)
        .length;
  }

  // Clear all logs
  Future<void> clearAllLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  // Export logs to JSON string
  String exportLogsToJson() {
    final logsData = _logs.map((log) => log.toJson()).toList();
    return json.encode(logsData);
  }

  // Search logs by file name
  List<UploadLog> searchLogs(String query) {
    if (query.isEmpty) return logs;

    final lowerQuery = query.toLowerCase();
    return _logs.where((log) {
      return log.fileName.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
