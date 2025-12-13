package com.example.amusemet_park_sell_ticket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.amusemet_park_sell_ticket/dual_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showImage" -> {
                    // TODO: ต้องเพิ่ม iMin SDK dependency ก่อนถึงจะใช้งานได้
                    // สำหรับตอนนี้ให้ส่ง false กลับไปก่อน
                    result.success(false)
                }
                "showText" -> {
                    result.success(false)
                }
                "clearScreen" -> {
                    result.success(false)
                }
                "initScreen" -> {
                    result.success(false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}