package com.nkshub.nextclouddeck

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingCamera: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.nkshub.nextclouddeck/camera_permission")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(cameraStatus())
                    "request" -> requestCamera(result)
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(Uri.parse("package:$packageName")))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun cameraStatus(): Map<String, String> {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            return mapOf("status" to "granted")
        }
        val asked = getSharedPreferences("permissions", MODE_PRIVATE).getBoolean("camera_asked", false)
        return mapOf("status" to if (asked) "denied" else "notDetermined")
    }

    private fun requestCamera(result: MethodChannel.Result) {
        if (cameraStatus()["status"] == "granted") {
            result.success(cameraStatus())
            return
        }
        if (pendingCamera != null) {
            result.error("in_progress", "A camera request is already active.", null)
            return
        }
        pendingCamera = result
        getSharedPreferences("permissions", MODE_PRIVATE).edit().putBoolean("camera_asked", true).apply()
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 4108)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 4108) return
        if (grantResults.isEmpty()) {
            getSharedPreferences("permissions", MODE_PRIVATE).edit().putBoolean("camera_asked", false).apply()
        }
        pendingCamera?.success(cameraStatus())
        pendingCamera = null
    }

    override fun onDestroy() {
        pendingCamera?.error("cancelled", "The camera request was cancelled.", null)
        pendingCamera = null
        super.onDestroy()
    }
}
