package com.sistemasanaliticos.interautomy_mobile

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Adaptador mínimo para el selector de archivos de Android WebView.
 *
 * Usa Storage Access Framework: no solicita permisos amplios de almacenamiento,
 * devuelve URI content:// y no copia el archivo de forma permanente.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "interautomy/file_picker"
    private val deviceInfoChannelName = "interautomy/device_info"
    private val requestCode = 4917
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "pickFiles") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("PICKER_BUSY", "Ya existe un selector de archivos abierto.", null)
                    return@setMethodCallHandler
                }
                val acceptTypes = call.argument<List<String>>("acceptTypes")
                    ?.filter { it.isNotBlank() }
                    ?.toTypedArray()
                    ?: emptyArray()
                val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
                pendingResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
                    if (acceptTypes.isNotEmpty()) {
                        putExtra(Intent.EXTRA_MIME_TYPES, acceptTypes)
                    }
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                }
                startActivityForResult(intent, requestCode)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceInfoChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "getRuntimeInfo") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val webViewPackage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WebView.getCurrentWebViewPackage()
                } else {
                    null
                }
                result.success(
                    mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "androidSdk" to Build.VERSION.SDK_INT,
                        "webViewVersion" to (webViewPackage?.versionName ?: "unknown"),
                        "webViewPackage" to (webViewPackage?.packageName ?: "unknown")
                    )
                )
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != this.requestCode) return
        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }
        val flags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        val uris = mutableListOf<String>()
        data.data?.let { uris.add(it.toString()) }
        data.clipData?.let { clip ->
            for (index in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(index).uri.toString())
            }
        }
        uris.distinct().forEach { rawUri ->
            try {
                contentResolver.takePersistableUriPermission(android.net.Uri.parse(rawUri), flags)
            } catch (_: SecurityException) {
                // Algunos proveedores no conceden persistencia; la URI sigue válida para esta carga.
            }
        }
        result.success(uris.distinct())
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        // Nunca se serializan URI ni datos seleccionados para restaurarlos automáticamente.
    }
}
