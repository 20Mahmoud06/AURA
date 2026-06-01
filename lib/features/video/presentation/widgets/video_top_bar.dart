import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';

class VideoTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onToggleRate;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleRotation;
  final VoidCallback? onPictureInPicture;
  final VoidCallback? onToggleLock;
  final bool isMuted;
  final double playbackRate;
  final bool showPip;
  final bool isLocked;
  final String? videoTitle;

  const VideoTopBar({
    super.key,
    this.onBack,
    this.onToggleRate,
    this.onToggleMute,
    this.onToggleRotation,
    this.onPictureInPicture,
    this.onToggleLock,
    this.isMuted = false,
    this.playbackRate = 1.0,
    this.showPip = false,
    this.isLocked = false,
    this.videoTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 20 : 24.w,
        vertical: isLandscape ? 8 : 16.h,
      ),
      child: Row(
        children: [
          _CircularIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack ?? () => Navigator.of(context).pop(),
            isLandscape: isLandscape,
          ),
          if (videoTitle != null && videoTitle!.isNotEmpty) ...[
            SizedBox(width: isLandscape ? 10 : 12.w),
            Expanded(
              child: _MarqueeTitle(
                text: videoTitle!,
                isLandscape: isLandscape,
              ),
            ),
            SizedBox(width: isLandscape ? 10 : 12.w),
          ] else
            const Spacer(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLocked) ...[
                    _CircularIconButton(
                      icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      onPressed: onToggleMute ?? () {},
                      isActive: isMuted,
                      isLandscape: isLandscape,
                    ),
                    SizedBox(width: isLandscape ? 8 : 10.w),
                    _RateButton(
                      value: playbackRate,
                      onPressed: onToggleRate ?? () {},
                      isLandscape: isLandscape,
                    ),
                    SizedBox(width: isLandscape ? 8 : 10.w),
                    _CircularIconButton(
                      icon: Icons.screen_rotation_rounded,
                      onPressed: onToggleRotation ?? () {},
                      isLandscape: isLandscape,
                    ),
                    if (showPip) SizedBox(width: isLandscape ? 8 : 10.w),
                    if (showPip)
                      _CircularIconButton(
                        icon: Icons.picture_in_picture_alt_rounded,
                        onPressed: onPictureInPicture ?? () {},
                        isLandscape: isLandscape,
                      ),
                    SizedBox(width: isLandscape ? 8 : 10.w),
                  ],
                  _CircularIconButton(
                    icon: isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    onPressed: onToggleLock ?? () {},
                    isActive: isLocked,
                    isLandscape: isLandscape,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeTitle extends StatefulWidget {
  final String text;
  final bool isLandscape;

  const _MarqueeTitle({required this.text, required this.isLandscape});

  @override
  State<_MarqueeTitle> createState() => _MarqueeTitleState();
}

class _MarqueeTitleState extends State<_MarqueeTitle> {
  late ScrollController _scrollController;
  bool _shouldScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  @override
  void didUpdateWidget(covariant _MarqueeTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _startScrolling() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    while (_shouldScroll && mounted) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: (widget.text.length * 80).clamp(2000, 10000)),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        await Future.delayed(const Duration(seconds: 1));
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  void dispose() {
    _shouldScroll = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: TextStyle(
          color: AuraColors.text,
          fontSize: widget.isLandscape ? 13 : 13.sp,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.isLandscape = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final size = isLandscape ? 38.0 : 44.r;
    final iconSize = isLandscape ? 18.0 : 20.r;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AuraColors.primary.withValues(alpha: 0.2)
            : AuraColors.surfaceHigh.withValues(alpha: 0.5),
        border: Border.all(
          color: isActive
              ? AuraColors.primary.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(Size.square(size)),
        icon: Icon(
          icon,
          color: isActive ? AuraColors.primary : AuraColors.muted,
          size: iconSize,
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.value,
    required this.onPressed,
    this.isLandscape = false,
  });

  final double value;
  final VoidCallback onPressed;
  final bool isLandscape;

  String _formatRate(double rate) {
    final normalized = double.parse(rate.toStringAsFixed(2));
    if (normalized % 1 == 0) {
      return normalized.toStringAsFixed(0);
    }
    if ((normalized * 10) % 1 == 0) {
      return normalized.toStringAsFixed(1);
    }
    return normalized.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 12 : 12.w,
          vertical: isLandscape ? 0 : 10.h,
        ),
        constraints: BoxConstraints(
          minWidth: isLandscape ? 42 : 0,
          minHeight: isLandscape ? 38 : 0,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isLandscape ? 22 : 22.r),
          color: AuraColors.surfaceHigh.withValues(alpha: 0.55),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          '${_formatRate(value)}x',
          style: TextStyle(
            color: AuraColors.text,
            fontSize: isLandscape ? 12 : 11.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
