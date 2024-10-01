package com.flexben.hr

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.provider.MediaStore
import android.os.Environment

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.flexben.downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveFileToDownloads") {
                val fileBytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName")
                if (fileBytes != null && fileName != null) {
                    try {
                        saveFileToDownloads(fileBytes, fileName)
                        result.success("File saved successfully")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to save file: ${e.message}", null)
                    }
                } else {
                    result.error("ERROR", "Invalid arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveFileToDownloads(fileBytes: ByteArray, fileName: String): String? {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }

        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
        contentResolver.openOutputStream(uri!!).use { outputStream ->
            outputStream!!.write(fileBytes)
        }

        // Retrieve the file's absolute path
        val cursor = contentResolver.query(uri, null, null, null, null)
        var path: String? = null
        if (cursor != null && cursor.moveToFirst()) {
            val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
            path = cursor.getString(columnIndex)
            cursor.close()
        }
        return path
    }
}
