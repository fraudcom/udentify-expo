package expo.modules.mrz

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.Manifest
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoMRZModule : Module() {
    
    companion object {
        private const val TAG = "ExpoMRZModule"
        private const val REQUEST_CAMERA_PERMISSION = 1001
        const val LAUNCH_MRZ_CAMERA_ACTIVITY = 1002
    }
    
    private var currentPromise: Promise? = null
    
    override fun definition() = ModuleDefinition {
        Name("ExpoMRZ")
        
        Events("onMrzProgress")
        
        AsyncFunction("checkPermissions") {
            try {
                val currentActivity = appContext.currentActivity
                if (currentActivity != null) {
                    val hasCameraPermission = ContextCompat.checkSelfPermission(
                        currentActivity,
                        Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED
                    hasCameraPermission
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "ExpoMRZModule - Error checking permissions: ${e.message}")
                false
            }
        }
        
        AsyncFunction("requestPermissions") {
            try {
                val currentActivity = appContext.currentActivity
                if (currentActivity != null) {
                    val hasCameraPermission = ContextCompat.checkSelfPermission(
                        currentActivity,
                        Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED
                    
                    if (hasCameraPermission) {
                        "granted"
                    } else {
                        ActivityCompat.requestPermissions(
                            currentActivity,
                            arrayOf(Manifest.permission.CAMERA),
                            REQUEST_CAMERA_PERMISSION
                        )
                        "requested"
                    }
                } else {
                    "denied"
                }
            } catch (e: Exception) {
                Log.e(TAG, "ExpoMRZModule - Error requesting permissions: ${e.message}")
                "denied"
            }
        }
        
        AsyncFunction("startMrzCamera") { customization: Map<String, Any>?, promise: Promise ->
            try {
                val currentActivity = appContext.currentActivity ?: run {
                    promise.reject("ACTIVITY_ERROR", "Activity not available", null)
                    return@AsyncFunction
                }
                
                val hasCameraPermission = ContextCompat.checkSelfPermission(
                    currentActivity,
                    Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED
                
                if (!hasCameraPermission) {
                    promise.reject("PERMISSION_DENIED", "Camera permission required for MRZ scanning", null)
                    return@AsyncFunction
                }
                
                currentPromise = promise
                
                val intent = Intent(currentActivity, MrzCameraActivity::class.java)
                currentActivity.startActivityForResult(intent, LAUNCH_MRZ_CAMERA_ACTIVITY)
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoMRZModule - Error starting MRZ camera: ${e.message}")
                promise.reject("START_MRZ_CAMERA_ERROR", "Failed to start MRZ camera: ${e.message}", e)
            }
        }
        
        AsyncFunction("processMrzImage") { imageBase64: String, promise: Promise ->
            promise.reject("NOT_IMPLEMENTED", "Image processing feature not yet implemented", null)
        }
        
        AsyncFunction("cancelMrzScanning") {
            try {
                currentPromise?.reject("CANCELLED", "MRZ scanning was cancelled", null)
                currentPromise = null
                
                true
            } catch (e: Exception) {
                Log.e(TAG, "ExpoMRZModule - Error cancelling MRZ scanning: ${e.message}")
                false
            }
        }
        
        OnActivityResult { _, result ->
            handleActivityResult(result.requestCode, result.resultCode, result.data)
        }
    }
    
    private fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == LAUNCH_MRZ_CAMERA_ACTIVITY) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val mrzDataJson = data.getStringExtra(MrzCameraActivity.RESULT_MRZ_DATA)
                
                if (mrzDataJson != null) {
                    try {
                        val jsonObject = org.json.JSONObject(mrzDataJson)
                        
                        fun getValueFromJson(vararg keys: String): String {
                            for (key in keys) {
                                if (jsonObject.has(key)) {
                                    val value = jsonObject.optString(key, "")
                                    if (value.isNotEmpty()) {
                                        return value
                                    }
                                }
                            }
                            return ""
                        }
                        
                        val mrzData = mapOf(
                            "documentType" to getValueFromJson("documentType", "docType", "document_type"),
                            "issuingCountry" to getValueFromJson("issuingCountry", "issuing_country", "country"),
                            "documentNumber" to getValueFromJson("documentNumber", "docNo", "document_number", "doc_no"),
                            "optionalData1" to getValueFromJson("optionalData1", "optional_data_1", "optionalData"),
                            "dateOfBirth" to getValueFromJson("dateOfBirth", "birthDate", "date_of_birth", "birth_date"),
                            "gender" to getValueFromJson("gender", "sex"),
                            "dateOfExpiration" to getValueFromJson("date_of_expire", "dateOfExpiration", "expirationDate", "expireDate", "date_of_expiration", "expiration_date"),
                            "nationality" to getValueFromJson("nationality", "nat"),
                            "optionalData2" to getValueFromJson("optionalData2", "optional_data_2"),
                            "surname" to getValueFromJson("surname", "lastName", "last_name"),
                            "givenNames" to getValueFromJson("givenNames", "firstName", "first_name", "given_names")
                        )
                        
                        val docNum = getValueFromJson("documentNumber", "docNo", "document_number", "doc_no")
                        val birthDate = getValueFromJson("dateOfBirth", "birthDate", "date_of_birth", "birth_date")
                        val expDate = getValueFromJson("date_of_expire", "dateOfExpiration", "expirationDate", "expireDate", "date_of_expiration", "expiration_date")
                        
                        val resultMap = mapOf(
                            "success" to true,
                            "mrzData" to mrzData,
                            "documentNumber" to docNum,
                            "dateOfBirth" to birthDate,
                            "dateOfExpiration" to expDate
                        )
                        
                        currentPromise?.resolve(resultMap)
                        currentPromise = null
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "ExpoMRZModule - Error parsing MRZ result: ${e.message}")
                        currentPromise?.reject("PARSE_ERROR", "Failed to parse MRZ result: ${e.message}", e)
                        currentPromise = null
                    }
                } else {
                    currentPromise?.reject("NO_DATA", "No MRZ data received", null)
                    currentPromise = null
                }
            } else {
                currentPromise?.reject("USER_CANCELLED", "MRZ scanning was cancelled", null)
                currentPromise = null
            }
        }
    }
}

