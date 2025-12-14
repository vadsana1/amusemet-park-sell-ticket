package com.example.amusemet_park_sell_ticket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.amusemet_park_sell_ticket/dual_screen"
    private lateinit var dualScreenHelper: IminDualScreenHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        dualScreenHelper = IminDualScreenHelper(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showImage" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    if (imageBytes != null) {
                        val success = dualScreenHelper.showImageOnCustomerScreen(imageBytes)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image bytes is null", null)
                    }
                }
                "clearScreen" -> {
                    val success = dualScreenHelper.clearCustomerScreen()
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}