import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/services/settings_service.dart';
import 'package:aura/features/settings/presentation/widgets/widgets.dart';
import 'package:aura/shared/widgets/aura_screen_background.dart';
import 'package:aura/shared/widgets/custom_text.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsService.instance;

  late bool _pictureInPicture;
  late bool _subtitlesByDefault;
  late bool _gestureControls;
  late bool _doubleTapSeek;
  late int _doubleTapSeconds;
  late bool _longPressSpeed;
  late bool _rememberPlaybackSpeed;

  late bool _autoScanMusic;
  late bool _scanOnLaunch;
  late bool _normalizeVolume;

  late bool _gaplessPlayback;
  late bool _rememberPlaybackPosition;
  late bool _lockScreenControls;

  @override
  void initState() {
    super.initState();
    _pictureInPicture = _settings.pictureInPicture;
    _subtitlesByDefault = _settings.subtitlesByDefault;
    _gestureControls = _settings.gestureControls;
    _doubleTapSeek = _settings.doubleTapSeek;
    _doubleTapSeconds = _settings.doubleTapSeconds;
    _longPressSpeed = _settings.longPressSpeed;
    _rememberPlaybackSpeed = _settings.rememberPlaybackSpeed;
    _autoScanMusic = _settings.autoScanMusic;
    _scanOnLaunch = _settings.scanOnLaunch;
    _normalizeVolume = _settings.normalizeVolume;
    _gaplessPlayback = _settings.gaplessPlayback;
    _rememberPlaybackPosition = _settings.rememberPlaybackPosition;
    _lockScreenControls = _settings.lockScreenControls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.neutral,
      body: Stack(
        children: [
          const Positioned.fill(child: AuraScreenBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520.w),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            const SettingsTopBar(),
                            SizedBox(height: 26.h),
                            const SettingsTitle(),
                            SizedBox(height: 18.h),
                            SettingsCard(
                              children: [
                                const SettingsSectionHeader(
                                  icon: Icons.play_circle_outline_rounded,
                                  title: 'Video Playback',
                                  subtitle: 'Media handling and viewing preferences',
                                ),
                                SettingsSwitchTile(
                                  title: 'Picture-in-Picture',
                                  subtitle: 'Continue playing when app is minimized',
                                  value: _pictureInPicture,
                                  onChanged: (value) => setState(() {
                                    _pictureInPicture = value;
                                    _settings.setPictureInPicture(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Subtitles by Default',
                                  subtitle: 'Always show subtitles if available',
                                  value: _subtitlesByDefault,
                                  onChanged: (value) => setState(() {
                                    _subtitlesByDefault = value;
                                    _settings.setSubtitlesByDefault(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Remember Playback Speed',
                                  subtitle: 'Keep your latest video speed',
                                  value: _rememberPlaybackSpeed,
                                  onChanged: (value) => setState(() {
                                    _rememberPlaybackSpeed = value;
                                    _settings.setRememberPlaybackSpeed(value);
                                  }),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SettingsCard(
                              children: [
                                const SettingsSectionHeader(
                                  icon: Icons.touch_app_rounded,
                                  title: 'Video Gestures',
                                  subtitle: 'Touch shortcuts for watching videos',
                                ),
                                SettingsSwitchTile(
                                  title: 'Gesture Controls',
                                  subtitle: 'Swipe for volume and brightness',
                                  value: _gestureControls,
                                  onChanged: (value) => setState(() {
                                    _gestureControls = value;
                                    _settings.setGestureControls(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Double Tap Seek',
                                  subtitle: 'Jump forward or backward while watching',
                                  value: _doubleTapSeek,
                                  onChanged: (value) => setState(() {
                                    _doubleTapSeek = value;
                                    _settings.setDoubleTapSeek(value);
                                  }),
                                ),
                                SizedBox(height: 14.h),
                                DoubleTapSecondsPicker(
                                  selectedSeconds: _doubleTapSeconds,
                                  onChanged: (seconds) => setState(() {
                                    _doubleTapSeconds = seconds;
                                    _settings.setDoubleTapSeconds(seconds);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Long Press Speed',
                                  subtitle: 'Hold the video to play at 2x speed',
                                  value: _longPressSpeed,
                                  onChanged: (value) => setState(() {
                                    _longPressSpeed = value;
                                    _settings.setLongPressSpeed(value);
                                  }),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SettingsCard(
                              children: [
                                const SettingsSectionHeader(
                                  icon: Icons.library_music_rounded,
                                  title: 'Music Library',
                                  subtitle: 'Scanning and background audio behavior',
                                ),
                                SettingsSwitchTile(
                                  title: 'Auto Scan Music',
                                  subtitle: 'Find new audio files automatically',
                                  value: _autoScanMusic,
                                  onChanged: (value) => setState(() {
                                    _autoScanMusic = value;
                                    _settings.setAutoScanMusic(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Scan on Launch',
                                  subtitle: 'Refresh the library when Aura opens',
                                  value: _scanOnLaunch,
                                  onChanged: (value) => setState(() {
                                    _scanOnLaunch = value;
                                    _settings.setScanOnLaunch(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Normalize Volume',
                                  subtitle: 'Balance quiet and loud tracks',
                                  value: _normalizeVolume,
                                  onChanged: (value) => setState(() {
                                    _normalizeVolume = value;
                                    _settings.setNormalizeVolume(value);
                                  }),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SettingsCard(
                              children: [
                                const SettingsSectionHeader(
                                  icon: Icons.wifi_tethering_rounded,
                                  title: 'Music Playback',
                                  subtitle: 'Playback quality and track navigation',
                                ),
                                SettingsSwitchTile(
                                  title: 'Gapless Playback',
                                  subtitle: 'Seamless transitions between tracks',
                                  value: _gaplessPlayback,
                                  onChanged: (value) => setState(() {
                                    _gaplessPlayback = value;
                                    _settings.setGaplessPlayback(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Remember Playback Position',
                                  subtitle: 'Resume each track where you left off',
                                  value: _rememberPlaybackPosition,
                                  onChanged: (value) => setState(() {
                                    _rememberPlaybackPosition = value;
                                    _settings.setRememberPlaybackPosition(value);
                                  }),
                                ),
                                SettingsSwitchTile(
                                  title: 'Lock Screen Controls',
                                  subtitle: 'Show playback controls on the lock screen',
                                  value: _lockScreenControls,
                                  onChanged: (value) => setState(() {
                                    _lockScreenControls = value;
                                    _settings.setLockScreenControls(value);
                                  }),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Center(
                              child: CustomText(
                                text: 'AURA CINEMATIC MEDIA PLAYER',
                                textColor: AuraColors.muted.withValues(alpha: 0.55),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


