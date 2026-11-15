import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/app_update_info.dart';
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
  List<AssetEntity> _allVideos = [];
  List<AssetEntity> _filteredVideos = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadVideos();
    _searchController.addListener(_onSearchChanged);
    // Automatically check for OTA in-app updates in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesInBackground();
    });
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
          final title = (video.title ?? '').toLowerCase();
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
              Text("GS Video Player is already on the latest version!"),
            ],
          ),
          backgroundColor: const Color(0xFF1E2235),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _checkPermissionAndLoadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request media / storage permissions
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

      // Filter options: Sort newest to oldest by creation date
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
            asc: false, // Newest first
          ),
        );

      // Fetch all video albums/paths
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: filterOption,
      );

      List<AssetEntity> videos = [];
      if (paths.isNotEmpty) {
        final AssetPathEntity allVideosPath = paths.first;
        final int totalCount = await allVideosPath.assetCountAsync;
        
        if (totalCount > 0) {
          videos = await allVideosPath.getAssetListRange(
            start: 0,
            end: totalCount,
          );
        }
      }

      setState(() {
        _allVideos = videos;
        _filteredVideos = _searchQuery.isEmpty
            ? List.from(videos)
            : videos.where((v) => (v.title ?? '').toLowerCase().contains(_searchQuery)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading videos: $e");
      setState(() {
        _isLoading = false;
      });
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
            const Text(
              "GS Video Player",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Check for updates",
            icon: const Icon(Icons.system_update_rounded, color: Color(0xFF00ADB5)),
            onPressed: () => _checkForUpdatesInBackground(showFeedbackIfLatest: true),
          ),
          IconButton(
            tooltip: "Refresh videos",
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _checkPermissionAndLoadVideos,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF00ADB5),
            ),
            SizedBox(height: 16),
            Text(
              "Scanning device videos...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return PermissionDeniedView(
        onRetry: _checkPermissionAndLoadVideos,
      );
    }

    return Column(
      children: [
        // Search Bar with Video Count
        _buildSearchBar(),

        // Video Grid View
        Expanded(
          child: _filteredVideos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFF00ADB5),
                  backgroundColor: const Color(0xFF1E2235),
                  onRefresh: _checkPermissionAndLoadVideos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = _filteredVideos[index];
                      return VideoThumbnailCard(
                        entity: video,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(entity: video),
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
          hintText: "Search in ${_allVideos.length} videos...",
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.video_library_outlined,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "No videos matching '$_searchQuery'"
                : "No videos found on device",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? "Try searching with a different video name."
                : "Add some videos to your phone storage and pull to refresh.",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
