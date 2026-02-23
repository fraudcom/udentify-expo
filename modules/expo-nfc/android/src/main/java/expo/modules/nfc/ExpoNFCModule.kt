package expo.modules.nfc

import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import io.udentify.android.nfc.ApiCredentials
import io.udentify.android.nfc.reader.NFCLocation
import io.udentify.android.nfc.reader.NfcLocationListener

class ExpoNFCModule : Module(), INFCModuleCallbacks {

    companion object {
        private const val TAG = "ExpoNfcModule"
    }

    private var nfcLocation: NFCLocation? = null
    private var currentCredentials: ApiCredentials? = null
    private var pendingReadingPromise: expo.modules.kotlin.Promise? = null

    override fun definition() = ModuleDefinition {
        Name("ExpoNFC")

        Events(
            "onNFCPassportSuccess",
            "onNFCError",
            "onNFCProgress"
        )

        AsyncFunction("isNFCAvailable") {
            try {
                Log.d(TAG, "ExpoNfcModule - Checking NFC availability")

                val isAvailable = true
                Log.d(TAG, "ExpoNfcModule - NFC available: $isAvailable (handled by Udentify SDK)")

                isAvailable
            } catch (e: Exception) {
                Log.e(TAG, "ExpoNfcModule - Error checking NFC availability: ${e.message}", e)
                throw Exception("Error checking NFC availability: ${e.message}")
            }
        }

        AsyncFunction("isNFCEnabled") {
            try {
                Log.d(TAG, "ExpoNfcModule - Checking NFC enabled status")

                val isEnabled = true
                Log.d(TAG, "ExpoNfcModule - NFC enabled: $isEnabled (handled by Udentify SDK)")

                isEnabled
            } catch (e: Exception) {
                Log.e(TAG, "ExpoNfcModule - Error checking NFC enabled status: ${e.message}", e)
                throw Exception("Error checking NFC enabled status: ${e.message}")
            }
        }

        AsyncFunction("startNFCReading") { credentials: Map<String, Any?>, promise: expo.modules.kotlin.Promise ->
            Log.d(TAG, "ExpoNfcModule - ========== STARTING NFC PASSPORT READING ==========")
            Log.d(TAG, "ExpoNfcModule - Credentials: $credentials")
            Log.d(TAG, "ExpoNfcModule - Current pendingReadingPromise: $pendingReadingPromise")
            Log.d(TAG, "ExpoNfcModule - Current currentCredentials: $currentCredentials")

            val currentActivity = appContext.currentActivity
            if (currentActivity !is AppCompatActivity) {
                Log.e(TAG, "ExpoNfcModule - Current activity is not AppCompatActivity")
                promise.reject("NFC_ERROR", "Current activity must be an AppCompatActivity for NFC reading", null)
                return@AsyncFunction
            }
            
            Log.d(TAG, "ExpoNfcModule - Activity is valid: ${currentActivity.javaClass.simpleName}")

            val documentNumber = credentials["documentNumber"] as? String
            val dateOfBirth = credentials["dateOfBirth"] as? String
            val expiryDate = credentials["expiryDate"] as? String
            val serverURL = credentials["serverURL"] as? String
            val transactionID = credentials["transactionID"] as? String

            if (documentNumber == null || dateOfBirth == null || expiryDate == null ||
                serverURL == null || transactionID == null) {
                Log.e(TAG, "ExpoNfcModule - Missing required credentials")
                promise.reject("NFC_ERROR", "Missing required credentials: documentNumber, dateOfBirth, expiryDate, serverURL, transactionID", null)
                return@AsyncFunction
            }

            val isActiveAuthEnabled = credentials["isActiveAuthenticationEnabled"] as? Boolean ?: true
            val isPassiveAuthEnabled = credentials["isPassiveAuthenticationEnabled"] as? Boolean ?: true
            val enableAutoTriggering = credentials["enableAutoTriggering"] as? Boolean ?: true

            Log.d(TAG, "ExpoNfcModule - Building API credentials")
            val apiCredentials = ApiCredentials.Builder()
                .mrzDocNo(documentNumber)
                .mrzBirthDate(dateOfBirth)
                .mrzExpireDate(expiryDate)
                .serverUrl(serverURL)
                .transactionID(transactionID)
                .enableAutoTriggering(enableAutoTriggering)
                .isActiveAuthenticationEnabled(isActiveAuthEnabled)
                .isPassiveAuthenticationEnabled(isPassiveAuthEnabled)
                .build()

            currentCredentials = apiCredentials
            pendingReadingPromise = promise

            Log.d(TAG, "ExpoNfcModule - Stored credentials and promise in module")
            Log.d(TAG, "ExpoNfcModule - Transaction ID: ${apiCredentials.transactionID}")
            Log.d(TAG, "ExpoNfcModule - About to start NFC reading as separate Activity")
            
            try {
                // Start NFCReaderActivityWrapper as a proper Activity
                val intent = android.content.Intent(currentActivity, NFCReaderActivityWrapper::class.java)
                
                // Store references for the activity to use
                NFCReaderActivityWrapper.staticCredentials = apiCredentials
                NFCReaderActivityWrapper.staticCallbacks = this@ExpoNFCModule
                NFCReaderActivityWrapper.staticPromise = promise
                
                currentActivity.startActivity(intent)
                Log.d(TAG, "ExpoNfcModule - ✅ NFCReaderActivity launched successfully")
                Log.d(TAG, "ExpoNfcModule - Activity should now be active and listening for NFC")
            } catch (e: Exception) {
                Log.e(TAG, "ExpoNfcModule - ❌ Exception starting NFC reading: ${e.message}", e)
                e.printStackTrace()
                currentCredentials = null
                pendingReadingPromise = null
                promise.reject("NFC_ERROR", "Failed to start NFC reading: ${e.message}", e)
            }
        }

        AsyncFunction("cancelNFCReading") {
            Log.d(TAG, "ExpoNfcModule - Cancelling NFC reading")

            val currentActivity = appContext.currentActivity
            if (currentActivity is AppCompatActivity) {
                NFCReaderActivityWrapper.stopInlineNFCReading(currentActivity)
            }

            currentCredentials = null
            pendingReadingPromise?.reject("NFC_CANCELLED", "NFC reading was cancelled", null)
            pendingReadingPromise = null

            Log.d(TAG, "ExpoNfcModule - NFC reading cancelled successfully")
            true
        }

        AsyncFunction("getNFCLocation") { serverURL: String, promise: expo.modules.kotlin.Promise ->
            try {
                Log.d(TAG, "ExpoNfcModule - Getting NFC antenna location")

                val currentActivity = appContext.currentActivity
                if (currentActivity == null) {
                    promise.reject("NFC_ERROR", "No current activity found", null)
                    return@AsyncFunction
                }

                val locationListener = object : NfcLocationListener {
                    override fun onSuccess(location: Int) {
                        Log.d(TAG, "ExpoNfcModule - NFC location detected: $location")

                        val result = mapOf(
                            "success" to true,
                            "location" to location,
                            "message" to "NFC location detected successfully",
                            "timestamp" to System.currentTimeMillis().toDouble()
                        )

                        promise.resolve(result)
                    }

                    override fun onFailed(error: String?) {
                        Log.e(TAG, "ExpoNfcModule - NFC location detection failed: $error")
                        promise.reject("NFC_LOCATION_ERROR", error ?: "Failed to detect NFC location", null)
                    }
                }

                nfcLocation = NFCLocation(locationListener, "$serverURL/nfc/nfcLocation")
                nfcLocation?.getNfcLocation()
                
            } catch (e: Exception) {
                Log.e(TAG, "ExpoNfcModule - Error getting NFC location: ${e.message}", e)
                promise.reject("NFC_LOCATION_ERROR", "Error getting NFC location: ${e.message}", e)
            }
        }
    }

