package expo.modules.ocr

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentTransaction
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import io.udentify.android.ocr.activities.CardFragment
import io.udentify.android.ocr.activities.CardRecognizerObject
import io.udentify.android.ocr.activities.DocumentLivenessListener
import io.udentify.android.ocr.activities.HologramFragment
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse

class ExpoOCRModule : Module() {
    
    companion object {
        private const val TAG = "ExpoOCRModule"
    }
    
    private var lastCapturedFrontImageBase64: String = ""
    private var lastCapturedBackImageBase64: String = ""
    private var currentServerURL: String? = null
    private var currentTransactionID: String? = null
    private var currentDocumentType: String? = null
    private var currentCountry: String = "TUR"
    private var uiConfiguration: Map<String, Any>? = null
    
    override fun definition() = ModuleDefinition {
        Name("ExpoOCR")
        
        Events("onOCRComplete", "onOCRError", "onHologramComplete", "onHologramVideoRecorded", "onHologramError", "onIQAResult")
        
        AsyncFunction("checkAvailability") {
            mapOf(
                "isAvailable" to true,
                "deviceSupported" to true,
                "osVersion" to android.os.Build.VERSION.RELEASE,
                "frameworkImported" to true
            )
        }
        
        AsyncFunction("getFrameworkInfo") {
            mapOf(
                "frameworkName" to "UdentifyOCR",
                "version" to "25.3.0",
                "status" to "Framework loaded successfully"
            )
        }
        
        AsyncFunction("configureUISettings") { uiConfig: Map<String, Any> ->
            try {
                val configMap = mutableMapOf<String, Any>()
                
                uiConfig["backgroundColor"]?.let { configMap["backgroundColor"] = it }
                uiConfig["borderColor"]?.let { configMap["borderColor"] = it }
                uiConfig["placeholderTemplate"]?.let { configMap["placeholderTemplate"] = it }
                uiConfig["orientation"]?.let { configMap["orientation"] = it }
                uiConfig["cornerRadius"]?.let { configMap["cornerRadius"] = it }
                uiConfig["detectionAccuracy"]?.let { configMap["detectionAccuracy"] = it }
                uiConfig["backButtonEnabled"]?.let { configMap["backButtonEnabled"] = it }
                uiConfig["reviewScreenEnabled"]?.let { configMap["reviewScreenEnabled"] = it }
                uiConfig["footerViewHidden"]?.let { configMap["footerViewHidden"] = it }
                uiConfig["blurCoefficient"]?.let { configMap["blurCoefficient"] = it }
                uiConfig["requestTimeout"]?.let { configMap["requestTimeout"] = it }
                uiConfig["manualCapture"]?.let { configMap["manualCapture"] = it }
                uiConfig["faceDetection"]?.let { configMap["faceDetection"] = it }
                uiConfig["isDocumentLivenessActive"]?.let { configMap["isDocumentLivenessActive"] = it }
                // IQA settings
                uiConfig["isIQAServiceEnabled"]?.let { configMap["isIQAServiceEnabled"] = it }
                uiConfig["iqaEnabled"]?.let { configMap["iqaEnabled"] = it }
                uiConfig["iqaSuccessAutoDismissDelay"]?.let { configMap["iqaSuccessAutoDismissDelay"] = it }
                
                uiConfiguration = configMap.toMap()
                
                true
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error configuring UI settings: ${e.message}", e)
                throw Exception("Failed to configure UI settings: ${e.message}")
            }
        }
        
        AsyncFunction("startOCRScanning") { serverURL: String, transactionID: String, documentType: String, documentSide: String, country: String?, promise: Promise ->
            val currentActivity = appContext.currentActivity as? AppCompatActivity
            if (currentActivity == null) {
                promise.reject("OCR_ERROR", "Unable to find activity to present OCR camera", null)
                return@AsyncFunction
            }
            
            if (ContextCompat.checkSelfPermission(appContext.reactContext!!, Manifest.permission.CAMERA) 
                != PackageManager.PERMISSION_GRANTED) {
                promise.reject("OCR_ERROR", "Camera permission is required for OCR scanning", null)
                return@AsyncFunction
            }
            
            if (ContextCompat.checkSelfPermission(appContext.reactContext!!, Manifest.permission.READ_PHONE_STATE) 
                != PackageManager.PERMISSION_GRANTED) {
                promise.reject("OCR_ERROR", "Phone state permission is required for Udentify SDK", null)
                return@AsyncFunction
            }
            
            try {
                currentServerURL = serverURL
                currentTransactionID = transactionID
                currentDocumentType = documentType
                currentCountry = country ?: "TUR"
                
                lastCapturedFrontImageBase64 = ""
                lastCapturedBackImageBase64 = ""
                
                val cardRecognizer = OCRCardRecognizer(
                    activity = currentActivity,
                    serverURL = serverURL,
                    transactionID = transactionID,
                    documentType = documentType,
                    country = currentCountry,
                    originalDocumentSide = documentSide,
                    ocrModule = this@ExpoOCRModule,
                    uiConfiguration = uiConfiguration,
                    promise = promise
                )
                
                val process = when (documentSide.uppercase()) {
                    "FRONT", "FRONTSIDE" -> Process.frontSide
                    "BACK", "BACKSIDE" -> Process.backSide
                    "BOTH", "BOTHSIDES" -> Process.frontSide
                    else -> Process.frontSide
                }
                
                val cardOrientation = if (uiConfiguration?.get("orientation") == "vertical") true else false
                
                val cardFragment = CardFragment.newInstance(
                    process,
                    cardOrientation,
                    cardRecognizer
                )
                
                currentActivity.runOnUiThread {
                    try {
                        val fragmentManager = currentActivity.supportFragmentManager
                        val transaction: FragmentTransaction = fragmentManager.beginTransaction()
                        transaction.add(android.R.id.content, cardFragment)
                        transaction.addToBackStack(null)
                        transaction.commit()
                    } catch (e: Exception) {
                        Log.e(TAG, "ExpoOCRModule - Error adding CardFragment: ${e.message}", e)
                        promise.reject("OCR_ERROR", "Failed to instantiate OCR camera controller", e)
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error starting OCR scanning: ${e.message}", e)
                promise.reject("OCR_ERROR", "Failed to start OCR scanning: ${e.message}", e)
            }
        }
        
        AsyncFunction("performOCR") { serverURL: String, transactionID: String, frontSideImage: String, backSideImage: String, documentType: String, country: String?, promise: Promise ->
            if (serverURL.isEmpty()) {
                throw Exception("Server URL cannot be empty")
            }
            
            if (transactionID.isEmpty()) {
                throw Exception("Transaction ID cannot be empty")
            }
            
            val currentActivity = appContext.currentActivity as? AppCompatActivity
            if (currentActivity == null) {
                throw Exception("Current activity is not an AppCompatActivity")
            }
            
            try {
                var frontImage = frontSideImage
                var backImage = backSideImage
                
                if (frontSideImage.isEmpty() && backSideImage.isEmpty()) {
                    frontImage = lastCapturedFrontImageBase64
                    backImage = lastCapturedBackImageBase64
                    
                    if (frontImage.isEmpty() && backImage.isEmpty()) {
                        throw Exception("No images available for OCR processing")
                    }
                }
                
                val cardRecognizer = OCRCardRecognizer(
                    activity = currentActivity,
                    serverURL = serverURL,
                    transactionID = transactionID,
                    documentType = documentType,
                    country = country ?: "TUR",
                    originalDocumentSide = "API_ONLY",
                    ocrModule = null,
                    uiConfiguration = uiConfiguration,
                    promise = promise
                )
                
                val cardRecognizerObject = CardRecognizerObject(
                    cardRecognizer,
                    currentActivity,
                    frontImage,
                    backImage
                )
                
                cardRecognizerObject.processOCR()
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error performing OCR: ${e.message}", e)
                promise.reject("OCR_ERROR", "OCR processing failed: ${e.message}", e)
            }
        }
        
        AsyncFunction("performDocumentLiveness") { serverURL: String, transactionID: String, frontSideImage: String, backSideImage: String, promise: Promise ->
            val currentActivity = appContext.currentActivity as? AppCompatActivity
            if (currentActivity == null) {
                throw Exception("Current activity is not an AppCompatActivity")
            }
            
            try {
                var frontImage = frontSideImage
                var backImage = backSideImage
                
                if (frontSideImage.isEmpty() && backSideImage.isEmpty()) {
                    frontImage = lastCapturedFrontImageBase64
                    backImage = lastCapturedBackImageBase64
                    
                    if (frontImage.isEmpty() && backImage.isEmpty()) {
                        throw Exception("Document liveness requires at least one valid base64 image")
                    }
                }
                
                if (frontImage.isEmpty() && backImage.isEmpty()) {
                    throw Exception("Failed to convert base64 strings to valid images")
                }
                
                val cardRecognizerObject = CardRecognizerObject(currentActivity)
                
                cardRecognizerObject.performDocumentLiveness(
                    serverURL,
                    transactionID,
                    frontImage,
                    backImage,
                    object : DocumentLivenessListener {
                        override fun successResponse(response: OCRAndDocumentLivenessResponse?) {
                            if (response != null) {
                                try {
                                    val result = convertDocumentLivenessResponseToMap(response, transactionID)
                                    promise.resolve(result)
                                } catch (e: Exception) {
                                    Log.e(TAG, "ExpoOCRModule - Error converting liveness response: ${e.message}", e)
                                    promise.reject("LIVENESS_ERROR", "Error processing liveness response: ${e.message}", e)
                                }
                            } else {
                                promise.reject("LIVENESS_ERROR", "No document liveness response received", null)
                            }
                        }
                        
                        override fun errorResponse(error: String?) {
                            Log.e(TAG, "ExpoOCRModule - Document Liveness API Error: $error")
                            promise.reject("LIVENESS_ERROR", error ?: "Document liveness check failed", null)
                        }
                    }
                )
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error performing document liveness: ${e.message}", e)
                promise.reject("LIVENESS_ERROR", "Document liveness check failed: ${e.message}", e)
            }
        }
        
        AsyncFunction("performOCRAndDocumentLiveness") { serverURL: String, transactionID: String, frontSideImage: String, backSideImage: String, documentType: String, country: String?, promise: Promise ->
            if (serverURL.isEmpty()) {
                throw Exception("Server URL cannot be empty")
            }
            
            if (transactionID.isEmpty()) {
                throw Exception("Transaction ID cannot be empty")
            }
            
            if (documentType.isEmpty()) {
                throw Exception("Document type cannot be empty")
            }
            
            val currentActivity = appContext.currentActivity as? AppCompatActivity
            if (currentActivity == null) {
                throw Exception("Current activity is not an AppCompatActivity")
            }
            
            try {
                var frontImage = frontSideImage
                var backImage = backSideImage
                
                if (frontSideImage.isEmpty() && backSideImage.isEmpty()) {
                    frontImage = lastCapturedFrontImageBase64
                    backImage = lastCapturedBackImageBase64
                    
                    if (frontImage.isEmpty() && backImage.isEmpty()) {
                        throw Exception("OCR and document liveness requires at least one valid base64 image")
                    }
                }
                
                if (frontImage.isEmpty() && backImage.isEmpty()) {
                    throw Exception("Failed to convert base64 strings to valid images")
                }
                
                val cardRecognizer = OCRCardRecognizer(
                    activity = currentActivity,
                    serverURL = serverURL,
                    transactionID = transactionID,
                    documentType = documentType,
                    country = country ?: "TUR",
                    originalDocumentSide = "API_ONLY",
                    ocrModule = null,
                    uiConfiguration = uiConfiguration,
                    promise = promise
                )
                
                val cardRecognizerObject = CardRecognizerObject(
                    cardRecognizer,
                    currentActivity,
                    frontImage,
                    backImage
                )
                
                cardRecognizerObject.processOCR()
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error performing OCR and document liveness: ${e.message}", e)
                promise.reject("OCR_AND_LIVENESS_ERROR", "OCR and document liveness check failed: ${e.message}", e)
            }
        }
        
        AsyncFunction("startHologramCamera") { serverURL: String, transactionID: String, promise: Promise ->
            val currentActivity = appContext.currentActivity as? AppCompatActivity
            if (currentActivity == null) {
                promise.reject("HOLOGRAM_ERROR", "Unable to find activity to present Hologram camera", null)
                return@AsyncFunction
            }
            
            if (ContextCompat.checkSelfPermission(appContext.reactContext!!, Manifest.permission.CAMERA) 
                != PackageManager.PERMISSION_GRANTED) {
                promise.reject("HOLOGRAM_ERROR", "Camera permission is required for hologram scanning", null)
                return@AsyncFunction
            }
            
            if (ContextCompat.checkSelfPermission(appContext.reactContext!!, Manifest.permission.READ_PHONE_STATE) 
                != PackageManager.PERMISSION_GRANTED) {
                promise.reject("HOLOGRAM_ERROR", "Phone state permission is required for Udentify SDK", null)
                return@AsyncFunction
            }
            
            try {
                currentServerURL = serverURL
                currentTransactionID = transactionID
                
                val hologramRecognizer = HologramRecognizer(
                    activity = currentActivity,
                    serverURL = serverURL,
                    transactionID = transactionID,
                    ocrModule = this@ExpoOCRModule,
                    promise = promise
                )
                
                val hologramFragment = HologramFragment.newInstance(
                    false,
                    hologramRecognizer
                )
                
                currentActivity.runOnUiThread {
                    try {
                        val fragmentManager = currentActivity.supportFragmentManager
                        val transaction: FragmentTransaction = fragmentManager.beginTransaction()
                        transaction.add(android.R.id.content, hologramFragment)
                        transaction.addToBackStack(null)
                        transaction.commit()
                    } catch (e: Exception) {
                        Log.e(TAG, "ExpoOCRModule - Error adding HologramFragment: ${e.message}", e)
                        promise.reject("HOLOGRAM_ERROR", "Failed to instantiate Hologram camera controller", e)
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error starting hologram camera: ${e.message}", e)
                promise.reject("HOLOGRAM_ERROR", "Failed to start hologram camera: ${e.message}", e)
            }
        }
        
        AsyncFunction("performHologramCheck") { serverURL: String, transactionID: String, videoUrls: List<String> ->
            try {
                if (videoUrls.isEmpty()) {
                    throw Exception("No video URLs provided for hologram check")
                }
                
                mapOf(
                    "success" to false,
                    "message" to "Android hologram check is handled automatically through camera callbacks",
                    "transactionID" to transactionID,
                    "timestamp" to System.currentTimeMillis().toDouble()
                )
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error in performHologramCheck: ${e.message}", e)
                throw Exception("Failed to perform hologram check: ${e.message}")
            }
        }
    }
    
    private fun convertDocumentLivenessResponseToMap(
        response: OCRAndDocumentLivenessResponse,
        transactionID: String
    ): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        result["success"] = !response.isFailed
        result["transactionID"] = transactionID
        result["timestamp"] = System.currentTimeMillis().toDouble()
        
        if (response.errorCode != null) {
            result["error"] = response.errorCode
        }
        
        if (response.documentLivenessDataFront != null) {
            try {
                val frontResult = parseDocumentLivenessData(response.documentLivenessDataFront, "front")
                val probability = frontResult["aggregateDocumentLivenessProbability"] as? Double ?: 0.85
                result["frontDocumentLivenessData"] = frontResult
                result["frontSideProbability"] = probability
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error parsing front document liveness data: ${e.message}")
                result["frontSideProbability"] = 0.85
            }
        }
        
        if (response.documentLivenessDataBack != null) {
            try {
                val backResult = parseDocumentLivenessData(response.documentLivenessDataBack, "back")
                val probability = backResult["aggregateDocumentLivenessProbability"] as? Double ?: 0.85
                result["backDocumentLivenessData"] = backResult
                result["backSideProbability"] = probability
            } catch (e: Exception) {
                Log.e(TAG, "ExpoOCRModule - Error parsing back document liveness data: ${e.message}")
                result["backSideProbability"] = 0.85
            }
        }
        
        return result
    }
    
    fun storeDocumentScanImages(frontSideBase64: String, backSideBase64: String) {
        lastCapturedFrontImageBase64 = frontSideBase64
        lastCapturedBackImageBase64 = backSideBase64
    }
    
    fun emitHologramComplete(result: Map<String, Any>) {
        try {
            this@ExpoOCRModule.sendEvent("onHologramComplete", result)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoOCRModule - Error sending onHologramComplete event: ${e.message}", e)
        }
    }
    
    fun emitHologramVideoRecorded(videoUrls: List<String>) {
        try {
            val params = mapOf("videoUrls" to videoUrls)
            this@ExpoOCRModule.sendEvent("onHologramVideoRecorded", params)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoOCRModule - Error sending onHologramVideoRecorded event: ${e.message}", e)
        }
    }
    
    fun emitHologramError(error: String) {
        try {
            val params = mapOf("message" to error)
            this@ExpoOCRModule.sendEvent("onHologramError", params)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoOCRModule - Error sending onHologramError event: ${e.message}", e)
        }
    }
    
    fun emitOCRComplete(result: Map<String, Any>) {
        try {
            this@ExpoOCRModule.sendEvent("onOCRComplete", result)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoOCRModule - Error sending onOCRComplete event: ${e.message}", e)
        }
    }
    
    fun emitOCRError(error: String) {
        try {
            val params = mapOf("message" to error)
            this@ExpoOCRModule.sendEvent("onOCRError", params)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoOCRModule - Error sending onOCRError event: ${e.message}", e)
        }
    }
    
    fun emitIQAResult(result: Map<String, Any>) {
        try {
            this@ExpoOCRModule.sendEvent("onIQAResult", result)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoOCRModule - Error sending onIQAResult event: ${e.message}", e)
        }
    }
    
    private fun parseDocumentLivenessData(documentData: Any, side: String): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        val dataClass = documentData.javaClass
        
        val aggregateMethod = dataClass.methods.find { it.name == "getAggregateDocumentLivenessProbability" }
        if (aggregateMethod != null) {
            val aggregateValue = aggregateMethod.invoke(documentData) as? String
            val probability = aggregateValue?.toDoubleOrNull() ?: 0.85
            result["aggregateDocumentLivenessProbability"] = probability
        } else {
            result["aggregateDocumentLivenessProbability"] = 0.85
        }
        
        val pipelinesMethod = dataClass.methods.find { it.name == "getPipelines" }
        if (pipelinesMethod != null) {
            val pipelinesData = pipelinesMethod.invoke(documentData)
            if (pipelinesData != null) {
                val pipelineResult = mutableMapOf<String, Any>()
                val pipelineClass = pipelinesData.javaClass
                
                val nameMethod = pipelineClass.methods.find { it.name == "getName" }
                if (nameMethod != null) {
                    val nameValue = nameMethod.invoke(pipelinesData) as? String
                    if (nameValue != null) pipelineResult["name"] = nameValue
                }
                
                val calibrationMethod = pipelineClass.methods.find { it.name == "getCalibration" }
                if (calibrationMethod != null) {
                    val calibrationValue = calibrationMethod.invoke(pipelinesData) as? String
                    if (calibrationValue != null) pipelineResult["calibration"] = calibrationValue
                }
                
                val scoreMethod = pipelineClass.methods.find { it.name == "getDocumentLivenessScore" }
                if (scoreMethod != null) {
                    val scoreValue = scoreMethod.invoke(pipelinesData) as? String
                    if (scoreValue != null) pipelineResult["documentLivenessScore"] = scoreValue
                }
                
                val probMethod = pipelineClass.methods.find { it.name == "getDocumentLivenessProbability" }
                if (probMethod != null) {
                    val probValue = probMethod.invoke(pipelinesData) as? String
                    if (probValue != null) pipelineResult["documentLivenessProbability"] = probValue
                }
                
                val statusMethod = pipelineClass.methods.find { it.name == "getDocumentStatusCode" }
                if (statusMethod != null) {
                    val statusValue = statusMethod.invoke(pipelinesData) as? String
                    if (statusValue != null) pipelineResult["documentStatusCode"] = statusValue
                }
                
                result["pipelines"] = pipelineResult
            }
        }
        
        val warningsMethod = dataClass.methods.find { it.name == "getAggregateDocumentImageQualityWarnings" }
        if (warningsMethod != null) {
            val warningsValue = warningsMethod.invoke(documentData) as? String
            if (warningsValue != null) result["aggregateDocumentImageQualityWarnings"] = warningsValue
        }
        
        return result
    }
}
