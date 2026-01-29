package com.example.my_expense_tracker

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.my_expense_tracker/bubble"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchApp" -> {
                    launchApp()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchApp() {
        // Bring the app to foreground with SINGLE_TOP flag to reuse existing activity
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            // Clear any previous extras to ensure clean state
            removeExtra("bubbleTapped")
        }
        startActivity(intent)
        
        // Log the action
        android.util.Log.d("BubbleAction", "App launched from bubble tap via MethodChannel")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Called when app is already running and receives a new intent
        android.util.Log.d("BubbleAction", "onNewIntent called - app already in foreground")
    }
}

