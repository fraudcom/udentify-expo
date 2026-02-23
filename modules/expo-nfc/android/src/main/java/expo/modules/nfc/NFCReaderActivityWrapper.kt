package expo.modules.nfc

import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import expo.modules.kotlin.Promise
import io.udentify.android.nfc.ApiCredentials
import io.udentify.android.nfc.CardData
import io.udentify.android.nfc.reader.NFCReaderActivity
import io.udentify.android.nfc.reader.NFCReaderFragment
import io.udentify.android.nfc.reader.NFCState
import io.udentify.android.nfc.reader.DGResponse

interface INFCModuleCallbacks {
    fun emitNFCPassportSuccess(result: Map<String, Any>)
    fun emitNFCError(error: String)
    fun convertBitmapToBase64(bitmap: android.graphics.Bitmap): String
}

class NFCReaderActivityWrapper : NFCReaderActivity() {

    companion object {
        private const val TAG = "NFCReaderActivityWrapper"
        
        var staticCredentials: ApiCredentials? = null
        var staticCallbacks: INFCModuleCallbacks? = null
        var staticPromise: expo.modules.kotlin.Promise? = null
        private var currentFragment: NFCReaderFragment? = null
        
        fun startInlineNFCReading(
            activity: AppCompatActivity, 
            apiCredentials: ApiCredentials, 
            callbacks: INFCModuleCallbacks, 
            promise: expo.modules.kotlin.Promise
        ) {
            try {
                staticCredentials = apiCredentials
                staticCallbacks = callbacks
                staticPromise = promise
                
                activity.runOnUiThread {
                    try {
                        val fragmentManager = activity.supportFragmentManager
                        
                        val existingFragment = fragmentManager.findFragmentByTag("nfc_reader_fragment")
                        if (existingFragment != null) {
                            val removeTransaction = fragmentManager.beginTransaction()
                            removeTransaction.remove(existingFragment)
                            removeTransaction.commitNowAllowingStateLoss()
                        }
                        
                        currentFragment = InlineNFCReaderFragment()
                        
                        val transaction = fragmentManager.beginTransaction()
                        transaction.add(android.R.id.content, currentFragment!!, "nfc_reader_fragment")
                        transaction.commitAllowingStateLoss()
                        
                        fragmentManager.executePendingTransactions()
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "NFCReaderActivityWrapper - Error during fragment startup: ${e.message}", e)
                        promise.reject("NFC_ERROR", "Failed to start fragment: ${e.message}", e)
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "NFCReaderActivityWrapper - Error starting inline NFC reading: ${e.message}", e)
                promise.reject("NFC_ERROR", "Failed to start inline NFC reading: ${e.message}", e)
            }
        }
        
        fun stopInlineNFCReading(activity: AppCompatActivity) {
            try {
                activity.runOnUiThread {
                    currentFragment?.let { fragment ->
                        try {
                            val fragmentManager = activity.supportFragmentManager
                            val transaction = fragmentManager.beginTransaction()
                            transaction.remove(fragment)
                            transaction.commitAllowingStateLoss()
                            currentFragment = null
                        } catch (e: Exception) {
                            Log.e(TAG, "NFCReaderActivityWrapper - Error removing fragment: ${e.message}", e)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "NFCReaderActivityWrapper - Error stopping inline NFC reading: ${e.message}", e)
            }
        }
        
        fun handleSuccess(cardData: CardData) {
            try {
                val resultForEvent = convertCardDataToMap(cardData)
                val resultForPromise = convertCardDataToMap(cardData)
                
                staticCallbacks?.emitNFCPassportSuccess(resultForEvent)
                
                staticPromise?.let { promise ->
                    promise.resolve(resultForPromise)
                    staticPromise = null
                }
                
                currentFragment?.let { fragment ->
                    val activity = fragment.activity
                    if (activity is AppCompatActivity) {
                        activity.runOnUiThread {
                            try {
                                val fragmentManager = activity.supportFragmentManager
                                val transaction = fragmentManager.beginTransaction()
                                transaction.remove(fragment)
                                transaction.commitAllowingStateLoss()
                                currentFragment = null
                                
                                staticCredentials = null
                                staticCallbacks = null
                            } catch (e: Exception) {
                                Log.e(TAG, "NFCReaderActivityWrapper - Error removing fragment: ${e.message}", e)
                                staticCredentials = null
                                staticCallbacks = null
                            }
                        }
                    } else {
                        staticCredentials = null
                        staticCallbacks = null
                    }
                } ?: run {
                    staticCredentials = null
                    staticCallbacks = null
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "NFCReaderActivityWrapper - Error processing card data: ${e.message}", e)
                handleFailure(e)
            }
        }
        
        fun handleFailure(throwable: Throwable) {
            try {
                Log.e(TAG, "NFCReaderActivityWrapper - NFC reading failed: ${throwable.message}", throwable)
                
                staticCallbacks?.emitNFCError(throwable.message ?: "Unknown NFC error")
                
                staticPromise?.let { promise ->
                    promise.reject("NFC_ERROR", throwable.message ?: "NFC reading failed", throwable)
                    staticPromise = null
                }
                
                staticCredentials = null
                staticCallbacks = null
                
            } catch (e: Exception) {
                Log.e(TAG, "NFCReaderActivityWrapper - Error handling failure: ${e.message}", e)
            }
        }
        
        fun handleStateChange(nfcState: NFCState) {
            when (nfcState) {
                NFCState.DISABLED -> {
                    staticCallbacks?.emitNFCError("NFC is disabled on this device")
                }
                else -> {}
            }
        }
        
        private fun convertCardDataToMap(cardData: CardData): Map<String, Any> {
            val result = mutableMapOf<String, Any>()
            
            result["success"] = true
            result["transactionID"] = staticCredentials?.transactionID ?: ""
            result["timestamp"] = System.currentTimeMillis().toDouble()
            
            cardData.firstName?.let { result["firstName"] = it }
            cardData.lastName?.let { result["lastName"] = it }
            cardData.documentNumber?.let { result["documentNumber"] = it }
            cardData.nationality?.let { result["nationality"] = it }
            cardData.birthDate?.let { result["dateOfBirth"] = it }
            cardData.expireDate?.let { result["expiryDate"] = it }
            cardData.gender?.let { result["gender"] = it }
            cardData.identityNo?.let { result["personalNumber"] = it }
            cardData.birthPlace?.let { result["placeOfBirth"] = it }
            cardData.documentType?.let { result["documentType"] = it }
            cardData.address?.let { result["address"] = it }
            cardData.phoneNumber?.let { result["phoneNumber"] = it }
            cardData.email?.let { result["email"] = it }
            
            cardData.passiveAuthInfo?.let { dgResponse ->
                val paResult = when (dgResponse) {
                    DGResponse.True -> "true"
                    DGResponse.False -> "false"
                    DGResponse.Disabled -> "disabled"
                    DGResponse.NotSupported -> "notSupported"
                    else -> "disabled"
                }
                result["passedPA"] = paResult
            }
            
            cardData.activeAuthInfo?.let { dgResponse ->
                val aaResult = when (dgResponse) {
                    DGResponse.True -> "true"
                    DGResponse.False -> "false"
                    DGResponse.Disabled -> "disabled"
                    DGResponse.NotSupported -> "notSupported"
                    else -> "disabled"
                }
                result["passedAA"] = aaResult
            }
            
            cardData.rawPhoto?.let { bitmap ->
                try {
                    val base64String = staticCallbacks?.convertBitmapToBase64(bitmap)
                    result["faceImage"] = base64String ?: ""
                } catch (e: Exception) {
                    Log.e(TAG, "NFCReaderActivityWrapper - Error converting face image to base64: ${e.message}", e)
                }
            }
            
            cardData.idImg?.let { bitmap ->
                try {
                    val base64String = staticCallbacks?.convertBitmapToBase64(bitmap)
                    result["idImage"] = base64String ?: ""
                } catch (e: Exception) {
                    Log.e(TAG, "NFCReaderActivityWrapper - Error converting ID image to base64: ${e.message}", e)
                }
            }
            
            return result
        }
    }

    override fun getCallerActivity(): AppCompatActivity {
        return this
    }

    override fun getApiCredentials(): ApiCredentials {
        return staticCredentials ?: throw IllegalStateException("ApiCredentials not set - call startNFCReading first")
    }

    override fun onSuccess(cardData: CardData) {
        try {
            val resultForEvent = convertCardDataToMap(cardData)
            val resultForPromise = convertCardDataToMap(cardData)
            
            staticCallbacks?.emitNFCPassportSuccess(resultForEvent)
            
            staticPromise?.resolve(resultForPromise)
            staticPromise = null
            
            finish()
            staticCredentials = null
            staticCallbacks = null
            
        } catch (e: Exception) {
            Log.e(TAG, "NFCReaderActivityWrapper - Error processing card data: ${e.message}", e)
            onFailure(e)
        }
    }

    override fun onFailure(throwable: Throwable) {
        Log.e(TAG, "NFCReaderActivityWrapper - NFC reading failed: ${throwable.message}", throwable)
        
        staticCallbacks?.emitNFCError(throwable.message ?: "Unknown NFC error")
        
        staticPromise?.reject("NFC_ERROR", throwable.message ?: "NFC reading failed", throwable)
        staticPromise = null
        
        finish()
        staticCredentials = null
        staticCallbacks = null
    }

    override fun onState(nfcState: NFCState) {
        when (nfcState) {
            NFCState.DISABLED -> {
                staticCallbacks?.emitNFCError("NFC is disabled on this device")
            }
            else -> {}
        }
    }

    override fun onProgress(progress: Int) {
    }
    
    private fun convertCardDataToMap(cardData: CardData): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        result["success"] = true
        result["transactionID"] = staticCredentials?.transactionID ?: ""
        result["timestamp"] = System.currentTimeMillis().toDouble()
        
        cardData.firstName?.let { result["firstName"] = it }
        cardData.lastName?.let { result["lastName"] = it }
        cardData.documentNumber?.let { result["documentNumber"] = it }
        cardData.nationality?.let { result["nationality"] = it }
        cardData.birthDate?.let { result["dateOfBirth"] = it }
        cardData.expireDate?.let { result["expiryDate"] = it }
        cardData.gender?.let { result["gender"] = it }
        cardData.identityNo?.let { result["personalNumber"] = it }
        cardData.birthPlace?.let { result["placeOfBirth"] = it }
        cardData.documentType?.let { result["documentType"] = it }
        cardData.address?.let { result["address"] = it }
        cardData.phoneNumber?.let { result["phoneNumber"] = it }
        cardData.email?.let { result["email"] = it }
        
        cardData.passiveAuthInfo?.let { dgResponse ->
            val paResult = when (dgResponse) {
                DGResponse.True -> "true"
                DGResponse.False -> "false"
                DGResponse.Disabled -> "disabled"
                DGResponse.NotSupported -> "notSupported"
                else -> "disabled"
            }
            result["passedPA"] = paResult
        }
        
        cardData.activeAuthInfo?.let { dgResponse ->
            val aaResult = when (dgResponse) {
                DGResponse.True -> "true"
                DGResponse.False -> "false"
                DGResponse.Disabled -> "disabled"
                DGResponse.NotSupported -> "notSupported"
                else -> "disabled"
            }
            result["passedAA"] = aaResult
        }
        
        cardData.rawPhoto?.let { bitmap ->
            try {
                val base64String = staticCallbacks?.convertBitmapToBase64(bitmap)
                result["faceImage"] = base64String ?: ""
            } catch (e: Exception) {
                Log.e(TAG, "NFCReaderActivityWrapper - Error converting face image to base64: ${e.message}", e)
            }
        }
        
        cardData.idImg?.let { bitmap ->
            try {
                val base64String = staticCallbacks?.convertBitmapToBase64(bitmap)
                result["idImage"] = base64String ?: ""
            } catch (e: Exception) {
                Log.e(TAG, "NFCReaderActivityWrapper - Error converting ID image to base64: ${e.message}", e)
            }
        }
        
        return result
    }
}

class InlineNFCReaderFragment : NFCReaderFragment() {
    
