package com.example.aura_media_player

import android.annotation.SuppressLint
import android.app.PictureInPictureParams
import android.content.ContentValues
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Rational
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.aura.media.player/pip"
    private val FILE_CHANNEL = "com.aura.media.player/file"
    private var isPipActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(isPictureInPictureSupported())
                }
                "enter" -> {
                    enterPipMode()
                    result.success(true)
                }
                "setAspectRatio" -> {
                    val width = call.argument<Double>("width") ?: 16.0
                    val height = call.argument<Double>("height") ?: 9.0
                    setPipAspectRatio(width, height)
                    result.success(true)
                }
                "isActive" -> {
                    result.success(isPipActive)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteMediaFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    val mediaType = call.argument<String>("mediaType") ?: "audio"
                    val id = call.argument<Long>("id")
                    val deleted = deleteMediaFile(path, mediaType, id)
                    result.success(deleted)
                }
                "renameMediaFile" -> {
                    val oldPath = call.argument<String>("oldPath") ?: ""
                    val newPath = call.argument<String>("newPath") ?: ""
                    val mediaType = call.argument<String>("mediaType") ?: "audio"
                    val id = call.argument<Long>("id")
                    val renamed = renameMediaFile(oldPath, newPath, mediaType, id)
                    result.success(renamed)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun deleteMediaFile(path: String, mediaType: String, id: Long?): Boolean {
        // Try physical file delete first
        try {
            val file = File(path)
            if (file.exists() && file.delete()) {
                val uri = getContentUri(mediaType)
                if (uri != null) {
                    contentResolver.delete(uri, "${MediaStore.MediaColumns.DATA}=?", arrayOf(path))
                }
                return true
            }
        } catch (_: SecurityException) {
            // Scoped storage: try MediaStore delete
        }
        // Try MediaStore delete using ID
        if (id != null && id > 0) {
            try {
                val uri = getContentUri(mediaType)
                if (uri != null) {
                    val deleteUri = Uri.withAppendedPath(uri, id.toString())
                    val deleted = contentResolver.delete(deleteUri, null, null)
                    if (deleted > 0) return true
                }
            } catch (_: Exception) {}
        }
        // Fallback: try delete by path
        try {
            val uri = getContentUri(mediaType)
            if (uri != null) {
                val deleted = contentResolver.delete(uri, "${MediaStore.MediaColumns.DATA}=?", arrayOf(path))
                if (deleted > 0) return true
            }
        } catch (_: Exception) {}
        return false
    }

    private fun renameMediaFile(oldPath: String, newPath: String, mediaType: String, id: Long?): Boolean {
        // Try physical file rename first (works on Android 9 and below)
        try {
            val file = File(oldPath)
            val newFile = File(newPath)
            if (file.exists() && file.renameTo(newFile)) {
                updateMediaStorePath(oldPath, newPath, mediaType)
                return true
            }
        } catch (_: SecurityException) {}
        // Fallback: update DISPLAY_NAME in MediaStore (keeps file in place but updates metadata)
        if (id != null && id > 0) {
            try {
                val uri = getContentUri(mediaType)
                if (uri != null) {
                    val updateUri = Uri.withAppendedPath(uri, id.toString())
                    val fileName = File(newPath).name
                    val values = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.TITLE, fileName.substringBeforeLast('.'))
                    }
                    val updated = contentResolver.update(updateUri, values, null, null)
                    if (updated > 0) return true
                }
            } catch (_: Exception) {}
        }
        return false
    }

    private fun updateMediaStorePath(oldPath: String, newPath: String, mediaType: String) {
        try {
            val uri = getContentUri(mediaType) ?: return
            val fileName = File(newPath).name
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DATA, newPath)
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.TITLE, fileName.substringBeforeLast('.'))
            }
            contentResolver.update(uri, values, "${MediaStore.MediaColumns.DATA}=?", arrayOf(oldPath))
        } catch (_: Exception) {}
    }

    private fun getContentUri(mediaType: String): Uri? {
        return if (mediaType == "audio") {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        } else if (mediaType == "video") {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            null
        }
    }

    @SuppressLint("NewApi")
    private fun isPictureInPictureSupported(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        } else {
            false
        }
    }

    @SuppressLint("NewApi")
    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (!isPictureInPictureSupported()) return

        val aspectRatio = Rational(16, 9)
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(aspectRatio)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setActions(emptyList())
        }

        enterPictureInPictureMode(builder.build())
    }

    @SuppressLint("NewApi")
    private fun setPipAspectRatio(width: Double, height: Double) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val rational = Rational(Math.round(width).toInt(), Math.round(height).toInt())
        val params = PictureInPictureParams.Builder()
            .setAspectRatio(rational)
            .build()
        setPictureInPictureParams(params)
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        isPipActive = isInPictureInPictureMode
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onPipModeChanged", isInPictureInPictureMode)
        }
    }
}
