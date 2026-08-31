package com.example.capsule

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so the
// biometric prompt has a FragmentActivity host.
class MainActivity : FlutterFragmentActivity() {
    private val systemChannel = "capsule/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBiometricEnroll" -> {
                        try {
                            startActivity(biometricEnrollIntent())
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun biometricEnrollIntent(): Intent {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // BIOMETRIC_WEAK | DEVICE_CREDENTIAL — literals avoid an androidx.biometric dep.
            return Intent(Settings.ACTION_BIOMETRIC_ENROLL).apply {
                putExtra(Settings.EXTRA_BIOMETRIC_AUTHENTICATORS_ALLOWED, 0x000000FF or 0x00008000)
            }
        }
        @Suppress("DEPRECATION")
        return Intent(Settings.ACTION_SECURITY_SETTINGS)
    }
}