    override fun getCallerActivity(): AppCompatActivity {
        return activity as? AppCompatActivity 
            ?: throw IllegalStateException("Fragment must be attached to an AppCompatActivity")
    }
    
    override fun getApiCredentials(): ApiCredentials {
        return NFCReaderActivityWrapper.staticCredentials 
            ?: throw IllegalStateException("ApiCredentials not set - fragment should be removed after success")
    }
    
    override fun onSuccess(cardData: CardData) {
        NFCReaderActivityWrapper.handleSuccess(cardData)
    }
    
    override fun onFailure(throwable: Throwable) {
        NFCReaderActivityWrapper.handleFailure(throwable)
    }
    
    override fun onState(nfcState: NFCState) {
        NFCReaderActivityWrapper.handleStateChange(nfcState)
    }
    
    override fun onProgress(progress: Int) {
    }
    
    override fun onResume() {
        try {
            if (NFCReaderActivityWrapper.staticCredentials != null) {
                super.onResume()
            } else {
                activity?.let { activity ->
                    if (activity is AppCompatActivity) {
                        activity.runOnUiThread {
                            try {
                                val fragmentManager = activity.supportFragmentManager
                                val transaction = fragmentManager.beginTransaction()
                                transaction.remove(this)
                                transaction.commitAllowingStateLoss()
                            } catch (e: Exception) {
                                Log.e("InlineNFCReaderFragment", "InlineNFCReaderFragment - Error removing fragment: ${e.message}", e)
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("InlineNFCReaderFragment", "InlineNFCReaderFragment - Error in onResume: ${e.message}", e)
            activity?.let { activity ->
                if (activity is AppCompatActivity) {
                    activity.runOnUiThread {
                        try {
                            val fragmentManager = activity.supportFragmentManager
                            val transaction = fragmentManager.beginTransaction()
                            transaction.remove(this)
                            transaction.commitAllowingStateLoss()
                        } catch (removeException: Exception) {
                            Log.e("InlineNFCReaderFragment", "InlineNFCReaderFragment - Error removing fragment after exception: ${removeException.message}", removeException)
                        }
                    }
                }
            }
        }
    }
    
    override fun onPause() {
        super.onPause()
    }
}