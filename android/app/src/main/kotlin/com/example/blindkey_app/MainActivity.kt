package com.example.blindkey_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ensure all plugins are registered (GeneratedPluginRegistrant is handled automatically by super in newer implementations but good to keep if manually needed, though usually redundant now. leaving acts as safe)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.blindkey_app/file_utils").setMethodCallHandler { call, result ->
            if (call.method == "resolveContentUri") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    val path = resolveContentUri(uriString)
                    if (path != null) {
                        result.success(path)
                    } else {
                        result.error("UNAVAILABLE", "Could not resolve URI", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "URI is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun resolveContentUri(uriString: String): String? {
        try {
            val uri = android.net.Uri.parse(uriString)
            val contentResolver = contentResolver
            
            // Open input stream from the content URI
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            
            // Create a temporary file in the cache directory
            val cacheDir = cacheDir
            // Try to deduce extension or name, but for now specific to blindkey or generic
            val fileName = "temp_import_${System.currentTimeMillis()}.blindkey" 
            val file = java.io.File(cacheDir, fileName)
            
            val outputStream = java.io.FileOutputStream(file)
            
            inputStream.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }
            
            return file.absolutePath
        } catch (e: Exception) {
            return null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // High security: Prevent screenshots and screen recording ALWAYS
        enableSecureFlag()
    }

    override fun onStart() {
        super.onStart()
        // Ensure protection when activity starts
        enableSecureFlag()
    }

    override fun onResume() {
        super.onResume()
        // Ensure FLAG_SECURE is always set when app resumes
        enableSecureFlag()
    }

    override fun onPause() {
        super.onPause()
        // Keep protection even when minimized/backgrounded
        enableSecureFlag()
    }

    override fun onStop() {
        super.onStop()
        // Maintain protection when activity stops
        enableSecureFlag()
    }

    override fun onRestart() {
        super.onRestart()
        // Re-enable protection when restarting
        enableSecureFlag()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Ensure protection regardless of focus state
        enableSecureFlag()
    }

    /**
     * Enable FLAG_SECURE to prevent screenshots and screen recording
     * This works even when app is minimized or in background
     */
    private fun enableSecureFlag() {
        try {
            window?.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        } catch (e: Exception) {
            // Silently handle any exceptions
        }
    }
}
