package com.videocallmodule

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class VideoCallModule : Module() {

    private var videoCallOperator: VideoCallOperatorImpl? = null

    companion object {
        private const val TAG = "VideoCallModule"
        private const val PERMISSION_REQUEST_CODE = 1001
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.INTERNET,
            Manifest.permission.RECORD_AUDIO
        )
    }

    override fun definition() = ModuleDefinition {
        Name("ExpoVideoCall")
        
        Events(
            "onStatusChanged",
            "onUserStateChanged", 
            "onParticipantStateChanged",
            "onError"
        )

        AsyncFunction("checkPermissions") {
            try {
                val context = appContext.reactContext ?: return@AsyncFunction mapOf(
                    "hasCameraPermission" to false,
                    "hasPhoneStatePermission" to false,
                    "hasInternetPermission" to false,
                    "hasRecordAudioPermission" to false
                )
                
                val hasCameraPermission = ContextCompat.checkSelfPermission(
                    context, Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED

                val hasPhoneStatePermission = ContextCompat.checkSelfPermission(
                    context, Manifest.permission.READ_PHONE_STATE
                ) == PackageManager.PERMISSION_GRANTED

                val hasInternetPermission = ContextCompat.checkSelfPermission(
                    context, Manifest.permission.INTERNET
                ) == PackageManager.PERMISSION_GRANTED

                val hasRecordAudioPermission = ContextCompat.checkSelfPermission(
                    context, Manifest.permission.RECORD_AUDIO
                ) == PackageManager.PERMISSION_GRANTED

                mapOf(
                    "hasCameraPermission" to hasCameraPermission,
                    "hasPhoneStatePermission" to hasPhoneStatePermission,
                    "hasInternetPermission" to hasInternetPermission,
                    "hasRecordAudioPermission" to hasRecordAudioPermission
                )
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to check permissions: ${e.message}")
                throw Exception("Failed to check permissions: ${e.message}")
            }
        }

        AsyncFunction("requestPermissions") {
            try {
                val activity = appContext.currentActivity
                if (activity == null) {
                    Log.e(TAG, "VideoCallModule - Activity not available for permission request")
                    return@AsyncFunction "denied"
                }

                ActivityCompat.requestPermissions(activity, REQUIRED_PERMISSIONS, PERMISSION_REQUEST_CODE)
                "requested"
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to request permissions: ${e.message}")
                throw Exception("Failed to request permissions: ${e.message}")
            }
        }

        AsyncFunction("startVideoCall") { credentials: Map<String, Any?>, promise: Promise ->
            try {
                val activity = appContext.currentActivity as? FragmentActivity
                if (activity == null) {
                    promise.reject("NO_ACTIVITY", "FragmentActivity not available", null)
                    return@AsyncFunction
                }

                val serverURL = credentials["serverURL"] as? String
                val wssURL = credentials["wssURL"] as? String
                val userID = credentials["userID"] as? String
                val transactionID = credentials["transactionID"] as? String
                val clientName = credentials["clientName"] as? String
                val idleTimeout = (credentials["idleTimeout"] as? String) ?: "30"

                if (serverURL == null || wssURL == null || userID == null || 
                    transactionID == null || clientName == null) {
                    promise.reject("MISSING_PARAMETERS", "Missing required parameters", null)
                    return@AsyncFunction
                }

                videoCallOperator = VideoCallOperatorImpl(
                    serverURL = serverURL,
                    wssURL = wssURL,
                    userID = userID,
                    transactionID = transactionID,
                    clientName = clientName,
                    idleTimeout = idleTimeout,
                    module = this@VideoCallModule,
                    onEvent = { eventName, params ->
                        sendEvent(eventName, params)
                    }
                )

                val isSDKAvailable = try {
                    Class.forName("io.udentify.android.vc.fragment.VCFragment")
                    true
                } catch (e: ClassNotFoundException) {
                    false
                }

                val success = videoCallOperator?.startVideoCall(activity) ?: false

                val result = mapOf(
                    "success" to success,
                    "status" to "connecting",
                    "transactionID" to transactionID
                )

                promise.resolve(result)

            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to start video call: ${e.message}")
                promise.reject("START_VIDEO_CALL_FAILED", "Failed to start video call: ${e.message}", e)
            }
        }

        AsyncFunction("endVideoCall") { promise: Promise ->
            try {
                val success = videoCallOperator?.endVideoCall() ?: false
                videoCallOperator = null

                val result = mapOf(
                    "success" to success,
                    "status" to "disconnected"
                )

                promise.resolve(result)
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to end video call: ${e.message}")
                promise.reject("END_VIDEO_CALL_FAILED", "Failed to end video call: ${e.message}", e)
            }
        }

        AsyncFunction("getVideoCallStatus") {
            try {
                videoCallOperator?.getStatus() ?: "idle"
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to get video call status: ${e.message}")
                throw Exception("Failed to get video call status: ${e.message}")
            }
        }

        AsyncFunction("setVideoCallConfig") { config: Map<String, Any?> ->
            try {
                val backgroundColor = config["backgroundColor"] as? String
                val textColor = config["textColor"] as? String
                val pipViewBorderColor = config["pipViewBorderColor"] as? String
                val notificationLabelDefault = config["notificationLabelDefault"] as? String
                val notificationLabelCountdown = config["notificationLabelCountdown"] as? String
                val notificationLabelTokenFetch = config["notificationLabelTokenFetch"] as? String

                videoCallOperator?.setConfig(
                    backgroundColor = backgroundColor,
                    textColor = textColor,
                    pipViewBorderColor = pipViewBorderColor,
                    notificationLabelDefault = notificationLabelDefault,
                    notificationLabelCountdown = notificationLabelCountdown,
                    notificationLabelTokenFetch = notificationLabelTokenFetch
                )
                
                null
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to set video call config: ${e.message}")
                throw Exception("Failed to set video call config: ${e.message}")
            }
        }

        AsyncFunction("toggleCamera") {
            try {
                videoCallOperator?.toggleCamera() ?: false
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to toggle camera: ${e.message}")
                false
            }
        }

        AsyncFunction("switchCamera") {
            try {
                videoCallOperator?.switchCamera() ?: false
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to switch camera: ${e.message}")
                false
            }
        }

        AsyncFunction("toggleMicrophone") {
            try {
                videoCallOperator?.toggleMicrophone() ?: false
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to toggle microphone: ${e.message}")
                false
            }
        }

        AsyncFunction("dismissVideoCall") {
            try {
                videoCallOperator?.dismissVideoCall()
                null
            } catch (e: Exception) {
                Log.e(TAG, "VideoCallModule - Failed to dismiss video call: ${e.message}")
                throw Exception("Failed to dismiss video call: ${e.message}")
            }
        }
        
        OnDestroy {
            videoCallOperator?.endVideoCall()
            videoCallOperator = null
        }
    }
}
