package com.sistemasanaliticos.interautomy_mobile

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.database.Cursor
import android.provider.OpenableColumns
import android.os.Bundle
import android.os.Build
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
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
    private var pendingMetadataResult = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "openDocument") {
                    openDocument(call, result)
                    return@setMethodCallHandler
                }
                if (call.method != "pickFiles" && call.method != "pickPurchaseOrderFile") {
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
                val isPurchaseOrderPicker = call.method == "pickPurchaseOrderFile"
                val allowMultiple = if (isPurchaseOrderPicker) {
                    false
                } else {
                    call.argument<Boolean>("allowMultiple") ?: false
                }
                pendingResult = result
                pendingMetadataResult = isPurchaseOrderPicker
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
        val returnMetadata = pendingMetadataResult
        pendingMetadataResult = false
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(if (returnMetadata) null else emptyList<String>())
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
        val distinctUris = uris.distinct()
        if (returnMetadata) {
            val rawUri = distinctUris.firstOrNull()
            if (rawUri == null) {
                result.success(null)
                return
            }
            val uri = android.net.Uri.parse(rawUri)
            result.success(
                mapOf(
                    "uri" to rawUri,
                    "displayName" to displayName(uri),
                    "mimeType" to (contentResolver.getType(uri) ?: "")
                )
            )
            return
        }
        result.success(distinctUris)
    }

    private fun openDocument(call: MethodCall, result: MethodChannel.Result) {
        val rawUri = call.argument<String>("uri")
        if (rawUri.isNullOrBlank()) {
            result.error("DOCUMENT_URI_REQUIRED", "No se recibió la URI del documento.", null)
            return
        }
        val uri = android.net.Uri.parse(rawUri)
        if (uri.scheme != "content") {
            result.error("DOCUMENT_URI_INVALID", "La URI del documento no es válida.", null)
            return
        }
        val mimeType = call.argument<String>("mimeType").orEmpty().ifBlank { "*/*" }
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Abrir archivo OC"))
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error("DOCUMENT_OPEN_UNAVAILABLE", "No hay una aplicación para abrir este archivo.", null)
        } catch (_: SecurityException) {
            result.error("DOCUMENT_PERMISSION_DENIED", "No se pudo acceder al archivo seleccionado.", null)
        }
    }

    private fun displayName(uri: android.net.Uri): String {
        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) return cursor.getString(index).orEmpty().ifBlank { uri.lastPathSegment.orEmpty() }
            }
        } finally {
            cursor?.close()
        }
        return uri.lastPathSegment.orEmpty().ifBlank { "Documento seleccionado" }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        // Nunca se serializan URI ni datos seleccionados para restaurarlos automáticamente.
    }
}
