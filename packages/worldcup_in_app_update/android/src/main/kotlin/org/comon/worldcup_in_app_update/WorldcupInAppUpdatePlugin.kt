package org.comon.worldcup_in_app_update

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.ActivityResult
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Google Play In-App Update의 유연한(Flexible) 업데이트만 다루는 플러그인.
 *
 * 즉시(Immediate) 업데이트는 앱 사용 흐름을 끊으므로 의도적으로 노출하지 않는다.
 */
class WorldcupInAppUpdatePlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    companion object {
        private const val PROTOCOL_VERSION = 1
        private const val METHODS = "org.comon.my_worldcup_local/in_app_update/methods"
        private const val EVENTS = "org.comon.my_worldcup_local/in_app_update/events"
        private const val TAG = "WorldcupInAppUpdate"

        /** 동의 화면 결과를 되돌려 받는 요청 코드. 앱의 다른 코드와 겹치지 않게 고른 값이다. */
        private const val UPDATE_REQUEST = 7462
    }

    private lateinit var context: Context
    private lateinit var manager: AppUpdateManager
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private val mainHandler = Handler(Looper.getMainLooper())
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null

    /** 동의 화면이 떠 있는 동안 답을 미뤄 둔 호출. onActivityResult에서만 응답한다. */
    private var pendingFlowResult: MethodChannel.Result? = null

    private val installListener = InstallStateUpdatedListener { state -> emit(state) }
    private var listenerRegistered = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        manager = AppUpdateManagerFactory.create(context)
        methodChannel = MethodChannel(binding.binaryMessenger, METHODS)
        eventChannel = EventChannel(binding.binaryMessenger, EVENTS)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterInstallListener()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        // 동의 화면 결과를 받을 채널이 사라졌으므로 대기 중인 호출을 정리한다.
        finishPendingFlow("failed")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        detachActivity()
        // 화면이 사라지면 결과가 영영 오지 않는다. Dart가 무한정 기다리지 않게 닫아 준다.
        finishPendingFlow("canceled")
    }

    private fun detachActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    // --- EventChannel -------------------------------------------------------

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (!hasValidVersion(arguments)) {
            events?.error("protocol", "지원하지 않는 인앱 업데이트 프로토콜 버전입니다.", null)
            return
        }
        eventSink = events
        registerInstallListener()
    }

    override fun onCancel(arguments: Any?) {
        unregisterInstallListener()
        eventSink = null
    }

    private fun registerInstallListener() {
        if (listenerRegistered) return
        manager.registerListener(installListener)
        listenerRegistered = true
    }

    private fun unregisterInstallListener() {
        if (!listenerRegistered) return
        manager.unregisterListener(installListener)
        listenerRegistered = false
    }

    private fun emit(state: InstallState) {
        val payload = mapOf(
            "version" to PROTOCOL_VERSION,
            "status" to installStatusName(state.installStatus()),
            "bytesDownloaded" to state.bytesDownloaded(),
            "totalBytesToDownload" to state.totalBytesToDownload(),
            "errorCode" to state.installErrorCode(),
        )
        mainHandler.post { eventSink?.success(payload) }
    }

    // --- MethodChannel ------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.argument<Int>("version") != PROTOCOL_VERSION) {
            result.error("protocol", "지원하지 않는 인앱 업데이트 프로토콜 버전입니다.", null)
            return
        }
        when (call.method) {
            "checkForUpdate" -> checkForUpdate(result)
            "startFlexibleUpdate" -> startFlexibleUpdate(result)
            "completeUpdate" -> completeUpdate(result)
            else -> result.notImplemented()
        }
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        manager.appUpdateInfo
            .addOnSuccessListener { info -> result.success(infoToMap(info)) }
            .addOnFailureListener { error ->
                Log.w(TAG, "업데이트 정보를 가져오지 못했습니다.", error)
                result.error("update_check_failed", error.message, null)
            }
    }

    private fun startFlexibleUpdate(result: MethodChannel.Result) {
        val activity = this.activity
        if (activity == null) {
            result.error("no_activity", "화면이 없어 업데이트 동의 창을 띄울 수 없습니다.", null)
            return
        }
        if (pendingFlowResult != null) {
            result.error("already_in_progress", "이미 업데이트 동의 창이 떠 있습니다.", null)
            return
        }

        // Play는 한 번 받은 AppUpdateInfo로 흐름을 한 번만 띄울 수 있어서,
        // 조회 결과를 캐시하지 않고 시작 직전에 새로 받아 온다.
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE ||
                    !info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                ) {
                    result.success("unavailable")
                    return@addOnSuccessListener
                }
                pendingFlowResult = result
                try {
                    val started = manager.startUpdateFlowForResult(
                        info,
                        activity,
                        AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                        UPDATE_REQUEST,
                    )
                    if (!started) finishPendingFlow("failed")
                } catch (error: IntentSender.SendIntentException) {
                    Log.w(TAG, "업데이트 동의 창을 띄우지 못했습니다.", error)
                    finishPendingFlow("failed")
                }
            }
            .addOnFailureListener { error ->
                Log.w(TAG, "업데이트 정보를 가져오지 못했습니다.", error)
                result.error("update_check_failed", error.message, null)
            }
    }

    private fun completeUpdate(result: MethodChannel.Result) {
        manager.completeUpdate()
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { error ->
                Log.w(TAG, "업데이트 설치를 시작하지 못했습니다.", error)
                result.error("complete_update_failed", error.message, null)
            }
    }

    // --- Activity result ----------------------------------------------------

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != UPDATE_REQUEST) return false
        finishPendingFlow(
            when (resultCode) {
                Activity.RESULT_OK -> "accepted"
                Activity.RESULT_CANCELED -> "canceled"
                ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> "failed"
                else -> "failed"
            }
        )
        return true
    }

    /** 대기 중인 호출에 한 번만 응답한다. 두 번 응답하면 Flutter가 예외를 던진다. */
    private fun finishPendingFlow(outcome: String) {
        val pending = pendingFlowResult ?: return
        pendingFlowResult = null
        pending.success(outcome)
    }

    // --- 변환 ----------------------------------------------------------------

    private fun infoToMap(info: AppUpdateInfo): Map<String, Any?> {
        val versionCode = info.availableVersionCode()
        return mapOf(
            "version" to PROTOCOL_VERSION,
            "availability" to availabilityName(info.updateAvailability()),
            "installStatus" to installStatusName(info.installStatus()),
            "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
            "availableVersionCode" to if (versionCode > 0) versionCode else null,
            "clientVersionStalenessDays" to info.clientVersionStalenessDays(),
            "updatePriority" to info.updatePriority(),
        )
    }

    private fun availabilityName(value: Int): String = when (value) {
        UpdateAvailability.UPDATE_NOT_AVAILABLE -> "notAvailable"
        UpdateAvailability.UPDATE_AVAILABLE -> "available"
        UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS -> "inProgress"
        else -> "unknown"
    }

    private fun installStatusName(value: Int): String = when (value) {
        InstallStatus.REQUIRES_UI_INTENT -> "requiresUiIntent"
        InstallStatus.PENDING -> "pending"
        InstallStatus.DOWNLOADING -> "downloading"
        InstallStatus.DOWNLOADED -> "downloaded"
        InstallStatus.INSTALLING -> "installing"
        InstallStatus.INSTALLED -> "installed"
        InstallStatus.FAILED -> "failed"
        InstallStatus.CANCELED -> "canceled"
        else -> "unknown"
    }

    private fun hasValidVersion(arguments: Any?): Boolean {
        val map = arguments as? Map<*, *> ?: return false
        return (map["version"] as? Int) == PROTOCOL_VERSION
    }
}
