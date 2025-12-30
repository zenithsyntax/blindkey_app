package com.example.blindkey_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ensure all plugins are registered
        GeneratedPluginRegistrant.registerWith(flutterEngine)
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
