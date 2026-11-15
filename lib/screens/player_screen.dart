import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/duration_formatter.dart';

class PlayerScreen extends StatefulWidget {
  final AssetEntity entity;

  const PlayerScreen({
    super.key,
    required this.entity,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  File? _videoFile;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final File? file = await widget.entity.file;
      if (file == null || !await file.exists()) {
        setState(() {
          _errorMessage = "Unable to load video file from storage.";
          _isLoading = false;
        });
        return;
      }

      _videoFile = file;
      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        
        playbackSpeeds: const [0.5, 1.0, 1.5, 2.0],
        allowFullScreen: true,
        fullScreenByDefault: false,
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00ADB5),
          handleColor: const Color(0xFF00ADB5),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00ADB5),
          handleColor: const Color(0xFF00ADB5),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00ADB5),
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Playback Error: $errorMessage",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load video: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    // Restore default orientation behavior
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = (widget.entity.title != null && widget.entity.title!.isNotEmpty)
        ? widget.entity.title!
        : 'Video Player';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141724),
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Container
            Container(
              color: Colors.black,
              width: double.infinity,
              height: 250,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00ADB5),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 44,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : (_chewieController != null &&
                              _chewieController!
                                  .videoPlayerController.value.isInitialized)
                          ? Chewie(controller: _chewieController!)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00ADB5),
                              ),
                            ),
            ),
            // Video Details Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Video Details",
                          style: TextStyle(
                            color: Color(0xFF00ADB5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        _buildInfoRow(
                          icon: Icons.timer_outlined,
                          label: "Duration",
                          value: DurationFormatter.format(widget.entity.duration),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.aspect_ratio_rounded,
                          label: "Resolution",
                          value: "${widget.entity.width} x ${widget.entity.height}",
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: "Created",
                          value: widget.entity.createDateTime.toString().split('.')[0],
                        ),
                        if (_videoFile != null) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            icon: Icons.folder_open_rounded,
                            label: "Path",
                            value: _videoFile!.path,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
