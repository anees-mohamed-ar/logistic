package com.example.logistic

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.util.Log

class MainActivity : FlutterActivity() {
    private val INTENT_CHANNEL = "com.example.logistic/android_intent"
    private val FLAVOR_CHANNEL = "com.example.logistic/flavor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Intent channel for URL launching
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            Log.d("MainActivity", "Launching URL with Android Intent: $url")
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Failed to launch URL with Android Intent", e)
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Flavor channel for company configuration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLAVOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCompanyId" -> {
                    try {
                        // Get company ID from resources (set by flavor)
                        val companyId = resources.getString(R.string.company_id).toInt()
                        Log.d("MainActivity", "Providing company ID: $companyId")
                        result.success(companyId)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Failed to get company ID", e)
                        // Default to company ID 7 (Cargo) if there's an error
                        result.success(7)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
