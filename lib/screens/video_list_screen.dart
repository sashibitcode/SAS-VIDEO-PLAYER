import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/app_update_info.dart';
import '../models/video_item.dart';
import '../services/desktop_scanner_service.dart';
import '../services/update_service.dart';
import '../widgets/permission_denied_view.dart';
import '../widgets/update_dialog.dart';
import '../widgets/video_thumbnail_card.dart';
import 'player_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  bool _isLoading = true;
  bool _hasPermission = false;
  List<VideoItem> _allVideos = [];
  List<VideoItem> _filteredVideos = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _searchController.addListener(_onSearchChanged);

    // Automatically check for OTA in-app updates in background on mobile
    if (!_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdatesInBackground();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVideos = List.from(_allVideos);
      } else {
        _filteredVideos = _allVideos.where((video) {
          final title = video.title.toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _checkForUpdatesInBackground({bool showFeedbackIfLatest = false}) async {
    final AppUpdateInfo? updateInfo = await UpdateService.checkForUpdate();
    if (!mounted) return;

    if (updateInfo != null) {
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.isForceUpdate,
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    } else if (showFeedbackIfLatest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF00ADB5), size: 18),
              SizedBox(width: 8),
              Text("SAS Video Player is up to date!"),
            ],
          ),
          backgroundColor: const Color(0xFF1E2235),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    if (_isDesktop) {
      // Desktop / Laptop scan (Windows/Mac/Linux)
      try {
        final videos = await DesktopScannerService.scanDefaultDirectories();
        setState(() {
          _hasPermission = true;
          _allVideos = videos;
          _filteredVideos = _searchQuery.isEmpty
              ? List.from(videos)
              : videos.where((v) => v.title.toLowerCase().contains(_searchQuery)).toList();
          _isLoading = false;
        });
      } catch (e) {
        debugPrint("Desktop scan error: $e");
        setState(() {
          _hasPermission = true;
          _isLoading = false;
        });
      }
    } else {
      // Mobile scan (Android / iOS)
      try {
        final PermissionState permission = await PhotoManager.requestPermissionExtend();
        if (!permission.isAuth) {
          setState(() {
            _hasPermission = false;
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _hasPermission = true;
        });

        final FilterOptionGroup filterOption = FilterOptionGroup()
          ..setOption(
            AssetType.video,
            const FilterOption(
              needTitle: true,
              sizeConstraint: SizeConstraint(ignoreSize: true),
            ),
          )
          ..addOrderOption(
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          );

        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.video,
          filterOption: filterOption,
        );

        List<VideoItem> videoItems = [];
        if (paths.isNotEmpty) {
          final AssetPathEntity allVideosPath = paths.first;
          final int totalCount = await allVideosPath.assetCountAsync;

          if (totalCount > 0) {
            final assets = await allVideosPath.getAssetListRange(
              start: 0,
              end: totalCount,
            );
            videoItems = assets.map((a) => VideoItem.fromAsset(a)).toList();
          }
        }

        setState(() {
          _allVideos = videoItems;
          _filteredVideos = _searchQuery.isEmpty
              ? List.from(videoItems)
              : videoItems.where((v) => v.title.toLowerCase().contains(_searchQuery)).toList();
          _isLoading = false;
        });
      } catch (e) {
        debugPrint("Error loading mobile videos: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Pick individual movie files on laptop
  Future<void> _pickMovieFiles() async {
    final picked = await DesktopScannerService.pickMovieFiles();
    if (picked.isNotEmpty) {
      setState(() {
        for (final item in picked) {
          if (!_allVideos.any((v) => v.path == item.path)) {
            _allVideos.insert(0, item);
          }
        }
        _onSearchChanged();
      });

      // Directly play the first picked movie
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(video: picked.first),
          ),
        );
      }
    }
  }

  // Scan an entire movie folder on laptop
  Future<void> _pickMovieFolder() async {
    setState(() => _isLoading = true);
    final scanned = await DesktopScannerService.pickAndScanMovieFolder();
    setState(() {
      for (final item in scanned) {
        if (!_allVideos.any((v) => v.path == item.path)) {
          _allVideos.add(item);
        }
      }
      _onSearchChanged();
      _isLoading = false;
    });

    if (mounted && scanned.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added ${scanned.length} movies to library"),
          backgroundColor: const Color(0xFF1E2235),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141724),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00ADB5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF00ADB5),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SAS Video Player",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  _isDesktop ? "Laptop Movie Edition" : "Mobile Edition",
                  style: const TextStyle(
                    color: Color(0xFF00ADB5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isDesktop) ...[
            TextButton.icon(
              onPressed: _pickMovieFiles,
              icon: const Icon(Icons.file_open_rounded, color: Color(0xFF00ADB5), size: 18),
              label: const Text(
                "Open Movie",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1E2235),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _pickMovieFolder,
              icon: const Icon(Icons.folder_special_rounded, color: Color(0xFF6366F1), size: 18),
              label: const Text(
                "Add Folder",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1E2235),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            IconButton(
              tooltip: "Check for updates",
              icon: const Icon(Icons.system_update_rounded, color: Color(0xFF00ADB5)),
              onPressed: () => _checkForUpdatesInBackground(showFeedbackIfLatest: true),
            ),
          ],
          IconButton(
            tooltip: "Refresh videos",
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadVideos,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF00ADB5),
            ),
            const SizedBox(height: 16),
            Text(
              _isDesktop
                  ? "Scanning movies in Videos & Downloads..."
                  : "Scanning phone video library...",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasPermission && !_isDesktop) {
      return PermissionDeniedView(
        onRetry: _loadVideos,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width >= 1200) {
          crossAxisCount = 5;
        } else if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        }

        return Column(
          children: [
            // Search Bar & Desktop Quick Bar
            _buildSearchBar(),

            // Video Grid View
            Expanded(
              child: _filteredVideos.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF00ADB5),
                      backgroundColor: const Color(0xFF1E2235),
                      onRefresh: _loadVideos,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: _isDesktop ? 0.95 : 0.85,
                        ),
                        itemCount: _filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = _filteredVideos[index];
                          return VideoThumbnailCard(
                            item: video,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(video: video),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161926),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: _isDesktop
              ? "Search across ${_allVideos.length} movies (MP4, MKV, AVI, 4K)..."
              : "Search in ${_allVideos.length} videos...",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF00ADB5),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.movie_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? "No movies matching '$_searchQuery'"
                  : "No movies found in standard folders",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isDesktop
                  ? "Click 'Open Movie' to choose any movie file, or 'Add Folder' to scan your movies collection."
                  : "Add some videos to your phone storage and pull to refresh.",
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isDesktop) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickMovieFiles,
                icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                label: const Text(
                  "Browse Movies File (.mp4, .mkv, .avi)",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ADB5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
