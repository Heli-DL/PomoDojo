package helidelorme.com.pomodojo_app

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.app.NotificationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "focus_shield"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val nm = getSystemService(NotificationManager::class.java)

                when (call.method) {
                    "hasDNDPermission" -> {
                        result.success(nm.isNotificationPolicyAccessGranted)
                    }
                    "openDNPSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                // Fallback to general settings if specific screen is unavailable
                                val fallback = Intent(Settings.ACTION_SETTINGS)
                                if (fallback.resolveActivity(packageManager) != null) {
                                    startActivity(fallback)
                                    result.success(true)
                                } else {
                                    result.error("UNAVAILABLE", "No settings activity found", null)
                                }
                            }
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", "Failed to open DND settings: ${e.message}", null)
                        }
                    }
                    "enableDND" -> {
                        if (nm.isNotificationPolicyAccessGranted) {
                            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                            result.success(true)
                        } else {
                            result.error("DENIED", "DND access not granted", null)
                        }
                    }
                    "disableDND" -> {
                        if (nm.isNotificationPolicyAccessGranted) {
                            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                            result.success(true)
                        } else {
                            result.error("DENIED", "DND access not granted", null)
                        }
                    }
                    "isGranted" -> {
                        result.success(nm.isNotificationPolicyAccessGranted)
                    }
                    "openSettings" -> {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    "setDnd" -> {
                        val mode = call.argument<Int>("mode") ?: NotificationManager.INTERRUPTION_FILTER_ALL
                        if (nm.isNotificationPolicyAccessGranted) {
                            nm.setInterruptionFilter(mode)
                            result.success(true)
                        } else {
                            result.error("DENIED", "DND access not granted", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

