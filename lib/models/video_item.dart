import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

class VideoItem {
  final String id;
  final String title;
  final String path;
  final int durationSeconds;
  final int sizeBytes;
  final DateTime? modifiedTime;
  final AssetEntity? assetEntity; // Present on Android/mobile
  final File? file; // Present on Windows/desktop

  VideoItem({
    required this.id,
    required this.title,
    required this.path,
    this.durationSeconds = 0,
    this.sizeBytes = 0,
    this.modifiedTime,
    this.assetEntity,
    this.file,
  });

  bool get isMobileAsset => assetEntity != null;

  String get fileExtension {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < path.length - 1) {
      return path.substring(dotIndex + 1).toUpperCase();
    }
    return 'VIDEO';
  }

  String get formattedSize {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024 * 1024) {
      return "${(sizeBytes / 1024).toStringAsFixed(1)} KB";
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return "${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
    return "${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  Future<File?> getResolvedFile() async {
    if (file != null) return file;
    if (assetEntity != null) {
      return await assetEntity!.file;
    }
    final f = File(path);
    if (await f.exists()) return f;
    return null;
  }

  factory VideoItem.fromAsset(AssetEntity asset) {
    return VideoItem(
      id: asset.id,
      title: asset.title ?? 'Untitled Video',
      path: asset.relativePath ?? '',
      durationSeconds: asset.duration,
      sizeBytes: 0,
      modifiedTime: asset.createDateTime,
      assetEntity: asset,
    );
  }

  factory VideoItem.fromFile(File file, {int? durationSeconds}) {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : file.path.split(Platform.isWindows ? r'\' : '/').last;

    int size = 0;
    DateTime? modified;
    try {
      final stat = file.statSync();
      size = stat.size;
      modified = stat.modified;
    } catch (_) {}

    return VideoItem(
      id: file.path,
      title: fileName,
      path: file.path,
      durationSeconds: durationSeconds ?? 0,
      sizeBytes: size,
      modifiedTime: modified,
      file: file,
    );
  }
}
