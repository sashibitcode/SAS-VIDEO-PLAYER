import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/video_item.dart';
import '../utils/duration_formatter.dart';

class PlayerScreen extends StatefulWidget {
  final VideoItem video;

  const PlayerScreen({
    super.key,
    required this.video,
  });

  /// Convenience constructor for mobile AssetEntity
  factory PlayerScreen.fromEntity(AssetEntity entity) {
    return PlayerScreen(video: VideoItem.fromAsset(entity));
  }

  /// Convenience constructor for raw File
  factory PlayerScreen.fromFile(File file, {String? title}) {
    return PlayerScreen(video: VideoItem.fromFile(file));
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  File? _videoFile;

  // On-screen shortcut feedback overlay
  String? _feedbackText;
  IconData? _feedbackIcon;
  Timer? _feedbackTimer;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _showFeedback(String text, IconData icon) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackText = text;
      _feedbackIcon = icon;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _feedbackText = null;
          _feedbackIcon = null;
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      final File? file = await widget.video.getResolvedFile();
      if (file == null || !await file.exists()) {
        setState(() {
          _errorMessage = "Unable to load video file: ${widget.video.path}";
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
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
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

      // Request keyboard focus for desktop shortcuts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _keyboardFocusNode.requestFocus();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load video: $e";
        _isLoading = false;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _videoPlayerController == null) return;

    final controller = _videoPlayerController!;
    final pos = controller.value.position;
    final dur = controller.value.duration;

    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.keyK) {
      if (controller.value.isPlaying) {
        controller.pause();
        _showFeedback("Paused", Icons.pause_rounded);
      } else {
        controller.play();
        _showFeedback("Playing", Icons.play_arrow_rounded);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyL) {
      final newPos = pos + const Duration(seconds: 10);
      controller.seekTo(newPos < dur ? newPos : dur);
      _showFeedback("+10s", Icons.fast_forward_rounded);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyJ) {
      final newPos = pos - const Duration(seconds: 10);
      controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
      _showFeedback("-10s", Icons.fast_rewind_rounded);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final newVol = (controller.value.volume + 0.1).clamp(0.0, 1.0);
      controller.setVolume(newVol);
      _showFeedback("Volume ${(newVol * 100).round()}%", Icons.volume_up_rounded);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final newVol = (controller.value.volume - 0.1).clamp(0.0, 1.0);
      controller.setVolume(newVol);
      _showFeedback("Volume ${(newVol * 100).round()}%", Icons.volume_down_rounded);
    } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
      if (controller.value.volume > 0) {
        controller.setVolume(0.0);
        _showFeedback("Muted", Icons.volume_off_rounded);
      } else {
        controller.setVolume(1.0);
        _showFeedback("Unmuted", Icons.volume_up_rounded);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _chewieController?.toggleFullScreen();
      _showFeedback("Fullscreen", Icons.fullscreen_rounded);
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _keyboardFocusNode.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    // Restore default orientation behavior
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.video.title;
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
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
          actions: [
            if (isDesktop)
              IconButton(
                tooltip: "Keyboard Shortcuts (Space, Arrows, F, M)",
                icon: const Icon(Icons.keyboard_outlined, color: Color(0xFF00ADB5)),
                onPressed: _showShortcutsDialog,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Player Area with Feedback HUD
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: isDesktop ? 420 : 250,
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
                  // Shortcut HUD Indicator
                  if (_feedbackText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00ADB5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_feedbackIcon, color: const Color(0xFF00ADB5), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _feedbackText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Video Details Section
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ADB5).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00ADB5)),
                          ),
                          child: Text(
                            widget.video.fileExtension,
                            style: const TextStyle(
                              color: Color(0xFF00ADB5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Movie Information",
                            style: TextStyle(
                              color: Color(0xFF00ADB5),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 20),
                          if (_videoPlayerController != null &&
                              _videoPlayerController!.value.isInitialized) ...[
                            _buildInfoRow(
                              icon: Icons.timer_outlined,
                              label: "Duration",
                              value: DurationFormatter.format(
                                _videoPlayerController!.value.duration.inSeconds,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              icon: Icons.aspect_ratio_rounded,
                              label: "Resolution",
                              value:
                                  "${_videoPlayerController!.value.size.width.toInt()} x ${_videoPlayerController!.value.size.height.toInt()}",
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (widget.video.formattedSize.isNotEmpty) ...[
                            _buildInfoRow(
                              icon: Icons.storage_rounded,
                              label: "File Size",
                              value: widget.video.formattedSize,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_videoFile != null) ...[
                            _buildInfoRow(
                              icon: Icons.folder_open_rounded,
                              label: "File Path",
                              value: _videoFile!.path,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161926),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded,
                                color: Color(0xFF00ADB5), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Laptop Tip: Press 'F' for Fullscreen, 'Space' to Play/Pause, and Arrow Keys to Seek & Change Volume.",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Row(
          children: [
            Icon(Icons.keyboard_outlined, color: Color(0xFF00ADB5)),
            SizedBox(width: 8),
            Text("Laptop Keyboard Shortcuts", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShortcutRow(keyLabel: "Space / K", action: "Play / Pause"),
            _ShortcutRow(keyLabel: "Right Arrow / L", action: "Forward 10 Seconds"),
            _ShortcutRow(keyLabel: "Left Arrow / J", action: "Rewind 10 Seconds"),
            _ShortcutRow(keyLabel: "Up / Down Arrow", action: "Volume Up / Down"),
            _ShortcutRow(keyLabel: "F", action: "Toggle Fullscreen"),
            _ShortcutRow(keyLabel: "M", action: "Mute / Unmute"),
            _ShortcutRow(keyLabel: "Esc", action: "Exit Fullscreen"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got It", style: TextStyle(color: Color(0xFF00ADB5))),
          ),
        ],
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

class _ShortcutRow extends StatelessWidget {
  final String keyLabel;
  final String action;

  const _ShortcutRow({required this.keyLabel, required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              keyLabel,
              style: const TextStyle(
                color: Color(0xFF00ADB5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            action,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
