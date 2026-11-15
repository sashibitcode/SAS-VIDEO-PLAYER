import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/video_item.dart';

class DesktopScannerService {
  static const List<String> videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'webm',
    'flv',
    'm4v',
    'ts',
    '3gp',
  ];

  /// Scan standard Windows folders (Videos, Downloads) for movie files
  static Future<List<VideoItem>> scanDefaultDirectories() async {
    final List<VideoItem> foundVideos = [];
    final Set<String> scannedPaths = {};

    final List<Directory> candidateDirs = [];

    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    if (userProfile.isNotEmpty) {
      final videosDir = Directory('$userProfile\\Videos');
      final downloadsDir = Directory('$userProfile\\Downloads');

      if (videosDir.existsSync()) candidateDirs.add(videosDir);
      if (downloadsDir.existsSync()) candidateDirs.add(downloadsDir);
    }

    for (final dir in candidateDirs) {
      try {
        final List<FileSystemEntity> entities = dir.listSync(
          recursive: true,
          followLinks: false,
        );

        for (final entity in entities) {
          if (entity is File) {
            final ext = entity.path.split('.').last.toLowerCase();
            if (videoExtensions.contains(ext) && !scannedPaths.contains(entity.path)) {
              scannedPaths.add(entity.path);
              foundVideos.add(VideoItem.fromFile(entity));
            }
          }
        }
      } catch (e) {
        debugPrint("Error scanning directory ${dir.path}: $e");
      }
    }

    // Sort newest modified first
    foundVideos.sort((a, b) {
      final aDate = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return foundVideos;
  }

  /// Let user choose any movie file directly from anywhere on their laptop
  static Future<List<VideoItem>> pickMovieFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Movies or Videos to Play',
        type: FileType.custom,
        allowedExtensions: videoExtensions,
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        final List<VideoItem> items = [];
        for (final path in result.paths) {
          if (path != null) {
            final file = File(path);
            if (await file.exists()) {
              items.add(VideoItem.fromFile(file));
            }
          }
        }
        return items;
      }
    } catch (e) {
      debugPrint("Error picking movie file: $e");
    }
    return [];
  }

  /// Let user choose a movie folder (e.g. D:\Movies) to scan
  static Future<List<VideoItem>> pickAndScanMovieFolder() async {
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Movie Folder to Scan',
      );

      if (selectedPath != null) {
        final dir = Directory(selectedPath);
        if (await dir.exists()) {
          final List<VideoItem> items = [];
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              final ext = entity.path.split('.').last.toLowerCase();
              if (videoExtensions.contains(ext)) {
                items.add(VideoItem.fromFile(entity));
              }
            }
          }

          items.sort((a, b) {
            final aDate = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          return items;
        }
      }
    } catch (e) {
      debugPrint("Error picking folder: $e");
    }
    return [];
  }
}
