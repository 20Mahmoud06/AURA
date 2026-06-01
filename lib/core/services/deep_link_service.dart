import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_routes.dart';
import '../routing/global_navigator.dart';
import 'audio_player_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void init() {
    _sub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'music-player' || uri.path == '/music-player') {
      final audioService = AudioPlayerService();
      if (audioService.currentMusic != null) {
        final ctx = rootContext;
        if (ctx != null) {
          ctx.push(AppRoutes.musicPlayer);
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
