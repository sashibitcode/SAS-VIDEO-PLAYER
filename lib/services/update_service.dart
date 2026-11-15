import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_update_info.dart';

class UpdateService {
  // Current app version constants
  static const int currentVersionCode = 1;
  static const String currentVersionName = "1.0.0";

  // Website or GitHub raw URL for version.json
  // When you deploy your website or push to GitHub, update this endpoint if needed
  static const String defaultUpdateUrl = 
      "https://raw.githubusercontent.com/harsh/gs-video-player/main/version.json";

  /// Checks if a newer version is available
  static Future<AppUpdateInfo?> checkForUpdate({String? customUrl}) async {
    try {
      final String url = customUrl ?? defaultUpdateUrl;
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final AppUpdateInfo updateInfo = AppUpdateInfo.fromJson(data);

        if (updateInfo.versionCode > currentVersionCode) {
          return updateInfo;
        }
      }
    } catch (_) {
      // Offline or network timeout - fail silently
    }
    return null;
  }

  /// Downloads the APK and triggers the Android system package installer
  static Future<void> downloadAndInstall({
    required String downloadUrl,
    required Function(double progress, String progressText) onProgress,
    required Function(String error) onError,
  }) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String apkPath = "${tempDir.path}/update.apk";

      final File existingFile = File(apkPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      final Dio dio = Dio();
      await dio.download(
        downloadUrl,
        apkPath,
        onReceiveProgress: (int received, int total) {
          if (total > 0) {
            final double progress = received / total;
            final String text =
                "${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB";
            onProgress(progress, text);
          }
        },
      );

      // Verify downloaded file
      final File downloadedFile = File(apkPath);
      if (await downloadedFile.exists()) {
        final OpenResult result = await OpenFilex.open(
          apkPath,
          type: "application/vnd.android.package-archive",
        );
        if (result.type != ResultType.done) {
          onError("Could not open package installer: ${result.message}");
        }
      } else {
        onError("Downloaded APK file was not found on device.");
      }
    } catch (e) {
      onError("Download failed: $e");
    }
  }
}
