import 'package:go_router/go_router.dart';
import 'package:aura/core/routing/global_navigator.dart';
import 'package:aura/core/routing/app_routes.dart';
import 'package:aura/features/home/presentation/screens/home_page.dart';
import 'package:aura/features/music/presentation/screens/music_home_page.dart';
import 'package:aura/features/settings/presentation/screens/settings_page.dart';
import 'package:aura/features/splash/presentation/screens/splash_screen.dart';
import 'package:aura/features/video/presentation/screens/video_player_screen.dart';
import 'package:aura/features/music/presentation/screens/music_player_screen.dart';
import 'package:aura/features/playlists/presentation/screens/music_playlists_page.dart';
import 'package:aura/features/playlists/presentation/screens/video_playlists_page.dart';
import 'package:aura/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:aura/database/models/video_item.dart';
import 'package:aura/database/models/music_item.dart';


final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.music,
      name: 'music',
      builder: (context, state) => const MusicHomePage(),
    ),
    GoRoute(
      path: AppRoutes.musicPlaylists,
      name: 'music-playlists',
      builder: (context, state) => const MusicPlaylistsPage(),
    ),
    GoRoute(
      path: AppRoutes.videoPlaylists,
      name: 'video-playlists',
      builder: (context, state) => const VideoPlaylistsPage(),
    ),
    GoRoute(
      path: AppRoutes.playlistDetail,
      name: 'playlist-detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra as Map<String, String>?;
        final title = extra?['title'] ?? 'Playlist';
        final type = extra?['type'] ?? 'music';
        return PlaylistDetailScreen(
          playlistId: id,
          playlistTitle: title,
          type: type,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.videoPlayer,
      name: 'video-player',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          final path = extra['path'] as String? ?? '';
          final items = (extra['items'] as List<dynamic>?)?.cast<VideoItem>() ?? <VideoItem>[];
          final index = extra['index'] as int? ?? 0;
          return VideoPlayerScreen(
            videoPath: path,
            videoItems: items,
            initialIndex: index,
          );
        }
        final videoPath = extra as String? ?? '';
        return VideoPlayerScreen(videoPath: videoPath);
      },
    ),
    GoRoute(
      path: AppRoutes.musicPlayer,
      name: 'music-player',
      builder: (context, state) => MusicPlayerScreen(
        initialTrack: state.extra as MusicItem?,
      ),
    ),
  ],
);
