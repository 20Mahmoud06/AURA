import 'package:just_audio_background/just_audio_background.dart';
import 'core/imports/core_imports.dart';
import 'core/imports/packages_imports.dart';
import 'core/services/deep_link_service.dart';
import 'app.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  );

  await dotenv.load(fileName: '.env');

  await AppConfig.init();

  DeepLinkService().init();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: true,
  );

  runApp(
    App(),
  );

  FlutterNativeSplash.remove();
}