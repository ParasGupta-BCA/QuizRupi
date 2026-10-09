package com.quizrupi.quizrupi

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.quizrupi.customer/upi"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUpiIntent") {
                val upiUriString = call.argument<String>("uri")
                val requestCode = call.argument<Int>("requestCode") ?: 0

                if (upiUriString.isNullOrBlank()) {
                    result.error("INVALID_URI", "UPI URI cannot be null or empty", null)
                    return@setMethodCallHandler
                }

                try {
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        data = Uri.parse(upiUriString)
                    }
                    val chooser = Intent.createChooser(intent, "Pay with UPI")
                    pendingResult?.error("CANCELLED", "Superceded by new payment request", null)
                    pendingResult = result
                    startActivityForResult(chooser, requestCode)
                } catch (e: Exception) {
                    pendingResult = null
                    result.error("LAUNCH_FAILED", e.localizedMessage, null)
                }
            } else if (call.method == "getDeviceId") {
                try {
                    val id = android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.ANDROID_ID) ?: ""
                    result.success(id)
                } catch (e: Exception) {
                    result.success("")
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        var response = "discard"
        if (resultCode == RESULT_OK && data != null) {
            val res = data.getStringExtra("response")
            if (!res.isNullOrBlank()) {
                response = res
            }
        } else if (data != null) {
            val res = data.getStringExtra("response")
            if (!res.isNullOrBlank()) {
                response = res
            }
        }
        val resultMap = mapOf(
            "response" to response,
            "resultCode" to resultCode,
            "requestCode" to requestCode
        )
        pendingResult?.success(resultMap)
        pendingResult = null
    }
}
