import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const PermissionDeniedView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.video_collection_outlined,
                size: 64,
                color: Color(0xFF00ADB5),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Permission Required",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "SAS Video Player needs access to your media files to discover and play all the videos stored on your device.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                // Request permission again or open system settings if permanently denied
                final PermissionState state = await PhotoManager.requestPermissionExtend();
                if (state.isAuth) {
                  onRetry();
                } else {
                  await PhotoManager.openSetting();
                }
              },
              icon: const Icon(Icons.settings_suggest_rounded, color: Colors.black),
              label: const Text(
                "Allow Access / Open Settings",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ADB5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                "I've allowed it, check again",
                style: TextStyle(
                  color: Color(0xFF00ADB5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
