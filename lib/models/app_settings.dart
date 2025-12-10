class AppSettings {
  final String? monitoredFolderPath;
  final String? uploadUrl;
  final bool autoStartMonitoring;

  AppSettings({
    this.monitoredFolderPath,
    this.uploadUrl,
    this.autoStartMonitoring = false,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'monitoredFolderPath': monitoredFolderPath,
      'uploadUrl': uploadUrl,
      'autoStartMonitoring': autoStartMonitoring,
    };
  }

  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      monitoredFolderPath: json['monitoredFolderPath'] as String?,
      uploadUrl: json['uploadUrl'] as String?,
      autoStartMonitoring: json['autoStartMonitoring'] as bool? ?? false,
    );
  }

  // Validate settings
  bool get isValid {
    return monitoredFolderPath != null &&
        monitoredFolderPath!.isNotEmpty &&
        uploadUrl != null &&
        uploadUrl!.isNotEmpty &&
        _isValidUrl(uploadUrl!);
  }

  // Check if URL is valid
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Copy with method for updating settings
  AppSettings copyWith({
    String? monitoredFolderPath,
    String? uploadUrl,
    bool? autoStartMonitoring,
  }) {
    return AppSettings(
      monitoredFolderPath: monitoredFolderPath ?? this.monitoredFolderPath,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      autoStartMonitoring: autoStartMonitoring ?? this.autoStartMonitoring,
    );
  }

  // Create empty settings
  factory AppSettings.empty() {
    return AppSettings();
  }
}
