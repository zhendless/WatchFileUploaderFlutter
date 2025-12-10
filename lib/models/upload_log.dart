import 'package:intl/intl.dart';

enum UploadStatus { inProgress, success, failure }

class UploadLog {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime timestamp;
  final UploadStatus status;
  final String? errorMessage;
  final int fileSizeBytes;

  UploadLog({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    required this.fileSizeBytes,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  // Create from JSON
  factory UploadLog.fromJson(Map<String, dynamic> json) {
    return UploadLog(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: UploadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UploadStatus.failure,
      ),
      errorMessage: json['errorMessage'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int,
    );
  }

  // Get formatted timestamp
  String get formattedTimestamp {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }

  // Get relative time (e.g., "2 minutes ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return formattedTimestamp;
    }
  }

  // Get formatted file size
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // Copy with method for updating status
  UploadLog copyWith({
    String? id,
    String? fileName,
    String? filePath,
    DateTime? timestamp,
    UploadStatus? status,
    String? errorMessage,
    int? fileSizeBytes,
  }) {
    return UploadLog(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}
