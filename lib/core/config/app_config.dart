import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import '../services/database_service.dart';
import '../services/media_scanner_service.dart';
import '../services/settings_service.dart';
import '../services/picture_in_picture_service.dart';

class AppConfig {
  AppConfig._();

  static late final DatabaseService databaseService;
  static late final MediaScannerService mediaScannerService;

  static String get baseUrl => _getBaseUrl();

  static Future<void> init() async {
    // MediaKit Init
    MediaKit.ensureInitialized();

    // Init Services
    databaseService = DatabaseService();
    await databaseService.init();

    mediaScannerService = MediaScannerService();

    await SettingsService.instance.init();

    PictureInPictureService.instance.init();
  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL', fallback: 'https://api.example.com');
  }
}