    override fun emitNFCPassportSuccess(result: Map<String, Any>) {
        Log.d(TAG, "ExpoNfcModule - ========== EMITTING SUCCESS EVENT ==========")
        Log.d(TAG, "ExpoNfcModule - Called from thread: ${Thread.currentThread().name}")
        Log.d(TAG, "ExpoNfcModule - Result map size: ${result.size}")
        Log.d(TAG, "ExpoNfcModule - Result keys: ${result.keys}")
        Log.d(TAG, "ExpoNfcModule - Success value: ${result["success"]}")
        Log.d(TAG, "ExpoNfcModule - Transaction ID: ${result["transactionID"]}")
        Log.d(TAG, "ExpoNfcModule - First Name: ${result["firstName"]}")
        Log.d(TAG, "ExpoNfcModule - Last Name: ${result["lastName"]}")
        
        try {
            Log.d(TAG, "ExpoNfcModule - About to send event to JavaScript")
            sendEvent("onNFCPassportSuccess", result)
            Log.d(TAG, "ExpoNfcModule - ✅ Event sent successfully to JavaScript")
            
            pendingReadingPromise = null
            currentCredentials = null
            Log.d(TAG, "ExpoNfcModule - ✅ Cleaned up module state after success")
        } catch (e: Exception) {
            Log.e(TAG, "ExpoNfcModule - ❌ Error sending event: ${e.message}", e)
            e.printStackTrace()
        }
    }

    override fun emitNFCError(error: String) {
        Log.d(TAG, "ExpoNfcModule - ========== EMITTING ERROR EVENT ==========")
        Log.d(TAG, "ExpoNfcModule - Error message: $error")
        val params = mapOf(
            "message" to error,
            "timestamp" to System.currentTimeMillis().toDouble()
        )
        try {
            sendEvent("onNFCError", params)
            Log.d(TAG, "ExpoNfcModule - Error event sent successfully")
            
            pendingReadingPromise = null
            currentCredentials = null
            Log.d(TAG, "ExpoNfcModule - Cleaned up module state after error")
        } catch (e: Exception) {
            Log.e(TAG, "ExpoNfcModule - Error sending error event: ${e.message}", e)
            e.printStackTrace()
        }
    }

    fun emitNFCProgress(progress: Int) {
        Log.d(TAG, "ExpoNfcModule - NFC progress: $progress%")
        try {
            val params = mapOf(
                "progress" to progress,
                "timestamp" to System.currentTimeMillis().toDouble()
            )
            sendEvent("onNFCProgress", params)
        } catch (e: Exception) {
            Log.e(TAG, "ExpoNfcModule - Error sending progress event: ${e.message}", e)
        }
    }

    override fun convertBitmapToBase64(bitmap: android.graphics.Bitmap): String {
        val outputStream = java.io.ByteArrayOutputStream()
        bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, outputStream)
        val byteArray = outputStream.toByteArray()
        return android.util.Base64.encodeToString(byteArray, android.util.Base64.DEFAULT)
    }
}