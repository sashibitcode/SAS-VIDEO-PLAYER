import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/video_item.dart';
import '../utils/duration_formatter.dart';

class VideoThumbnailCard extends StatelessWidget {
  final VideoItem item;
  final VoidCallback onTap;

  const VideoThumbnailCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDuration = item.durationSeconds > 0
        ? DurationFormatter.format(item.durationSeconds)
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Poster area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVisualHeader(),
                  // Format Badge (e.g. MKV, MP4)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00ADB5).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item.fileExtension,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Duration or Size Badge
                  if (formattedDuration.isNotEmpty || item.formattedSize.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          formattedDuration.isNotEmpty ? formattedDuration : item.formattedSize,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title & Meta Info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.movie_rounded,
                        size: 13,
                        color: Color(0xFF00ADB5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.formattedSize.isNotEmpty
                              ? item.formattedSize
                              : "Local Video",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: Color(0xFF00ADB5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHeader() {
    // If mobile asset with thumbnail
    if (item.isMobileAsset && item.assetEntity != null) {
      return FutureBuilder<Uint8List?>(
        future: item.assetEntity!.thumbnailDataWithSize(const ThumbnailSize(360, 360)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            );
          }
          return _buildDefaultPlaceholder();
        },
      );
    }

    // Desktop movie placeholder with movie poster style
    return _buildDefaultPlaceholder();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1F33),
            Color(0xFF101320),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00ADB5).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00ADB5).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Color(0xFF00ADB5),
            size: 32,
          ),
        ),
      ),
    );
  }
}
