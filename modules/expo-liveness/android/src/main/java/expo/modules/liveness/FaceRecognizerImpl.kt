package expo.modules.liveness

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.fragment.app.FragmentActivity

class FaceRecognizerImpl(
    private val livenessModule: ExpoLivenessModule
) {
    private var inProgress: Boolean = false
    private var currentActivity: FragmentActivity? = null
    private var currentCredentials: FaceRecognizerCredentials? = null
    
    companion object {
        private const val TAG = "FaceRecognizerImpl"
    }

    fun isInProgress(): Boolean = inProgress

    fun cancelFaceRecognition() {
        inProgress = false
    }

    fun startFaceRecognitionWithCamera(activity: FragmentActivity, credentials: FaceRecognizerCredentials, method: FaceRecognitionMethod): Boolean {
        currentActivity = activity
        currentCredentials = credentials
        return try {
            
            // Use reflection to access the SDK classes
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodConst = when (method) {
                FaceRecognitionMethod.REGISTER -> methodEnum.getField("Register").get(null)
                FaceRecognitionMethod.AUTHENTICATION -> methodEnum.getField("Authentication").get(null)
            }

            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials(credentials)
            
            // Create proxy for FaceRecognizer callbacks
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onResult" -> {
                        val serverResponse = args?.getOrNull(0)
                        val detailedResponse = extractResponseData(serverResponse)
                        
                        val resultMap = createResultMap(
                            success = true,
                            message = "Face ${method.name.lowercase()} completed successfully",
                            data = detailedResponse
                        )
                        
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionResult", resultMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("face_camera_fragment")
                            }, 100)
                        }
                    }
                    "onFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Unknown error"
                        Log.e(TAG, "FaceRecognizerImpl - Face recognition failed: $errorMessage")
                        
                        val errorMap = mapOf(
                            "code" to "FACE_RECOGNITION_ERROR",
                            "message" to errorMessage
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionError", errorMap)
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("face_camera_fragment")
                            }, 100)
                        }
                        inProgress = false
                    }
                    "onPhotoTaken" -> {
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onPhotoTaken", mapOf())
                        }
                    }
                    "onSelfieTaken" -> {
                        val base64 = args?.getOrNull(0)?.toString()
                        Handler(Looper.getMainLooper()).post {
                            val selfieMap = mapOf("base64Image" to (base64 ?: ""))
                            livenessModule.sendEvent("onSelfieTaken", selfieMap)
                        }
                    }
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.FaceCameraFragment")
            val newInstance = fragmentClass.getMethod("newInstance", methodEnum, faceRecognizerInterface)
            val fragment = newInstance.invoke(null, methodConst, recognizer) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "face_camera_fragment")
                .addToBackStack("face_camera_fragment")
                .commit()
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to start face recognition with camera", e)
            false
        }
    }
    
    fun startActiveLiveness(activity: FragmentActivity, credentials: FaceRecognizerCredentials, isAuthentication: Boolean = false): Boolean {
        currentActivity = activity
        currentCredentials = credentials

        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodFieldName = "ActiveLiveness"
            val methodConst = methodEnum.getField(methodFieldName).get(null)
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val activeLivenessOperatorInterface = Class.forName("io.udentify.android.face.activities.ActiveLivenessOperator")

            val credsObj = buildFaceCredentials(credentials)

            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                    else -> null
                }
            }

            val activeLivenessOperator = java.lang.reflect.Proxy.newProxyInstance(
                activeLivenessOperatorInterface.classLoader,
                arrayOf(activeLivenessOperatorInterface)
            ) { _, m, args ->
                when (m.name) {
                    "activeLivenessResult" -> {
                        val faceIDMessage = args?.getOrNull(0)
                        val extractedData = extractResponseData(faceIDMessage)
                        val resultMap = createActiveLivenessResultMap(extractedData)
                        
                        Handler(Looper.getMainLooper()).post {
                            livenessModule.sendEvent("onActiveLivenessResult", resultMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("active_liveness_fragment")
                            }, 100)
                        }
                        Unit
                    }
                    "activeLivenessFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Active Liveness failed"
                        Log.e(TAG, "FaceRecognizerImpl - Active Liveness failed: $errorMessage")
                        
                        val errorMap = mapOf(
                            "code" to "ACTIVE_LIVENESS_ERROR",
                            "message" to errorMessage
                        )
                        
                        Handler(Looper.getMainLooper()).post {
                            livenessModule.sendEvent("onActiveLivenessFailure", errorMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("active_liveness_fragment")
                            }, 100)
                        }
                        Unit
                    }
                    else -> null
                }
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.ActiveLivenessFragment")
            val newInstanceMethod = fragmentClass.getMethod(
                "newInstance",
                methodEnum,
                Boolean::class.javaObjectType,
                faceRecognizerInterface,
                activeLivenessOperatorInterface
            )
            
            val fragment = newInstanceMethod.invoke(
                null,
                methodConst,
                isAuthentication,
                recognizer,
                activeLivenessOperator
            ) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "active_liveness_fragment")
                .addToBackStack("active_liveness_fragment")
                .commitAllowingStateLoss()
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to start active liveness", e)
            false
        }
    }
    
    fun startHybridLiveness(activity: FragmentActivity, credentials: FaceRecognizerCredentials, isAuthentication: Boolean = false): Boolean {
        currentActivity = activity
        currentCredentials = credentials
        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodFieldName = "HybridLiveness"
            val methodConst = methodEnum.getField(methodFieldName).get(null)

            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val activeOpInterface = Class.forName("io.udentify.android.face.activities.ActiveLivenessOperator")
            val credsObj = buildFaceCredentials(credentials)
            
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                    else -> null
                }
            }

            val activeOperator = java.lang.reflect.Proxy.newProxyInstance(
                activeOpInterface.classLoader,
                arrayOf(activeOpInterface)
            ) { _, m, args ->
                when (m.name) {
                    "activeLivenessResult" -> {
                        val faceIDMessage = args?.getOrNull(0)
                        val extractedData = extractResponseData(faceIDMessage)
                        val resultMap = createHybridLivenessResultMap(extractedData)
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onActiveLivenessResult", resultMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("hybrid_liveness_fragment")
                            }, 100)
                        }
                        Unit
                    }
                    "activeLivenessFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Hybrid liveness failed"
                        Log.e(TAG, "FaceRecognizerImpl - Hybrid Liveness failed: $errorMessage")
                        
                        val errorMap = mapOf(
                            "code" to "HYBRID_LIVENESS_ERROR",
                            "message" to errorMessage
                        )
                        
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onActiveLivenessFailure", errorMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("hybrid_liveness_fragment")
                            }, 100)
                        }
                        Unit
                    }
                }
                null
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.ActiveLivenessFragment")
            val newInstance = fragmentClass.getMethod(
                "newInstance",
                methodEnum,
                Boolean::class.javaObjectType,
                faceRecognizerInterface,
                activeOpInterface
            )
            val fragment = newInstance.invoke(
                null,
                methodConst,
                isAuthentication,
                recognizer,
                activeOperator
            ) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "hybrid_liveness_fragment")
                .addToBackStack("hybrid_liveness_fragment")
                .commit()
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to start hybrid liveness", e)
            false
        }
    }
    
    fun registerUserWithPhoto(credentials: FaceRecognizerCredentials, base64Image: String): Boolean {
        return try {
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials(credentials)
            
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onResult" -> {
                        val resultMap = createResultMap(
                            success = true,
                            message = "Photo registration completed successfully",
                            data = emptyMap()
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionResult", resultMap)
                        }
                        inProgress = false
                    }
                    "onFailure" -> {
                        val errorMap = mapOf(
                            "code" to "PHOTO_REGISTRATION_ERROR",
                            "message" to (args?.getOrNull(0)?.toString() ?: "Photo registration failed")
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionError", errorMap)
                        }
                        inProgress = false
                    }
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            // Use the current activity if available, otherwise this won't work
            val activity = currentActivity ?: return false
            
            val clazz = Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
            val ctor = clazz.getConstructor(faceRecognizerInterface, android.app.Activity::class.java, String::class.java)
            val instance = ctor.newInstance(recognizer, activity, base64Image)
            val registerMethod = clazz.getMethod("registerUser")
            registerMethod.invoke(instance)
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to register user with photo", e)
            false
        }
    }

    fun startSelfieCapture(activity: FragmentActivity, credentials: FaceRecognizerCredentials): Boolean {
        currentActivity = activity
        currentCredentials = credentials
        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodConst = methodEnum.getField("Selfie").get(null)

            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials(credentials)
            
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onSelfieTaken" -> {
                        val base64 = args?.getOrNull(0)?.toString()
                        
                        Handler(Looper.getMainLooper()).post {
                            val selfieMap = mapOf("base64Image" to (base64 ?: ""))
                            livenessModule.sendEvent("onSelfieTaken", selfieMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("selfie_camera_fragment")
                            }, 100)
                        }
                    }
                    "onFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Selfie capture failed"
                        Log.e(TAG, "FaceRecognizerImpl - Selfie capture failed: $errorMessage")
                        
                        val errorMap = mapOf(
                            "code" to "SELFIE_CAPTURE_ERROR",
                            "message" to errorMessage
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionError", errorMap)
                            inProgress = false
                            
                            Handler(Looper.getMainLooper()).postDelayed({
                                dismissCurrentFragment("selfie_camera_fragment")
                            }, 100)
                        }
                    }
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.FaceCameraFragment")
            val newInstance = fragmentClass.getMethod("newInstance", methodEnum, faceRecognizerInterface)
            val fragment = newInstance.invoke(null, methodConst, recognizer) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "selfie_camera_fragment")
                .addToBackStack("selfie_camera_fragment")
                .commit()
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to start selfie capture", e)
            false
        }
    }

    fun performFaceRecognitionWithSelfie(credentials: FaceRecognizerCredentials, base64Image: String, isAuthentication: Boolean): Boolean {
        currentCredentials = credentials
        return try {
            val method = if (isAuthentication) FaceRecognitionMethod.AUTHENTICATION else FaceRecognitionMethod.REGISTER
            
            val activity = livenessModule.getActivity() ?: run {
                Log.e(TAG, "FaceRecognizerImpl - No current activity available")
                val errorMap = mapOf(
                    "code" to "NO_ACTIVITY_CONTEXT",
                    "message" to "No activity context available for selfie processing"
                )
                Handler(Looper.getMainLooper()).post { 
                    livenessModule.sendEvent("onFaceRecognitionError", errorMap)
                }
                return false
            }
            
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials(credentials)
            
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onResult" -> {
                        try {
                            val serverResponse = args?.getOrNull(0)
                            val detailedResponse = extractResponseData(serverResponse)
                            
                            val resultMap = createSelfieRecognitionResultMap(
                                success = true,
                                message = "Face ${method.name.lowercase()} with selfie completed successfully",
                                data = detailedResponse,
                                isAuthentication = isAuthentication
                            )
                            
                            Handler(Looper.getMainLooper()).post { 
                                livenessModule.sendEvent("onFaceRecognitionResult", resultMap)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "FaceRecognizerImpl - Exception in onResult callback: ${e.message}", e)
                            Handler(Looper.getMainLooper()).post { 
                                val fallbackResult = mapOf(
                                    "status" to "success",
                                    "message" to "Face recognition completed successfully"
                                )
                                livenessModule.sendEvent("onFaceRecognitionResult", fallbackResult)
                            }
                        } finally {
                            inProgress = false
                        }
                    }
                    "onFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Face recognition with selfie failed"
                        Log.e(TAG, "FaceRecognizerImpl - Face recognition with selfie failed: $errorMessage")
                        
                        val errorMap = mapOf(
                            "code" to "FACE_RECOGNITION_SELFIE_ERROR",
                            "message" to errorMessage
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionError", errorMap)
                        }
                        inProgress = false
                    }
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val clazz = Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
            val ctor = clazz.getConstructor(faceRecognizerInterface, android.app.Activity::class.java, String::class.java)
            val faceRecognizerObject = ctor.newInstance(recognizer, activity, base64Image)
            
            if (isAuthentication) {
                val authMethod = clazz.getMethod("authenticateUser")
                authMethod.invoke(faceRecognizerObject)
            } else {
                val registerMethod = clazz.getMethod("registerUser")
                registerMethod.invoke(faceRecognizerObject)
            }
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to perform face recognition with selfie", e)
            false
        }
    }

    fun authenticateUserWithPhoto(credentials: FaceRecognizerCredentials, base64Image: String): Boolean {
        return try {
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials(credentials)
            
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onResult" -> {
                        val resultMap = createResultMap(
                            success = true,
                            message = "Photo authentication completed successfully",
                            data = emptyMap()
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionResult", resultMap)
                        }
                        inProgress = false
                    }
                    "onFailure" -> {
                        val errorMap = mapOf(
                            "code" to "PHOTO_AUTHENTICATION_ERROR",
                            "message" to (args?.getOrNull(0)?.toString() ?: "Photo authentication failed")
                        )
                        Handler(Looper.getMainLooper()).post { 
                            livenessModule.sendEvent("onFaceRecognitionError", errorMap)
                        }
                        inProgress = false
                    }
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            // Use the current activity if available, otherwise this won't work
            val activity = currentActivity ?: return false
            
            val clazz = Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
            val ctor = clazz.getConstructor(faceRecognizerInterface, android.app.Activity::class.java, String::class.java)
            val instance = ctor.newInstance(recognizer, activity, base64Image)
            val authMethod = clazz.getMethod("authenticateUser")
            authMethod.invoke(instance)
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to authenticate user with photo", e)
            false
        }
    }
    
    private fun buildFaceCredentials(credentials: FaceRecognizerCredentials): Any? {
        return try {
            val builderClass = Class.forName("io.udentify.android.face.FaceRecognizerCredentials\$Builder")
            var builder = builderClass.getDeclaredConstructor().newInstance()
            
            builder = builderClass.getMethod("serverURL", String::class.java).invoke(builder, credentials.serverURL)
            builder = builderClass.getMethod("transactionID", String::class.java).invoke(builder, credentials.transactionID)
            builder = builderClass.getMethod("userID", String::class.java).invoke(builder, credentials.userID)
            builder = builderClass.getMethod("autoTake", Boolean::class.javaPrimitiveType).invoke(builder, credentials.autoTake)
            builder = builderClass.getMethod("errorDelay", Float::class.javaPrimitiveType).invoke(builder, credentials.errorDelay)
            builder = builderClass.getMethod("successDelay", Float::class.javaPrimitiveType).invoke(builder, credentials.successDelay)
            builder = builderClass.getMethod("runInBackground", Boolean::class.javaPrimitiveType).invoke(builder, credentials.runInBackground)
            builder = builderClass.getMethod("blinkDetectionEnabled", Boolean::class.javaPrimitiveType).invoke(builder, credentials.blinkDetectionEnabled)
            builder = builderClass.getMethod("requestTimeout", Int::class.javaPrimitiveType).invoke(builder, credentials.requestTimeout)
            builder = builderClass.getMethod("eyesOpenThreshold", Float::class.javaPrimitiveType).invoke(builder, credentials.eyesOpenThreshold)
            builder = builderClass.getMethod("invertedAnimation", Boolean::class.javaPrimitiveType).invoke(builder, credentials.invertedAnimation)
            builder = builderClass.getMethod("activeLivenessAutoNextEnabled", Boolean::class.javaPrimitiveType).invoke(builder, credentials.activeLivenessAutoNextEnabled)
            
            try {
                builder = builderClass.getMethod("maskConfidence", Double::class.javaPrimitiveType).invoke(builder, credentials.maskConfidence.toDouble())
            } catch (e: Exception) {
                try {
                    builder = builderClass.getMethod("maskConfidence", Float::class.javaPrimitiveType).invoke(builder, credentials.maskConfidence)
                } catch (e2: Exception) {
                    Log.e(TAG, "FaceRecognizerImpl - Could not set maskConfidence: ${e2.message}")
                }
            }
            
            val credentialsObj = builderClass.getMethod("build").invoke(builder)
            
            if (credentialsObj == null) {
                Log.e(TAG, "FaceRecognizerImpl - Built credentials object is null")
            }
            
            credentialsObj
        } catch (e: Throwable) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to build FaceRecognizerCredentials", e)
            createMinimalCredentials(credentials)
        }
    }
    
    private fun createMinimalCredentials(credentials: FaceRecognizerCredentials): Any? {
        return try {
            val builderClass = Class.forName("io.udentify.android.face.FaceRecognizerCredentials\$Builder")
            var builder = builderClass.getDeclaredConstructor().newInstance()
            
            builder = builderClass.getMethod("serverURL", String::class.java).invoke(builder, credentials.serverURL ?: "")
            builder = builderClass.getMethod("transactionID", String::class.java).invoke(builder, credentials.transactionID ?: "")
            builder = builderClass.getMethod("userID", String::class.java).invoke(builder, credentials.userID ?: "")
            
            try {
                builder = builderClass.getMethod("maskConfidence", Double::class.javaPrimitiveType).invoke(builder, 0.95)
            } catch (e: Exception) {
                try {
                    builder = builderClass.getMethod("maskConfidence", Float::class.javaPrimitiveType).invoke(builder, 0.95f)
                } catch (e2: Exception) {
                    Log.e(TAG, "FaceRecognizerImpl - Could not set minimal maskConfidence: ${e2.message}")
                }
            }
            
            val credentialsObj = builderClass.getMethod("build").invoke(builder)
            
            if (credentialsObj == null) {
                Log.e(TAG, "FaceRecognizerImpl - Minimal credentials object is null")
            }
            
            credentialsObj
        } catch (e: Exception) {
            Log.e(TAG, "FaceRecognizerImpl - Failed to create minimal credentials", e)
            null
        }
    }
    
    private fun extractResponseData(serverResponse: Any?): Map<String, Any?> {
        return try {
            if (serverResponse == null) return emptyMap()
            
            val responseFields = mutableMapOf<String, Any?>()
            
            serverResponse.javaClass.declaredFields.forEach { field ->
                try {
                    field.isAccessible = true
                    val value = field.get(serverResponse)
                    
                    when (field.name) {
                        "faceIDResult" -> {
                            if (value != null) {
                                extractFaceIDResultData(value, responseFields)
                            }
                        }
                        "livenessResult" -> {
                            if (value != null) {
                                extractLivenessResultData(value, responseFields)
                            }
                        }
                        "activeLivenessResult" -> {
                            if (value != null) {
                                extractActiveLivenessResultData(value, responseFields)
                            }
                        }
                        else -> {
                            when (value) {
                                is String, is Number, is Boolean, null -> {
                                    responseFields[field.name] = value
                                }
                                else -> {
                                    responseFields[field.name] = value.toString()
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                }
            }
            
            responseFields
        } catch (e: Exception) {
            Log.e(TAG, "FaceRecognizerImpl - Error extracting response data: ${e.message}")
            emptyMap()
        }
    }
    
    private fun extractFaceIDResultData(faceIDResult: Any, responseFields: MutableMap<String, Any?>) {
        try {
            faceIDResult.javaClass.declaredFields.forEach { field ->
                try {
                    field.isAccessible = true
                    val value = field.get(faceIDResult)
                    when (value) {
                        is String, is Number, is Boolean, null -> {
                            responseFields[field.name] = value
                        }
                        else -> {
                            responseFields[field.name] = value.toString()
                        }
                    }
                } catch (e: Exception) {
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "FaceRecognizerImpl - Error extracting FaceIDResult data: ${e.message}")
        }
    }
    
    private fun extractLivenessResultData(livenessResult: Any, responseFields: MutableMap<String, Any?>) {
        try {
            livenessResult.javaClass.declaredFields.forEach { field ->
                try {
                    field.isAccessible = true
                    val value = field.get(livenessResult)
                    when (value) {
                        is String, is Number, is Boolean, null -> {
                            responseFields[field.name] = value
                        }
                        else -> {
                            responseFields[field.name] = value.toString()
                        }
                    }
                } catch (e: Exception) {
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "FaceRecognizerImpl - Error extracting LivenessResult data: ${e.message}")
        }
    }
    
    private fun extractActiveLivenessResultData(activeLivenessResult: Any, responseFields: MutableMap<String, Any?>) {
        try {
            activeLivenessResult.javaClass.declaredFields.forEach { field ->
                try {
                    field.isAccessible = true
                    val value = field.get(activeLivenessResult)
                    when (value) {
                        is String, is Number, is Boolean, null -> {
                            responseFields["active_${field.name}"] = value
                        }
                        is Map<*, *> -> {
                            responseFields["gestureResult"] = value
                        }
                        else -> {
                            responseFields["active_${field.name}"] = value.toString()
                        }
                    }
                } catch (e: Exception) {
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "FaceRecognizerImpl - Error extracting ActiveLivenessResult data: ${e.message}")
        }
    }

    private fun createResultMap(success: Boolean, message: String, data: Map<String, Any?>): Map<String, Any?> {
        val faceIDResult = mutableMapOf<String, Any?>()
        
        if (data.containsKey("verified") || data.containsKey("matchScore") || data.containsKey("userID")) {
            data.forEach { (key, value) ->
                when (value) {
                    is String -> {
                        faceIDResult[key] = if (value == "null") null else value
                    }
                    is Map<*, *> -> {
                        val nestedMap = mutableMapOf<String, Any?>()
                        value.forEach { (nestedKey, nestedValue) ->
                            nestedMap[nestedKey.toString()] = nestedValue
                        }
                        faceIDResult[key] = nestedMap
                    }
                    else -> faceIDResult[key] = value
                }
            }
        }
        
        val faceIDMessage = mutableMapOf<String, Any?>(
            "success" to success,
            "message" to message
        )
        
        if (faceIDResult.isNotEmpty()) {
            faceIDMessage["faceIDResult"] = faceIDResult
        }
        
        return mapOf(
            "status" to if (success) "success" else "failure",
            "faceIDMessage" to faceIDMessage,
            "timestamp" to System.currentTimeMillis().toDouble()
        )
    }

    private fun createActiveLivenessResultMap(data: Map<String, Any?> = emptyMap()): Map<String, Any?> {
        return createResultMap(
            success = data["verified"] as? Boolean ?: !(data["isFailed"] as? Boolean ?: true),
            message = "Active liveness completed",
            data = data
        )
    }

    private fun createSelfieRecognitionResultMap(success: Boolean, message: String, data: Map<String, Any?>, isAuthentication: Boolean): Map<String, Any?> {
        return createResultMap(success, message, data)
    }

    private fun createHybridLivenessResultMap(data: Map<String, Any?> = emptyMap()): Map<String, Any?> {
        return createResultMap(
            success = data["verified"] as? Boolean ?: !(data["isFailed"] as? Boolean ?: true),
            message = "Hybrid liveness completed",
            data = data
        )
    }

    private fun dismissCurrentFragment(tag: String) {
        try {
            currentActivity?.let { activity ->
                Handler(Looper.getMainLooper()).post {
                    val fragmentManager = activity.supportFragmentManager
                    val fragment = fragmentManager.findFragmentByTag(tag)
                    
                    fragment?.let {
                        fragmentManager.beginTransaction()
                            .remove(it)
                            .commitAllowingStateLoss()
                        
                        if (fragmentManager.backStackEntryCount > 0) {
                            fragmentManager.popBackStack()
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "FaceRecognizerImpl - Error dismissing fragment: ${e.message}")
        }
    }
}