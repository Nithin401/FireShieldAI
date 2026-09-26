package com.fireshield.fireshield_app

import android.content.Intent
import android.net.Uri
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fireshield/telephony"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "directCall" -> {
                    val phone = call.argument<String>("phone")
                    if (!phone.isNullOrEmpty()) {
                        try {
                            val intent = Intent(Intent.ACTION_CALL)
                            intent.data = Uri.parse("tel:$phone")
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PHONE", "Phone number empty", null)
                    }
                }
                "directSms" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    if (!phone.isNullOrEmpty() && !message.isNullOrEmpty()) {
                        try {
                            val smsManager = getSystemService(SmsManager::class.java) ?: SmsManager.getDefault()
                            smsManager.sendTextMessage(phone, null, message, null, null)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Phone or message empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

