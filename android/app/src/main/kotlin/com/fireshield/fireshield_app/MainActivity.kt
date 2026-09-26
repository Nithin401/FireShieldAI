package com.fireshield.fireshield_app

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.telephony.SmsManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fireshield/telephony"
    private var alarmRingtone: Ringtone? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        unlockAndTurnScreenOn()
    }

    private fun unlockAndTurnScreenOn() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "wakeScreenAndAlert" -> {
                    try {
                        unlockAndTurnScreenOn()
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        if (powerManager != null) {
                            @Suppress("DEPRECATION")
                            wakeLock = powerManager.newWakeLock(
                                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                                "fireshield:emergencylockscreen"
                            )
                            wakeLock?.acquire(30000) // 30 seconds
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                            keyguardManager?.requestDismissKeyguard(this, null)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WAKE_ERROR", e.message, null)
                    }
                }
                "playAlarmSiren" -> {
                    try {
                        if (alarmRingtone == null) {
                            var alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            if (alertUri == null) {
                                alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                            }
                            alarmRingtone = RingtoneManager.getRingtone(applicationContext, alertUri)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                val audioAttributes = AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_ALARM)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                    .build()
                                alarmRingtone?.audioAttributes = audioAttributes
                            }
                        }
                        if (alarmRingtone?.isPlaying == false) {
                            alarmRingtone?.play()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                "stopAlarmSiren" -> {
                    try {
                        if (alarmRingtone?.isPlaying == true) {
                            alarmRingtone?.stop()
                        }
                        wakeLock?.let {
                            if (it.isHeld) it.release()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
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
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrEmpty()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_URL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL is empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        alarmRingtone?.stop()
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        super.onDestroy()
    }
}

