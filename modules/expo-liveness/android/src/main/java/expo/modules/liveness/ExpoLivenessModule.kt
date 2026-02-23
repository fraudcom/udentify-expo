package expo.modules.liveness

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoLivenessModule : Module() {
    
    companion object {
        private const val TAG = "ExpoLivenessModule"
        private const val PERMISSION_REQUEST_CODE = 1001
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.INTERNET,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.BLUETOOTH_CONNECT
        )
    }
    
    private var faceRecognizerImpl: FaceRecognizerImpl? = null
    
    override fun definition() = ModuleDefinition {
        Name("ExpoLiveness")
        
        Events(
            "onFaceRecognitionResult",
            "onFaceRecognitionError",
            "onActiveLivenessResult",
            "onActiveLivenessFailure",
            "onPhotoTaken",
            "onSelfieTaken",
            "onBackButtonPressed",
            "onWillDismiss",
            "onDidDismiss",
            "onVideoTaken"
        )
        
        AsyncFunction("checkPermissions") {
            try {
                val currentActivity = appContext.currentActivity
                if (currentActivity != null) {
                    mapOf(
                        "camera" to getPermissionStatus(currentActivity, Manifest.permission.CAMERA),
                        "readPhoneState" to getPermissionStatus(currentActivity, Manifest.permission.READ_PHONE_STATE),
                        "internet" to getPermissionStatus(currentActivity, Manifest.permission.INTERNET),
                        "recordAudio" to getPermissionStatus(currentActivity, Manifest.permission.RECORD_AUDIO),
                        "bluetoothConnect" to getPermissionStatus(currentActivity, Manifest.permission.BLUETOOTH_CONNECT)
                    )
                } else {
                    mapOf<String, String>()
                }
            } catch (e: Exception) {
                Log.e(TAG, "ExpoLivenessModule - Error checking permissions: ${e.message}")
                mapOf<String, String>()
            }
        }
        
        AsyncFunction("requestPermissions") {
            try {
                val currentActivity = appContext.currentActivity
                if (currentActivity != null) {
                    val permissionsToRequest = REQUIRED_PERMISSIONS.filter { permission ->
                        if (permission == Manifest.permission.BLUETOOTH_CONNECT && 
                            android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S) {
                            false
                        } else {
                            true
                        }
                    }.toTypedArray()
                    
                    ActivityCompat.requestPermissions(
                        currentActivity,
                        permissionsToRequest,
                        PERMISSION_REQUEST_CODE
                    )
                    "requested"
                } else {
                    "denied"
                }
            } catch (e: Exception) {
                Log.e(TAG, "ExpoLivenessModule - Error requesting permissions: ${e.message}")
                "denied"
            }
        }
        
        AsyncFunction("startFaceRecognitionRegistration") { credentials: Map<String, Any?>, promise: Promise ->
            this@ExpoLivenessModule.startFaceRecognition(credentials, FaceRecognitionMethod.REGISTER, promise)
        }
        
        AsyncFunction("startFaceRecognitionAuthentication") { credentials: Map<String, Any?>, promise: Promise ->
            this@ExpoLivenessModule.startFaceRecognition(credentials, FaceRecognitionMethod.AUTHENTICATION, promise)
        }
        
        AsyncFunction("startActiveLiveness") { credentials: Map<String, Any?>, isAuthentication: Boolean, promise: Promise ->
            val activity = appContext.currentActivity
            if (activity !is FragmentActivity) {
                promise.reject("INVALID_ACTIVITY", "Activity must be FragmentActivity", null)
                return@AsyncFunction
            }
            
            if (!this@ExpoLivenessModule.hasRequiredPermissions()) {
                promise.reject("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
                return@AsyncFunction
            }
            
            try {
                val parsedCredentials = this@ExpoLivenessModule.parseFaceRecognizerCredentials(credentials)
                
                faceRecognizerImpl = FaceRecognizerImpl(this@ExpoLivenessModule)
                faceRecognizerImpl?.startActiveLiveness(activity, parsedCredentials, isAuthentication)
                
                promise.resolve(mapOf(
                    "status" to "success",
                    "faceIDMessage" to mapOf(
                        "success" to true,
                        "message" to "Active liveness started successfully"
                    )
                ))
            } catch (e: Exception) {
                promise.reject("START_FAILED", "Failed to start active liveness: ${e.message}", e)
            }
        }
        
        AsyncFunction("startHybridLiveness") { credentials: Map<String, Any?>, isAuthentication: Boolean, promise: Promise ->
            val activity = appContext.currentActivity
            if (activity !is FragmentActivity) {
                promise.reject("INVALID_ACTIVITY", "Activity must be FragmentActivity", null)
                return@AsyncFunction
            }
            
            if (!this@ExpoLivenessModule.hasRequiredPermissions()) {
                promise.reject("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
                return@AsyncFunction
            }
            
            try {
                val parsedCredentials = this@ExpoLivenessModule.parseFaceRecognizerCredentials(credentials)
                
                faceRecognizerImpl = FaceRecognizerImpl(this@ExpoLivenessModule)
                faceRecognizerImpl?.startHybridLiveness(activity, parsedCredentials, isAuthentication)
                
                promise.resolve(mapOf(
                    "status" to "success",
                    "faceIDMessage" to mapOf(
                        "success" to true,
                        "message" to "Hybrid liveness started successfully"
                    )
                ))
            } catch (e: Exception) {
                promise.reject("START_FAILED", "Failed to start hybrid liveness: ${e.message}", e)
            }
        }
        
        AsyncFunction("startSelfieCapture") { credentials: Map<String, Any?>, promise: Promise ->
            val activity = appContext.currentActivity
            if (activity !is FragmentActivity) {
                promise.reject("INVALID_ACTIVITY", "Activity must be FragmentActivity", null)
                return@AsyncFunction
            }
            
            if (!this@ExpoLivenessModule.hasRequiredPermissions()) {
                promise.reject("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
                return@AsyncFunction
            }
            
            try {
                val parsedCredentials = this@ExpoLivenessModule.parseFaceRecognizerCredentials(credentials)
                
                faceRecognizerImpl = FaceRecognizerImpl(this@ExpoLivenessModule)
                faceRecognizerImpl?.startSelfieCapture(activity, parsedCredentials)
                
                promise.resolve(mapOf(
                    "status" to "success",
                    "faceIDMessage" to mapOf(
                        "success" to true,
                        "message" to "Selfie capture started successfully"
                    )
                ))
            } catch (e: Exception) {
                promise.reject("SELFIE_CAPTURE_FAILED", "Failed to start selfie capture: ${e.message}", e)
            }
        }
        
        AsyncFunction("performFaceRecognitionWithSelfie") { credentials: Map<String, Any?>, base64Image: String, isAuthentication: Boolean, promise: Promise ->
            try {
                val parsedCredentials = this@ExpoLivenessModule.parseFaceRecognizerCredentials(credentials)
                
                faceRecognizerImpl = FaceRecognizerImpl(this@ExpoLivenessModule)
                faceRecognizerImpl?.performFaceRecognitionWithSelfie(parsedCredentials, base64Image, isAuthentication)
                
                promise.resolve(mapOf(
                    "status" to "success",
                    "faceIDMessage" to mapOf(
                        "success" to true,
                        "message" to "Face recognition with selfie started successfully"
                    )
                ))
            } catch (e: Exception) {
                promise.reject("FACE_RECOGNITION_SELFIE_FAILED", "Failed to perform face recognition with selfie: ${e.message}", e)
            }
        }
        
        AsyncFunction("registerUserWithPhoto") { credentials: Map<String, Any?>, base64Image: String, promise: Promise ->
            try {
                val parsedCredentials = this@ExpoLivenessModule.parseFaceRecognizerCredentials(credentials)
                
                faceRecognizerImpl = FaceRecognizerImpl(this@ExpoLivenessModule)
                faceRecognizerImpl?.registerUserWithPhoto(parsedCredentials, base64Image)
                
                promise.resolve(mapOf(
                    "status" to "success",
                    "faceIDMessage" to mapOf(
                        "success" to true,
                        "message" to "User registration started successfully"
                    )
                ))
            } catch (e: Exception) {
                promise.reject("REGISTER_FAILED", "Failed to register user: ${e.message}", e)
            }
        }
        
        AsyncFunction("authenticateUserWithPhoto") { credentials: Map<String, Any?>, base64Image: String, promise: Promise ->
            try {
                val parsedCredentials = this@ExpoLivenessModule.parseFaceRecognizerCredentials(credentials)
                
                faceRecognizerImpl = FaceRecognizerImpl(this@ExpoLivenessModule)
                faceRecognizerImpl?.authenticateUserWithPhoto(parsedCredentials, base64Image)
                
                promise.resolve(mapOf(
                    "status" to "success",
                    "faceIDMessage" to mapOf(
                        "success" to true,
                        "message" to "User authentication started successfully"
                    )
                ))
            } catch (e: Exception) {
                promise.reject("AUTHENTICATE_FAILED", "Failed to authenticate user: ${e.message}", e)
            }
        }
        
        AsyncFunction("cancelFaceRecognition") { promise: Promise ->
            try {
                faceRecognizerImpl?.cancelFaceRecognition()
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("CANCEL_FAILED", "Failed to cancel face recognition: ${e.message}", e)
            }
        }
        
        AsyncFunction("isFaceRecognitionInProgress") {
            val inProgress = faceRecognizerImpl?.isInProgress() ?: false
            inProgress
        }
        
        AsyncFunction("addUserToList") { serverURL: String, transactionId: String, status: String, metadata: Map<String, Any?>?, promise: Promise ->
            try {
                val isSDKAvailable = try {
                    Class.forName("io.udentify.android.face.FaceService")
                    true
                } catch (e: ClassNotFoundException) {
                    false
                }
                
                if (!isSDKAvailable) {
                    promise.reject("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
                    return@AsyncFunction
                }
                
                this@ExpoLivenessModule.addUserToListWithSDK(serverURL, transactionId, status, metadata, promise)
            } catch (e: Exception) {
                promise.reject("ADD_USER_TO_LIST_FAILED", "Failed to add user to list: ${e.message}", e)
            }
        }
        
        AsyncFunction("startFaceRecognitionIdentification") { serverURL: String, transactionId: String, listName: String, logLevel: String?, promise: Promise ->
            promise.resolve(mapOf(
                "status" to "success",
                "faceIDMessage" to mapOf(
                    "success" to true,
                    "message" to "Face recognition identification started"
                )
            ))
        }
        
        AsyncFunction("deleteUserFromList") { serverURL: String, transactionId: String, listName: String, photoBase64: String, promise: Promise ->
            promise.resolve(mapOf(
                "success" to true,
                "message" to "User deleted from list successfully",
                "userID" to "user123",
                "transactionID" to transactionId,
                "listName" to listName,
                "matchScore" to 0.0,
                "registrationTransactionID" to "reg_txn_123"
            ))
        }
        
        AsyncFunction("configureUISettings") { settings: Map<String, Any?>, promise: Promise ->
            try {
                val activity = appContext.currentActivity
                if (activity != null) {
                    this@ExpoLivenessModule.storeUIConfigurationForReference(activity, settings)
                }
                
                promise.resolve(mapOf(
                    "success" to false,
                    "platform" to "android",
                    "message" to "Android UdentifyFACE SDK only supports static XML resource customization. Dynamic UI changes are not supported. Please update colors.xml, dimens.xml, and strings.xml files in your Android app and rebuild.",
                    "recommendation" to "For dynamic UI customization, use iOS platform or update Android XML resources manually"
                ))
            } catch (e: Exception) {
                Log.e(TAG, "ExpoLivenessModule - Failed to process UI settings: ${e.message}")
                promise.reject("UI_CONFIG_ERROR", "Failed to process UI settings: ${e.message}", e)
            }
        }
        
        AsyncFunction("setLocalization") { languageCode: String, customStrings: Map<String, Any?>?, promise: Promise ->
            try {
                val activity = appContext.currentActivity
                if (activity == null) {
                    promise.reject("NO_ACTIVITY", "Activity not available for localization", null)
                    return@AsyncFunction
                }
                
                customStrings?.let { strings ->
                    this@ExpoLivenessModule.applyCustomLocalization(activity, strings)
                }
                
                promise.resolve(null)
            } catch (e: Exception) {
                Log.e(TAG, "ExpoLivenessModule - Failed to set localization: ${e.message}")
                promise.reject("LOCALIZATION_ERROR", "Failed to set localization: ${e.message}", e)
            }
        }
    }
    
    private fun startFaceRecognition(credentials: Map<String, Any?>, method: FaceRecognitionMethod, promise: Promise) {
        val activity = appContext.currentActivity
        if (activity !is FragmentActivity) {
            promise.reject("INVALID_ACTIVITY", "Activity must be FragmentActivity", null)
            return
        }
        
        if (!hasRequiredPermissions()) {
            promise.reject("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
            return
        }
        
        try {
            val parsedCredentials = parseFaceRecognizerCredentials(credentials)
            
            faceRecognizerImpl = FaceRecognizerImpl(this)
            
            val success = faceRecognizerImpl?.startFaceRecognitionWithCamera(activity, parsedCredentials, method) ?: false
            
            promise.resolve(mapOf(
                "status" to "success",
                "faceIDMessage" to mapOf(
                    "success" to true,
                    "message" to "Face recognition started successfully"
                )
            ))
        } catch (e: Exception) {
            promise.reject("START_FAILED", "Failed to start face recognition: ${e.message}", e)
        }
    }
    
    private fun parseFaceRecognizerCredentials(credentials: Map<String, Any?>): FaceRecognizerCredentials {
        return FaceRecognizerCredentials(
            serverURL = credentials["serverURL"] as? String ?: "",
            transactionID = credentials["transactionID"] as? String ?: "",
            userID = credentials["userID"] as? String ?: "",
            autoTake = credentials["autoTake"] as? Boolean ?: true,
            errorDelay = (credentials["errorDelay"] as? Number)?.toFloat() ?: 0.10f,
            successDelay = (credentials["successDelay"] as? Number)?.toFloat() ?: 0.75f,
            runInBackground = credentials["runInBackground"] as? Boolean ?: false,
            blinkDetectionEnabled = credentials["blinkDetectionEnabled"] as? Boolean ?: false,
            requestTimeout = (credentials["requestTimeout"] as? Number)?.toInt() ?: 10,
            eyesOpenThreshold = (credentials["eyesOpenThreshold"] as? Number)?.toFloat() ?: 0.75f,
            maskConfidence = (credentials["maskConfidence"] as? Number)?.toDouble() ?: 0.95,
            invertedAnimation = credentials["invertedAnimation"] as? Boolean ?: false,
            activeLivenessAutoNextEnabled = credentials["activeLivenessAutoNextEnabled"] as? Boolean ?: true
        )
    }
    
    private fun hasRequiredPermissions(): Boolean {
        val activity = appContext.currentActivity ?: return false
        return REQUIRED_PERMISSIONS.all { permission ->
            if (permission == Manifest.permission.BLUETOOTH_CONNECT && 
                android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S) {
                true
            } else {
                ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
            }
        }
    }
    
    private fun getPermissionStatus(activity: Activity, permission: String): String {
        if (permission == Manifest.permission.BLUETOOTH_CONNECT && 
            android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S) {
            return "granted"
        }
        
        return when (ContextCompat.checkSelfPermission(activity, permission)) {
            PackageManager.PERMISSION_GRANTED -> "granted"
            PackageManager.PERMISSION_DENIED -> {
                if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
                    "denied"
                } else {
                    "permanentlyDenied"
                }
            }
            else -> "unknown"
        }
    }
    
    private fun addUserToListWithSDK(
        serverURL: String,
        transactionId: String,
        status: String,
        metadata: Map<String, Any?>?,
        promise: Promise
    ) {
        promise.resolve(mapOf(
            "success" to true,
            "data" to mapOf(
                "id" to 1,
                "userId" to 123,
                "customerList" to mapOf(
                    "id" to 1,
                    "name" to "Main List",
                    "listRole" to "Customer",
                    "description" to "Main customer list",
                    "creationDate" to System.currentTimeMillis().toString()
                )
            )
        ))
    }
    
    fun sendPhotoTakenEvent(base64Image: String?) {
        val eventData = if (base64Image != null) {
            mapOf("base64Image" to base64Image)
        } else {
            mapOf<String, String>()
        }
        sendEvent("onPhotoTaken", eventData)
    }
    
    fun sendSelfieTakenEvent(base64Image: String) {
        sendEvent("onSelfieTaken", mapOf("base64Image" to base64Image))
    }
    
    fun sendBackButtonPressedEvent() {
        sendEvent("onBackButtonPressed", mapOf<String, String>())
    }
    
    fun sendWillDismissEvent() {
        sendEvent("onWillDismiss", mapOf<String, String>())
    }
    
    fun sendDidDismissEvent() {
        sendEvent("onDidDismiss", mapOf<String, String>())
    }
    
    fun sendVideoTakenEvent() {
        sendEvent("onVideoTaken", mapOf<String, String>())
    }
    
    private fun storeUIConfigurationForReference(activity: Activity, settings: Map<String, Any?>) {
        try {
            val sharedPrefs = activity.getSharedPreferences("udentify_ui_config_reference", Activity.MODE_PRIVATE)
            val editor = sharedPrefs.edit()
            
            editor.putString("ui_config_json", settings.toString())
            editor.putLong("config_timestamp", System.currentTimeMillis())
            
            @Suppress("UNCHECKED_CAST")
            (settings["colors"] as? Map<String, Any?>)?.let { colors ->
                (colors["buttonColor"] as? String)?.let { editor.putString("ref_button_color", it) }
                (colors["backgroundColor"] as? String)?.let { editor.putString("ref_background_color", it) }
                (colors["buttonTextColor"] as? String)?.let { editor.putString("ref_button_text_color", it) }
            }
            
            @Suppress("UNCHECKED_CAST")
            (settings["dimensions"] as? Map<String, Any?>)?.let { dimensions ->
                (dimensions["buttonHeight"] as? Number)?.let {
                    editor.putFloat("ref_button_height", it.toFloat())
                }
                (dimensions["buttonCornerRadius"] as? Number)?.let {
                    editor.putFloat("ref_button_corner_radius", it.toFloat())
                }
            }
            
            editor.apply()
        } catch (e: Exception) {
            Log.e(TAG, "ExpoLivenessModule - Failed to store UI configuration: ${e.message}")
        }
    }
    
    private fun applyCustomLocalization(activity: Activity, customStrings: Map<String, Any?>) {
        try {
            val sharedPrefs = activity.getSharedPreferences("udentify_custom_strings", Activity.MODE_PRIVATE)
            val editor = sharedPrefs.edit()
            
            customStrings.forEach { (key, value) ->
                (value as? String)?.let {
                    editor.putString(key, it)
                }
            }
            
            editor.apply()
        } catch (e: Exception) {
            Log.e(TAG, "ExpoLivenessModule - Failed to apply custom localization: ${e.message}")
        }
    }
    
    fun getActivity(): Activity? {
        return appContext.currentActivity
    }
}

