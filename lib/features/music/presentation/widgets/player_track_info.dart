import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';
import 'package:aura/core/theme/app_borders.dart';
import 'package:aura/shared/widgets/custom_text.dart';
import 'package:aura/core/services/audio_player_service.dart';

class PlayerTrackInfo extends StatefulWidget {
  const PlayerTrackInfo({
    super.key,
    required this.title,
    required this.artist,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final String title;
  final String artist;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  State<PlayerTrackInfo> createState() => _PlayerTrackInfoState();
}

class _PlayerTrackInfoState extends State<PlayerTrackInfo> {
  void _toggleFavorite(BuildContext context) {
    final wasFavorite = widget.isFavorite;
    widget.onToggleFavorite?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite
              ? '"${widget.title}" removed from Favorites'
              : '"${widget.title}" added to Favorites',
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    final audioService = AudioPlayerService();
    final queue = audioService.currentQueue;
    final currentIndex = audioService.currentQueueIndex ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: Column(
            children: [
              Text(
                'Up Next',
                style: TextStyle(
                  color: AuraColors.text,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${queue.length} songs  •  ${currentIndex + 1} now playing',
                style: TextStyle(
                  color: AuraColors.muted,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  itemCount: queue.length,
                  itemBuilder: (ctx, i) {
                    final item = queue[i];
                    final isCurrent = i == currentIndex;
                    return Material(
                      color: isCurrent
                          ? AuraColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: isCurrent
                            ? null
                            : () {
                                audioService.playQueueIndex(i);
                                Navigator.pop(ctx);
                              },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: AuraColors.neutral.withValues(alpha: 0.5),
                                  borderRadius: AppBorders.sm,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: isCurrent ? AuraColors.primary : AuraColors.muted,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        color: isCurrent ? AuraColors.primary : AuraColors.text,
                                        fontSize: 13.sp,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      item.artist ?? 'Unknown Artist',
                                      style: TextStyle(
                                        color: AuraColors.muted,
                                        fontSize: 11.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Icon(Icons.play_arrow_rounded, color: AuraColors.primary, size: 20.r)
                              else
                                Text(
                                  _formatDuration(item.durationMs),
                                  style: TextStyle(
                                    color: AuraColors.muted.withValues(alpha: 0.6),
                                    fontSize: 11.sp,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '00:00';
    final totalSec = (ms / 1000).floor();
    final m = ((totalSec % 3600) / 60).floor();
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Column(
              children: [
                SizedBox(
                  height: 35.h,
                  child: _MarqueeWidget(
                    text: widget.title,
                    style: TextStyle(
                      color: AuraColors.text,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: AuraColors.primary.withValues(alpha: 0.6),
                          blurRadius: 16.r,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text: widget.artist,
                  textColor: AuraColors.muted,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            child: IconButton(
              onPressed: () => _showQueue(context),
              icon: Icon(
                Icons.queue_music_rounded,
                color: AuraColors.muted,
                size: 28.r,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: widget.onToggleFavorite == null
                  ? null
                  : () => _toggleFavorite(context),
              icon: Icon(
                widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: widget.isFavorite ? AuraColors.primary : AuraColors.muted,
                size: 28.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const _MarqueeWidget({required this.text, required this.style});

  @override
  State<_MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<_MarqueeWidget> {
  late ScrollController _scrollController;
  bool _shouldScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  @override
  void didUpdateWidget(covariant _MarqueeWidget oldWidget) {
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Text(
          widget.text,
          style: widget.style,
        ),
      ),
    );
  }
}
