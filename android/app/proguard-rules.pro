# Flutter general
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# just_audio / ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.google.android.exoplayer2.source.** { *; }
-keep class com.google.android.exoplayer2.extractor.** { *; }
-keep class com.google.android.exoplayer2.decoder.** { *; }
-keep class com.google.android.exoplayer2.audio.** { *; }
-keep class com.google.android.exoplayer2.video.** { *; }
-keep class com.google.android.exoplayer2.metadata.** { *; }
-keep class com.google.android.exoplayer2.drm.** { *; }
-keep class com.google.android.exoplayer2.upstream.** { *; }
-keep class com.google.android.exoplayer2.trackselection.** { *; }
-keep class com.google.android.exoplayer2.ui.** { *; }
-keep class com.google.android.exoplayer2.offline.** { *; }
-keep class com.google.android.exoplayer2.mediacodec.** { *; }

# audio_service / just_audio_background
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.** { *; }

# Keep MediaSession and related
-keep class android.support.v4.media.** { *; }
-keep class android.support.v4.media.session.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media.session.** { *; }
