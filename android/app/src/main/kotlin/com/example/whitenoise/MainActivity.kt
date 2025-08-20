package org.parres.whitenoise

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.os.PersistableBundle
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "clipboard_sensitive"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setSensitive") {
                val text = call.argument<String>("text")
                if (text != null) {
                    setSensitiveClipboard(text)
                    result.success(null)
                } else {
                    result.error("NO_TEXT", "Text was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setSensitiveClipboard(text: String) {
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("label", text)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU || Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val extras = PersistableBundle()
            extras.putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
            clip.description.extras = extras
        }

        clipboard.setPrimaryClip(clip)
    }
}