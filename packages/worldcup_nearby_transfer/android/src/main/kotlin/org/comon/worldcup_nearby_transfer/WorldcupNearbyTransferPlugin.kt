package org.comon.worldcup_nearby_transfer

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.ConnectionsStatusCodes
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.Executors

class WorldcupNearbyTransferPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val PROTOCOL_VERSION = 1
        private const val METHODS = "org.comon.my_worldcup_local/nearby_transfer/methods"
        private const val EVENTS = "org.comon.my_worldcup_local/nearby_transfer/events"
        private const val TAG = "WorldcupNearby"
        private const val PERMISSION_REQUEST = 7461
        private val STRATEGY = Strategy.P2P_POINT_TO_POINT
    }

    private lateinit var context: Context
    private lateinit var client: ConnectionsClient
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var activeServiceId: String? = null
    private var advertising = false
    private var discovering = false
    private var pendingEndpointId: String? = null
    private var connectedEndpointId: String? = null
    private var outgoingPayload: Payload? = null
    private var incomingEndpointNames = mutableMapOf<String, String>()
    private var discoveredEndpoints = mutableMapOf<String, String>()
    private val incomingFiles = mutableMapOf<Long, Payload>()
    private val incomingMetadata = mutableMapOf<Long, FileMetadata>()
    private val completedIncoming = mutableSetOf<Long>()
    private val incomingSizes = mutableMapOf<Long, Pair<Long, Long>>()
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private data class FileMetadata(val name: String, val size: Long)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        client = Nearby.getConnectionsClient(context)
        methodChannel = MethodChannel(binding.binaryMessenger, METHODS)
        eventChannel = EventChannel(binding.binaryMessenger, EVENTS)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cleanup(deleteReceivedFiles = true)
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        ioExecutor.shutdownNow()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        detachActivity()
        cleanup(deleteReceivedFiles = true)
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
        pendingPermissionResult?.error(
            "activity_unavailable",
            "권한 요청 화면을 사용할 수 없습니다.",
            null,
        )
        pendingPermissionResult = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        cleanup(deleteReceivedFiles = true)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = readArguments(call, result) ?: return
        when (call.method) {
            "checkAvailability" -> result.success(availability())
            "requestPermissions" -> requestPermissions(result)
            "openAppSettings" -> openAppSettings(result)
            "startDiscovery" -> startDiscovery(args, result)
            "stopDiscovery" -> {
                stopDiscovery()
                result.success(null)
            }
            "startAdvertising" -> startAdvertising(args, result)
            "stopAdvertising" -> {
                stopAdvertising()
                result.success(null)
            }
            "requestConnection" -> requestConnection(args, result)
            "acceptConnection" -> acceptConnection(args, result)
            "rejectConnection" -> rejectConnection(args, result)
            "sendFile" -> sendFile(args, result)
            "cancelTransfer" -> {
                cancelTransfer()
                result.success(null)
            }
            "disconnect" -> {
                disconnect()
                result.success(null)
            }
            "dispose" -> {
                cleanup(deleteReceivedFiles = true)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun readArguments(
        call: MethodCall,
        result: MethodChannel.Result,
    ): Map<*, *>? {
        val args = call.arguments as? Map<*, *>
        val version = args?.get("version") as? Int
        val serviceId = args?.get("serviceId") as? String
        if (version != PROTOCOL_VERSION || serviceId.isNullOrBlank()) {
            result.error("protocol", "지원하지 않는 Nearby 프로토콜입니다.", null)
            return null
        }
        if (activeServiceId != null && activeServiceId != serviceId) {
            result.error("protocol", "Nearby serviceId가 실행 중에 변경되었습니다.", null)
            return null
        }
        activeServiceId = serviceId
        return args
    }

    private fun requiredString(
        args: Map<*, *>,
        key: String,
        result: MethodChannel.Result,
    ): String? {
        val value = args[key] as? String
        if (value.isNullOrBlank()) {
            result.error("protocol", "Nearby 요청의 $key 값이 없습니다.", null)
            return null
        }
        return value
    }

    private fun requiredPermissions(): Array<String> {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT <= 28) {
            permissions += Manifest.permission.ACCESS_COARSE_LOCATION
        } else if (Build.VERSION.SDK_INT <= 31) {
            permissions += Manifest.permission.ACCESS_FINE_LOCATION
        }
        if (Build.VERSION.SDK_INT >= 31) {
            permissions += Manifest.permission.BLUETOOTH_ADVERTISE
            permissions += Manifest.permission.BLUETOOTH_CONNECT
            permissions += Manifest.permission.BLUETOOTH_SCAN
        }
        if (Build.VERSION.SDK_INT >= 33) {
            permissions += Manifest.permission.NEARBY_WIFI_DEVICES
        }
        if (Build.VERSION.SDK_INT >= 37 && context.applicationInfo.targetSdkVersion >= 37) {
            permissions += "android.permission.ACCESS_LOCAL_NETWORK"
        }
        if (Build.VERSION.SDK_INT <= 32) {
            permissions += Manifest.permission.READ_EXTERNAL_STORAGE
        }
        return permissions.distinct().toTypedArray()
    }

    private fun permissionState(): String {
        val denied = requiredPermissions().filter {
            ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
        }
        if (denied.isEmpty()) return "granted"
        val wasAsked = context.getSharedPreferences("worldcup_nearby", Context.MODE_PRIVATE)
            .getBoolean("permissionsAsked", false)
        val currentActivity = activity
        val permanentlyDenied = wasAsked && currentActivity != null && denied.any {
            !ActivityCompat.shouldShowRequestPermissionRationale(currentActivity, it)
        }
        return if (permanentlyDenied) "permanentlyDenied" else "denied"
    }

    private fun availability(): Map<String, Any?> {
        val supported = GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS
        val bluetoothState = try {
            val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            if (manager.adapter?.isEnabled == true) "enabled" else "disabled"
        } catch (_: SecurityException) {
            "unknown"
        }
        val wifiState = try {
            val manager = context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager
            if (manager.isWifiEnabled) "enabled" else "disabled"
        } catch (_: SecurityException) {
            "unknown"
        }
        return mapOf(
            "version" to PROTOCOL_VERSION,
            "supported" to supported,
            "permission" to permissionState(),
            "bluetooth" to bluetoothState,
            "wifi" to wifiState,
            "canOpenSettings" to true,
            "message" to if (supported) null else "Google Play 서비스를 사용할 수 없습니다.",
        )
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        if (permissionState() == "granted") {
            result.success(availability())
            return
        }
        val currentActivity = activity
        if (currentActivity == null || pendingPermissionResult != null) {
            result.error("activity_unavailable", "권한 요청 화면을 사용할 수 없습니다.", null)
            return
        }
        pendingPermissionResult = result
        context.getSharedPreferences("worldcup_nearby", Context.MODE_PRIVATE)
            .edit().putBoolean("permissionsAsked", true).apply()
        ActivityCompat.requestPermissions(
            currentActivity,
            requiredPermissions(),
            PERMISSION_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        pendingPermissionResult?.success(availability())
        pendingPermissionResult = null
        return true
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        result.success(null)
    }

    private fun ensureReady(result: MethodChannel.Result): Boolean {
        val state = availability()
        if (state["supported"] != true) {
            result.error("unavailable", state["message"] as? String, null)
            return false
        }
        if (state["permission"] != "granted") {
            result.error(state["permission"].toString(), "주변 기기 권한이 필요합니다.", null)
            return false
        }
        if (state["bluetooth"] == "disabled" || state["wifi"] == "disabled") {
            result.error("radioOff", "Bluetooth와 Wi-Fi를 켜주세요.", null)
            return false
        }
        return true
    }

    private fun startDiscovery(args: Map<*, *>, result: MethodChannel.Result) {
        if (!ensureReady(result)) return
        if (advertising || discovering || pendingEndpointId != null || connectedEndpointId != null) {
            result.error("alreadyBusy", "이미 다른 Nearby 작업이 진행 중입니다.", null)
            return
        }
        val serviceId = activeServiceId ?: return
        discovering = true
        client.startDiscovery(
            serviceId,
            discoveryCallback,
            DiscoveryOptions.Builder().setStrategy(STRATEGY).build(),
        ).addOnSuccessListener {
            result.success(null)
        }.addOnFailureListener { error ->
            discovering = false
            failResult(result, "unavailable", "주변 기기 검색을 시작할 수 없습니다.", error)
        }
    }

    private fun startAdvertising(args: Map<*, *>, result: MethodChannel.Result) {
        if (!ensureReady(result)) return
        if (advertising || discovering || pendingEndpointId != null || connectedEndpointId != null) {
            result.error("alreadyBusy", "이미 다른 Nearby 작업이 진행 중입니다.", null)
            return
        }
        val displayName = requiredString(args, "displayName", result) ?: return
        val serviceId = activeServiceId ?: return
        advertising = true
        client.startAdvertising(
            displayName,
            serviceId,
            connectionCallback,
            AdvertisingOptions.Builder().setStrategy(STRATEGY).build(),
        ).addOnSuccessListener {
            result.success(null)
        }.addOnFailureListener { error ->
            advertising = false
            failResult(result, "unavailable", "수신 대기를 시작할 수 없습니다.", error)
        }
    }

    private fun stopDiscovery() {
        if (discovering) client.stopDiscovery()
        discovering = false
        discoveredEndpoints.clear()
    }

    private fun stopAdvertising() {
        if (advertising) client.stopAdvertising()
        advertising = false
    }

    private fun requestConnection(args: Map<*, *>, result: MethodChannel.Result) {
        if (!discovering || pendingEndpointId != null || connectedEndpointId != null) {
            result.error("invalidState", "연결 요청을 시작할 수 없는 상태입니다.", null)
            return
        }
        val endpointId = requiredString(args, "endpointId", result) ?: return
        val displayName = requiredString(args, "displayName", result) ?: return
        if (!discoveredEndpoints.containsKey(endpointId)) {
            result.error("invalidState", "선택한 기기를 더 이상 찾을 수 없습니다.", null)
            return
        }
        pendingEndpointId = endpointId
        client.requestConnection(displayName, endpointId, connectionCallback)
            .addOnSuccessListener {
                stopDiscovery()
                result.success(null)
            }.addOnFailureListener { error ->
                pendingEndpointId = null
                failResult(result, "connectionFailed", "연결 요청을 보낼 수 없습니다.", error)
            }
    }

    private fun acceptConnection(args: Map<*, *>, result: MethodChannel.Result) {
        val endpointId = requiredString(args, "endpointId", result) ?: return
        if (pendingEndpointId != endpointId) {
            result.error("invalidState", "대기 중인 연결 요청이 아닙니다.", null)
            return
        }
        client.acceptConnection(endpointId, payloadCallback)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { error ->
                failResult(result, "connectionFailed", "연결 요청을 수락할 수 없습니다.", error)
            }
    }

    private fun rejectConnection(args: Map<*, *>, result: MethodChannel.Result) {
        val endpointId = requiredString(args, "endpointId", result) ?: return
        if (pendingEndpointId != endpointId) {
            result.error("invalidState", "대기 중인 연결 요청이 아닙니다.", null)
            return
        }
        client.rejectConnection(endpointId)
            .addOnSuccessListener {
                pendingEndpointId = null
                emitConnection(endpointId, "rejected")
                result.success(null)
            }.addOnFailureListener { error ->
                failResult(result, "connectionFailed", "연결 요청을 거절할 수 없습니다.", error)
            }
    }

    private fun sendFile(args: Map<*, *>, result: MethodChannel.Result) {
        val endpointId = requiredString(args, "endpointId", result) ?: return
        val path = requiredString(args, "path", result) ?: return
        val requestedName = requiredString(args, "name", result) ?: return
        if (connectedEndpointId != endpointId || outgoingPayload != null) {
            result.error("alreadyBusy", "한 번에 하나의 파일만 전송할 수 있습니다.", null)
            return
        }
        val file = File(path)
        if (!file.isFile || !file.canRead()) {
            result.error("io", "전송할 월드컵 파일을 읽을 수 없습니다.", null)
            return
        }
        try {
            val filePayload = Payload.fromFile(file)
            outgoingPayload = filePayload
            val safeName = sanitizeName(requestedName)
            val metadata = JSONObject()
                .put("version", PROTOCOL_VERSION)
                .put("kind", "fileMetadata")
                .put("payloadId", filePayload.id.toString())
                .put("name", safeName)
                .put("size", file.length())
                .toString().toByteArray(Charsets.UTF_8)
            client.sendPayload(endpointId, Payload.fromBytes(metadata))
                .continueWithTask { task ->
                    if (!task.isSuccessful) throw task.exception ?: IllegalStateException()
                    client.sendPayload(endpointId, filePayload)
                }.addOnSuccessListener {
                    result.success(null)
                }.addOnFailureListener { error ->
                    outgoingPayload = null
                    failResult(result, "transferFailed", "파일 전송을 시작할 수 없습니다.", error)
                }
        } catch (error: Exception) {
            outgoingPayload = null
            failResult(result, "io", "전송할 월드컵 파일을 열 수 없습니다.", error)
        }
    }

    private fun cancelTransfer() {
        outgoingPayload?.let { client.cancelPayload(it.id) }
        incomingFiles.keys.forEach { client.cancelPayload(it) }
        outgoingPayload = null
    }

    private fun disconnect() {
        connectedEndpointId?.let { client.disconnectFromEndpoint(it) }
        pendingEndpointId?.let { client.disconnectFromEndpoint(it) }
        connectedEndpointId = null
        pendingEndpointId = null
    }

    private fun cleanup(deleteReceivedFiles: Boolean) {
        cancelTransfer()
        stopDiscovery()
        stopAdvertising()
        client.stopAllEndpoints()
        connectedEndpointId = null
        pendingEndpointId = null
        incomingFiles.clear()
        incomingMetadata.clear()
        completedIncoming.clear()
        incomingSizes.clear()
        incomingEndpointNames.clear()
        activeServiceId = null
        if (deleteReceivedFiles && ::context.isInitialized) {
            val transferDirectory = File(context.cacheDir, "nearby_worldcup_transfer")
            if (transferDirectory.parentFile == context.cacheDir && transferDirectory.exists()) {
                transferDirectory.deleteRecursively()
            }
        }
    }

    private val discoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            val name = info.endpointName.ifBlank { "이름 없는 기기" }
            discoveredEndpoints[endpointId] = name
            emit("endpointFound", mapOf("endpointId" to endpointId, "endpointName" to name))
        }

        override fun onEndpointLost(endpointId: String) {
            discoveredEndpoints.remove(endpointId)
            emit("endpointLost", mapOf("endpointId" to endpointId))
        }
    }

    private val connectionCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            val outgoing = pendingEndpointId == endpointId && !advertising
            if ((!advertising && !outgoing) ||
                (pendingEndpointId != null && pendingEndpointId != endpointId) ||
                connectedEndpointId != null
            ) {
                client.rejectConnection(endpointId)
                return
            }
            pendingEndpointId = endpointId
            val endpointName = info.endpointName.ifBlank {
                discoveredEndpoints[endpointId] ?: "이름 없는 기기"
            }
            incomingEndpointNames[endpointId] = endpointName
            emit(
                "connectionRequest",
                mapOf(
                    "endpointId" to endpointId,
                    "endpointName" to endpointName,
                    "incoming" to !outgoing,
                ),
            )
            emit(
                "verificationCode",
                mapOf(
                    "endpointId" to endpointId,
                    "endpointName" to endpointName,
                    "code" to info.authenticationDigits,
                ),
            )
        }

        override fun onConnectionResult(endpointId: String, resolution: ConnectionResolution) {
            pendingEndpointId = null
            if (resolution.status.statusCode == ConnectionsStatusCodes.STATUS_OK) {
                connectedEndpointId = endpointId
                stopDiscovery()
                stopAdvertising()
                emitConnection(endpointId, "connected")
            } else {
                emitConnection(endpointId, "rejected")
            }
        }

        override fun onDisconnected(endpointId: String) {
            if (connectedEndpointId == endpointId) connectedEndpointId = null
            if (pendingEndpointId == endpointId) pendingEndpointId = null
            outgoingPayload = null
            emitConnection(endpointId, "disconnected")
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            when (payload.type) {
                Payload.Type.BYTES -> {
                    val filePayloadId = parseMetadata(payload.asBytes())
                    if (filePayloadId != null) tryFinalizeIncoming(endpointId, filePayloadId)
                }
                Payload.Type.FILE -> {
                    incomingFiles[payload.id] = payload
                    tryFinalizeIncoming(endpointId, payload.id)
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            val isOutgoingFile = outgoingPayload?.id == update.payloadId
            val isIncomingFile = incomingFiles.containsKey(update.payloadId)
            if (!isOutgoingFile && !isIncomingFile) return
            val direction = if (isOutgoingFile) "sending" else "receiving"
            val status = when (update.status) {
                PayloadTransferUpdate.Status.IN_PROGRESS -> "inProgress"
                PayloadTransferUpdate.Status.SUCCESS -> "success"
                PayloadTransferUpdate.Status.CANCELED -> "canceled"
                else -> "failure"
            }
            if (direction == "receiving") {
                incomingSizes[update.payloadId] = update.bytesTransferred to update.totalBytes
            }
            emit(
                "transferProgress",
                mapOf(
                    "endpointId" to endpointId,
                    "payloadId" to update.payloadId.toString(),
                    "direction" to direction,
                    "status" to status,
                    "bytesTransferred" to update.bytesTransferred,
                    "totalBytes" to update.totalBytes,
                ),
            )
            when (update.status) {
                PayloadTransferUpdate.Status.SUCCESS -> {
                    if (direction == "sending") outgoingPayload = null
                    else completedIncoming += update.payloadId
                    tryFinalizeIncoming(endpointId, update.payloadId)
                }
                PayloadTransferUpdate.Status.CANCELED,
                PayloadTransferUpdate.Status.FAILURE -> {
                    if (direction == "sending") outgoingPayload = null
                    else clearIncoming(update.payloadId)
                }
                else -> Unit
            }
        }
    }

    private fun parseMetadata(bytes: ByteArray?): Long? {
        if (bytes == null) return null
        try {
            val json = JSONObject(bytes.toString(Charsets.UTF_8))
            if (json.optInt("version") != PROTOCOL_VERSION ||
                json.optString("kind") != "fileMetadata"
            ) return null
            val payloadId = json.getString("payloadId").toLong()
            incomingMetadata[payloadId] = FileMetadata(
                sanitizeName(json.getString("name")),
                json.getLong("size"),
            )
            return payloadId
        } catch (error: Exception) {
            emitError("protocol", "파일 메타데이터가 올바르지 않습니다.", false)
            return null
        }
    }

    private fun tryFinalizeIncoming(endpointId: String, payloadId: Long) {
        val payload = incomingFiles[payloadId] ?: return
        val metadata = incomingMetadata[payloadId] ?: return
        if (!completedIncoming.contains(payloadId)) return
        incomingFiles.remove(payloadId)
        incomingMetadata.remove(payloadId)
        completedIncoming.remove(payloadId)
        val progress = incomingSizes.remove(payloadId)
        ioExecutor.execute {
            val uri = payload.asFile()?.asUri()
            if (uri == null) {
                emitError("io", "수신 파일을 열 수 없습니다.", false)
                return@execute
            }
            val directory = File(context.cacheDir, "nearby_worldcup_transfer")
            val destination = File(directory, "${UUID.randomUUID()}.myworldcup")
            try {
                directory.mkdirs()
                context.contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) { "Missing received file stream" }
                    FileOutputStream(destination).use { output -> input.copyTo(output) }
                }
                if (!destination.isFile || destination.length() != metadata.size) {
                    destination.delete()
                    emitError("io", "수신 파일의 크기를 확인할 수 없습니다.", false)
                    return@execute
                }
                emit(
                    "fileReceived",
                    mapOf(
                        "endpointId" to endpointId,
                        "payloadId" to payloadId.toString(),
                        "path" to destination.absolutePath,
                        "name" to metadata.name,
                        "size" to destination.length(),
                    ),
                )
            } catch (error: Exception) {
                destination.delete()
                emitError("io", "수신 파일을 임시 저장소에 복사하지 못했습니다.", false)
            } finally {
                try {
                    context.contentResolver.delete(uri, null, null)
                } catch (_: Exception) {
                    // The provider can own cleanup; the app copy has already been handled.
                }
            }
        }
    }

    private fun clearIncoming(payloadId: Long) {
        incomingFiles.remove(payloadId)
        incomingMetadata.remove(payloadId)
        completedIncoming.remove(payloadId)
        incomingSizes.remove(payloadId)
    }

    private fun sanitizeName(name: String): String {
        val leaf = File(name).name.replace(Regex("[^A-Za-z0-9._가-힣 -]"), "_")
        val limited = leaf.take(100).ifBlank { "worldcup.myworldcup" }
        return if (limited.endsWith(".myworldcup", ignoreCase = true)) {
            limited
        } else {
            "$limited.myworldcup"
        }
    }

    private fun emitConnection(endpointId: String, state: String) {
        emit("connectionState", mapOf("endpointId" to endpointId, "state" to state))
    }

    private fun emitError(code: String, message: String, recoverable: Boolean) {
        emit(
            "error",
            mapOf("code" to code, "message" to message, "recoverable" to recoverable),
        )
    }

    private fun emit(type: String, values: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(
                mapOf("version" to PROTOCOL_VERSION, "type" to type) + values,
            )
        }
    }

    private fun failResult(
        result: MethodChannel.Result,
        code: String,
        message: String,
        error: Throwable,
    ) {
        val apiException = error as? ApiException
        val nativeStatusCode = apiException?.statusCode
        val nativeStatus = nativeStatusCode?.let {
            ConnectionsStatusCodes.getStatusCodeString(it)
        }
        Log.w(
            TAG,
            "$message code=$code nativeStatusCode=$nativeStatusCode nativeStatus=$nativeStatus",
            error,
        )
        result.error(
            code,
            message,
            mapOf(
                "nativeStatusCode" to nativeStatusCode,
                "nativeStatus" to nativeStatus,
                "nativeMessage" to error.localizedMessage,
            ),
        )
    }
}
