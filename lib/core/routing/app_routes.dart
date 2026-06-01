/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String music = '/music';
  static const String musicPlayer = '/music-player';
  static const String settings = '/settings';
  static const String videoPlayer = '/video-player';
  static const String musicPlaylists = '/music-playlists';
  static const String videoPlaylists = '/video-playlists';
  static const String playlistDetail = '/playlist-detail/:id';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
}
