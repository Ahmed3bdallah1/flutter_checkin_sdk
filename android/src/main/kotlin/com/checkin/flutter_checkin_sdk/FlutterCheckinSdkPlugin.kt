package com.checkin.flutter_checkin_sdk

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.sdk.getidlib.app.common.receivers.BroadcastReceiverListener
import com.sdk.getidlib.config.GetIDSDK
import com.sdk.getidlib.model.app.auth.Key
import com.sdk.getidlib.model.app.auth.Token
import com.sdk.getidlib.model.app.document.DocumentEnum
import com.sdk.getidlib.model.app.metadata.Metadata as GetIdMetadata
import com.sdk.getidlib.model.entity.events.GetIDApplication
import com.sdk.getidlib.model.entity.events.GetIDError
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Flutter plugin bridging the Checkin.com (GetID) Android SDK. */
class FlutterCheckinSdkPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: Context

    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_INITIALIZE -> result.success(null)
            METHOD_START_VERIFICATION -> handleStartVerification(call.arguments, result)
            METHOD_CANCEL -> result.error(
                "UNSUPPORTED",
                "cancel() is not documented in the Checkin.com native SDK.",
                null,
            )
            else -> result.notImplemented()
        }
    }

    private fun handleStartVerification(arguments: Any?, result: Result) {
        val args = arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGUMENTS", "Verification arguments are required.", null)
            return
        }

        val apiUrl = args["apiUrl"] as? String
        val flowName = args["flowName"] as? String
        val auth = args["auth"] as? Map<*, *>

        if (apiUrl.isNullOrBlank() || flowName.isNullOrBlank() || auth == null) {
            result.error(
                "INVALID_CONFIGURATION",
                "apiUrl, flowName, and auth are required.",
                null,
            )
            return
        }

        val authType = auth["type"] as? String
        val authValue = auth["value"] as? String
        if (authType.isNullOrBlank() || authValue.isNullOrBlank()) {
            result.error("INVALID_CONFIGURATION", "Authentication type and value are required.", null)
            return
        }

        val context = activity?.applicationContext ?: applicationContext
        val locale = args["locale"] as? String
        val dictionary = args["dictionary"] as? String
        val profileData = (args["profileData"] as? Map<*, *>)?.mapNotNull { entry ->
            val key = entry.key as? String ?: return@mapNotNull null
            val value = entry.value as? String ?: return@mapNotNull null
            key to value
        }?.toMap()

        val metadata = parseMetadata(args["metadata"] as? Map<*, *>)
        val acceptableDocuments = parseAcceptableDocuments(args["acceptableDocuments"] as? Map<*, *>)

        val nativeAuth = when (authType) {
            "sdkKey" -> Key(authValue)
            "jwt" -> Token(authValue)
            else -> {
                result.error("INVALID_CONFIGURATION", "Unsupported auth type: $authType", null)
                return
            }
        }

        val eventListener = createEventListener()

        mainHandler.post {
            try {
                val sdk = GetIDSDK()
                sdk.startVerificationFlow(
                    context = context,
                    apiUrl = apiUrl,
                    auth = nativeAuth,
                    flowName = flowName,
                    metadata = metadata,
                    locale = locale,
                    profileData = profileData,
                    acceptableDocuments = acceptableDocuments,
                    dictionary = dictionary,
                    eventListener = eventListener,
                )
                result.success(null)
            } catch (error: Exception) {
                result.error(
                    "VERIFICATION_START_FAILED",
                    error.message ?: "Failed to start verification flow.",
                    error.toString(),
                )
            }
        }
    }

    private fun parseMetadata(raw: Map<*, *>?): GetIdMetadata? {
        if (raw == null) {
            return null
        }

        val externalId = when (val value = raw["externalId"]) {
            is String -> value
            is Number -> value.toString()
            else -> null
        }
        val labels = (raw["labels"] as? Map<*, *>)?.mapNotNull { entry ->
            val key = entry.key?.toString() ?: return@mapNotNull null
            val value = entry.value?.toString() ?: return@mapNotNull null
            key to value
        }?.toMap()

        if (externalId.isNullOrBlank() && labels.isNullOrEmpty()) {
            return null
        }

        return GetIdMetadata(
            externalId ?: "",
            labels ?: emptyMap(),
        )
    }

    private fun parseAcceptableDocuments(
        raw: Map<*, *>?,
    ): Map<String, List<DocumentEnum>>? {
        if (raw == null) {
            return null
        }

        val parsed = raw.mapNotNull { entry ->
            val country = entry.key as? String ?: return@mapNotNull null
            val documents = (entry.value as? List<*>)?.mapNotNull { value ->
                when (value as? String) {
                    "passport" -> DocumentEnum.PASSPORT
                    "idCard" -> DocumentEnum.ID_CARD
                    else -> null
                }
            } ?: emptyList()
            country to documents
        }.toMap()

        return parsed.ifEmpty { null }
    }

    private fun createEventListener(): BroadcastReceiverListener {
        return object : BroadcastReceiverListener {
            override fun verificationFlowStart() {
                emitEvent(
                    mapOf(
                        "type" to EVENT_VERIFICATION_STARTED,
                    ),
                )
            }

            override fun verificationFlowCancel() {
                emitEvent(
                    mapOf(
                        "type" to EVENT_VERIFICATION_CANCELLED,
                    ),
                )
            }

            override fun verificationFlowFail(error: GetIDError) {
                emitEvent(
                    mapOf(
                        "type" to EVENT_VERIFICATION_FAILED,
                        "error" to mapOf(
                            "code" to error.name,
                            "message" to errorMessage(error),
                            "nativeError" to error.name,
                        ),
                    ),
                )
            }

            override fun verificationFlowComplete(application: GetIDApplication) {
                emitEvent(
                    mapOf(
                        "type" to EVENT_VERIFICATION_COMPLETED,
                        "result" to mapOf(
                            "applicationId" to application.applicationId,
                        ),
                    ),
                )
            }
        }
    }

    private fun errorMessage(error: GetIDError): String {
        return when (error) {
            GetIDError.INVALID_KEY -> "Invalid SDK key."
            GetIDError.INVALID_TOKEN -> "Invalid JWT. It may have expired."
            GetIDError.FLOW_NOT_FOUND -> "No flow was found with the provided flowName."
            GetIDError.FAILED_TO_RECEIVE_CONFIGURATION ->
                "Failed to receive verification configuration from the server."
            GetIDError.UNSUPPORTED_SCHEMA_VERSION -> "The SDK version is outdated."
            GetIDError.CUSTOMER_ID_ALREADY_EXIST -> "An application with this customerId already exists."
            GetIDError.TOKEN_EXPIRED -> "The token has expired."
            GetIDError.DENY_PERMISSION -> "A required permission was denied."
            GetIDError.UNSUPPORTED_LIVENESS_VERSION -> "The SDK liveness version is outdated."
            GetIDError.INVALID_LIVENESS_TOKEN -> "Invalid liveness token."
            GetIDError.NO_NFC_SUPPORT -> "This device does not support NFC."
            GetIDError.FAILED_TO_SEND_APPLICATION -> "Failed to send application data to the server."
            GetIDError.UNEXPECTED_ERROR -> "An unexpected error occurred."
        }
    }

    private fun emitEvent(payload: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(payload)
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "flutter_checkin_sdk"
        private const val EVENT_CHANNEL = "flutter_checkin_sdk/events"

        private const val METHOD_INITIALIZE = "initialize"
        private const val METHOD_START_VERIFICATION = "startVerification"
        private const val METHOD_CANCEL = "cancel"

        private const val EVENT_VERIFICATION_STARTED = "verificationStarted"
        private const val EVENT_VERIFICATION_COMPLETED = "verificationCompleted"
        private const val EVENT_VERIFICATION_CANCELLED = "verificationCancelled"
        private const val EVENT_VERIFICATION_FAILED = "verificationFailed"
    }
}
