package hu.relaycore.pulzar

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Fájl mentése / megnyitása a rendszer fájlválasztójával (Storage Access Framework),
 * és egy mentett fájl megnyitása más alkalmazással (pl. PDF-nézegető, v0.5.0).
 * A Dart oldal: lib/platform/file_access.dart (ADR-010).
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "viewFile") {
                    result.success(viewFile(call.argument<String>("uri"), call.argument<String>("mimeType")))
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("busy", "Another file operation is in progress", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "saveFile" -> {
                        pendingBytes = call.argument<ByteArray>("bytes")
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = call.argument<String>("mimeType") ?: "application/octet-stream"
                            putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "pulzar")
                        }
                        startActivityForResult(intent, REQUEST_SAVE)
                    }
                    "openFile" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        }
                        startActivityForResult(intent, REQUEST_OPEN)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** A mentett fájl megnyitása: a fogadó alkalmazás csak olvasási jogot kap erre az egy fájlra. */
    private fun viewFile(uri: String?, mimeType: String?): Boolean {
        if (uri == null) return false
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uri), mimeType ?: "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return
        val result = pendingResult ?: return
        pendingResult = null
        val bytes = pendingBytes
        pendingBytes = null
        val uri: Uri? = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) {
            result.success(null)
            return
        }
        try {
            if (requestCode == REQUEST_SAVE) {
                val stream = contentResolver.openOutputStream(uri, "w")
                    ?: throw IllegalStateException("Cannot write the file")
                stream.use { it.write(bytes ?: ByteArray(0)) }
                result.success(uri.toString())
            } else {
                val stream = contentResolver.openInputStream(uri)
                    ?: throw IllegalStateException("Cannot read the file")
                result.success(stream.use { it.readBytes() })
            }
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
    }

    companion object {
        private const val CHANNEL = "hu.relaycore.pulzar/files"
        private const val REQUEST_SAVE = 4101
        private const val REQUEST_OPEN = 4102
    }
}
