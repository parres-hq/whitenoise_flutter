package org.parres.whitenoise

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Intent
import android.net.Uri
import android.os.PersistableBundle
import android.os.Build
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CLIPBOARD_CHANNEL = "clipboard_sensitive"
    private val NIP55_CHANNEL = "nip55_signer"
    
    private var nip55ResultCallback: MethodChannel.Result? = null
    private var signerPackageName: String? = null

    private val nip55Launcher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        android.util.Log.d("NIP55", "=== ACTIVITY RESULT RECEIVED ===")
        android.util.Log.d("NIP55", "Result code: ${result.resultCode}")
        android.util.Log.d("NIP55", "RESULT_OK = ${Activity.RESULT_OK}")
        android.util.Log.d("NIP55", "RESULT_CANCELED = ${Activity.RESULT_CANCELED}")
        
        val callback = nip55ResultCallback
        nip55ResultCallback = null

        if (callback == null) {
            android.util.Log.e("NIP55", "No callback available for result")
            return@registerForActivityResult
        }

        if (result.resultCode != Activity.RESULT_OK) {
            android.util.Log.e("NIP55", "Result not OK: ${result.resultCode}")
            android.util.Log.e("NIP55", "This usually means user cancelled or Amber returned an error")
            callback.error("USER_REJECTED", "Sign request rejected or cancelled. Result code: ${result.resultCode}", null)
            return@registerForActivityResult
        }

        val resultData = result.data
        if (resultData == null) {
            android.util.Log.e("NIP55", "No result data returned")
            callback.error("NO_RESULT", "No result data returned", null)
            return@registerForActivityResult
        }

        android.util.Log.d("NIP55", "=== PROCESSING RESULT DATA ===")

        // Extract result based on method type
        val resultString = resultData.getStringExtra("result")
        val id = resultData.getStringExtra("id")
        val eventJson = resultData.getStringExtra("event")
        val packageName = resultData.getStringExtra("package")

        android.util.Log.d("NIP55", "Result string: ${resultString?.take(100)}")
        android.util.Log.d("NIP55", "ID: $id")
        android.util.Log.d("NIP55", "Event JSON: ${eventJson?.take(100)}")
        android.util.Log.d("NIP55", "Package: $packageName")

        // Store package name for future use
        if (packageName != null) {
            signerPackageName = packageName
            android.util.Log.d("NIP55", "Stored signer package name: $packageName")
        }

        // Build result JSON
        val resultMap = mutableMapOf<String, Any?>()
        if (resultString != null) resultMap["result"] = resultString
        if (id != null) resultMap["id"] = id
        if (eventJson != null) resultMap["event"] = eventJson
        if (packageName != null) resultMap["package"] = packageName

        android.util.Log.d("NIP55", "=== RETURNING RESULT TO FLUTTER ===")
        android.util.Log.d("NIP55", "Result map keys: ${resultMap.keys}")
        callback.success(resultMap)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Clipboard channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL).setMethodCallHandler { call, result ->
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
        
        // NIP-55 channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NIP55_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "callNip55Method" -> {
                    val method = call.argument<String>("method")
                    val params = call.argument<String>("params")
                    
                    if (method == null || params == null) {
                        result.error("INVALID_ARGS", "Method and params are required", null)
                        return@setMethodCallHandler
                    }
                    
                    callNip55Method(method, params, result)
                }
                "isExternalSignerInstalled" -> {
                    val installed = isExternalSignerInstalled()
                    result.success(installed)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun callNip55Method(method: String, paramsJson: String, result: MethodChannel.Result) {
        try {
            android.util.Log.d("NIP55", "Calling NIP55 method: $method with params: $paramsJson")
            nip55ResultCallback = result

            val intent = Intent(Intent.ACTION_VIEW)
            
            // Parse params JSON to extract data
            val params = try {
                org.json.JSONObject(paramsJson)
            } catch (e: Exception) {
                result.error("INVALID_JSON", "Invalid params JSON: ${e.message}", null)
                return
            }
            
            when (method) {
                "get_public_key" -> {
                    val uri = Uri.parse("nostrsigner:")
                    intent.data = uri
                    intent.putExtra("type", "get_public_key")
                    
                    // Optional: send default permissions
                    val permissions = params.optJSONArray("permissions")
                    if (permissions != null) {
                        intent.putExtra("permissions", permissions.toString())
                    }
                }
                "sign_event" -> {
                    android.util.Log.d("NIP55", "=== SIGN_EVENT REQUEST ===")
                    val eventJson = params.optString("event", "")
                    android.util.Log.d("NIP55", "Event JSON length: ${eventJson.length}")
                    android.util.Log.d("NIP55", "Event JSON (first 200 chars): ${eventJson.take(200)}")
                    
                    val uri = Uri.parse("nostrsigner:$eventJson")
                    intent.data = uri
                    intent.putExtra("type", "sign_event")
                    
                    val id = params.optString("id", "")
                    val currentUser = params.optString("current_user", "")
                    
                    android.util.Log.d("NIP55", "ID: $id, currentUser: $currentUser")
                    
                    if (id.isNotEmpty()) intent.putExtra("id", id)
                    if (currentUser.isNotEmpty()) intent.putExtra("current_user", currentUser)
                    
                    // Set package name if we have it stored
                    signerPackageName?.let { 
                        android.util.Log.d("NIP55", "Setting package to: $it")
                        intent.setPackage(it) 
                    }
                    
                    // Add flags for multiple intents
                    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    android.util.Log.d("NIP55", "Launching sign_event intent")
                }
                "nip04_encrypt", "nip44_encrypt", "nip04_decrypt", "nip44_decrypt" -> {
                    val data = params.optString("data", "")
                    val uri = Uri.parse("nostrsigner:$data")
                    intent.data = uri
                    intent.putExtra("type", method)
                    
                    val id = params.optString("id", "")
                    val currentUser = params.optString("current_user", "")
                    val pubkey = params.optString("pubkey", "")
                    
                    if (id.isNotEmpty()) intent.putExtra("id", id)
                    if (currentUser.isNotEmpty()) intent.putExtra("current_user", currentUser)
                    if (pubkey.isNotEmpty()) intent.putExtra("pubkey", pubkey)
                    
                    signerPackageName?.let { intent.setPackage(it) }
                    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                "decrypt_zap_event" -> {
                    val eventJson = params.optString("event", "")
                    val uri = Uri.parse("nostrsigner:$eventJson")
                    intent.data = uri
                    intent.putExtra("type", "decrypt_zap_event")
                    
                    val id = params.optString("id", "")
                    val currentUser = params.optString("current_user", "")
                    
                    if (id.isNotEmpty()) intent.putExtra("id", id)
                    if (currentUser.isNotEmpty()) intent.putExtra("current_user", currentUser)
                    
                    signerPackageName?.let { intent.setPackage(it) }
                    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                else -> {
                    result.error("UNKNOWN_METHOD", "Unknown NIP-55 method: $method", null)
                    return
                }
            }

            // Check if intent can be resolved
            val resolveInfo = packageManager.resolveActivity(intent, 0)
            android.util.Log.d("NIP55", "Intent resolve info: $resolveInfo")
            if (resolveInfo == null) {
                android.util.Log.e("NIP55", "No activity found to handle intent")
                result.error("NO_ACTIVITY", "No activity found to handle NIP-55 intent", null)
                return
            }

            android.util.Log.d("NIP55", "Launching NIP55 intent")
            nip55Launcher.launch(intent)
        } catch (e: Exception) {
            android.util.Log.e("NIP55", "Exception in callNip55Method: ${e.message}", e)
            result.error("EXCEPTION", "Error calling NIP-55 method: ${e.message}", null)
        }
    }
    
    private fun isExternalSignerInstalled(): Boolean {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("nostrsigner:")
        }
        val infos = packageManager.queryIntentActivities(intent, 0)
        android.util.Log.d("NIP55", "External signer installed check: ${infos.size} activities found")
        infos.forEach { info ->
            android.util.Log.d("NIP55", "Activity: ${info.activityInfo.packageName}/${info.activityInfo.name}")
        }
        return infos.size > 0
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