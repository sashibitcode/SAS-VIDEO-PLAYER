class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String downloadUrl;
  final String releaseNotes;
  final String? fileSize;
  final bool isForceUpdate;

  AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    required this.releaseNotes,
    this.fileSize,
    this.isForceUpdate = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      versionCode: json['version_code'] as int? ?? 1,
      versionName: json['version_name'] as String? ?? '1.0.0',
      downloadUrl: (json['download_url'] ?? json['download_url_android'] ?? '') as String,
      releaseNotes: json['release_notes'] as String? ?? 'Performance improvements and bug fixes.',
      fileSize: json['file_size'] as String?,
      isForceUpdate: json['is_force_update'] as bool? ?? false,
    );
  }
}
