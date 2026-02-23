package expo.modules.ocr

import android.os.Parcel
import android.os.Parcelable
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import expo.modules.kotlin.Promise
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardFragment
import io.udentify.android.ocr.activities.CardRecognizer
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.PlaceholderTemplate
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.model.CardOCRMessage
import io.udentify.android.ocr.model.IQAFeedback
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse
import java.util.*

class OCRCardRecognizer(
    private val activity: AppCompatActivity,
    private val serverURL: String,
    private val transactionID: String,
    private val documentType: String,
    private val country: String = "TUR",
    private val originalDocumentSide: String = "BOTH",
    private val ocrModule: ExpoOCRModule? = null,
    private val uiConfiguration: Map<String, Any>? = null,
    private val promise: Promise? = null
) : CardRecognizer {

    companion object {
        private const val TAG = "OCRCardRecognizer"
        
        @JvmField
        val CREATOR = object : Parcelable.Creator<OCRCardRecognizer> {
            override fun createFromParcel(parcel: Parcel): OCRCardRecognizer {
                return OCRCardRecognizer(parcel)
            }

            override fun newArray(size: Int): Array<OCRCardRecognizer?> {
                return arrayOfNulls(size)
            }
        }
    }
    
    private var storedFrontSideImage: String? = null
    
    constructor(parcel: Parcel) : this(
        activity = AppCompatActivity(),
        serverURL = parcel.readString() ?: "",
        transactionID = parcel.readString() ?: "",
        documentType = parcel.readString() ?: "ID_CARD",
        country = parcel.readString() ?: "TUR",
        originalDocumentSide = parcel.readString() ?: "BOTH",
        ocrModule = null,
        uiConfiguration = null,
        promise = null
    )

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeString(serverURL)
        parcel.writeString(transactionID)
        parcel.writeString(documentType)
        parcel.writeString(country)
        parcel.writeString(originalDocumentSide)
    }

    override fun describeContents(): Int {
        return 0
    }

    override fun getCredentials(): CardRecognizerCredentials {
        Log.d(TAG, "OCRCardRecognizer - Creating credentials for transaction: $transactionID")
        
        val docType = when (documentType.uppercase()) {
            "ID_CARD" -> DocumentType.OCR_ID_UPLOAD
            "PASSPORT" -> DocumentType.OCR_PASSPORT_UPLOAD
            "DRIVER_LICENSE", "DRIVE_LICENCE" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
            else -> DocumentType.OCR_ID_UPLOAD
        }
        
        // Convert country code using shared mapper
        val mappedCountryCode = CountryCodeMapper.toCountryCode(country)
        Log.d(TAG, "OCRCardRecognizer - Country: $country -> $mappedCountryCode")
        
        val builder = CardRecognizerCredentials.Builder()
            .serverURL(serverURL)
            .transactionID(transactionID)
            .userID(Date().time.toString())
            .docType(docType)
            .countryCode(mappedCountryCode)
            
        uiConfiguration?.let { config ->
            Log.d(TAG, "OCRCardRecognizer - Applying UI configuration with ${config.size} parameters")
            
            config["detectionAccuracy"]?.let { 
                val value = (it as? Int ?: 7)
                builder.hardwareSupport(value)
            } ?: run {
                builder.hardwareSupport(7)
            }
            
            config["blurCoefficient"]?.let { 
                val value = (it as? Double ?: 0.0).toFloat()
                builder.blurCoefficient(value)
            } ?: run {
                builder.blurCoefficient(0.0f)
            }
            
            config["manualCapture"]?.let {
                val value = it as? Boolean ?: false
                builder.manualCapture(value)
            } ?: run {
                builder.manualCapture(false)
            }
            
            config["faceDetection"]?.let {
                val value = it as? Boolean ?: false
                builder.faceDetection(value)
            } ?: run {
                builder.faceDetection(false)
            }
            
            config["isDocumentLivenessActive"]?.let {
                val value = it as? Boolean ?: false
                builder.isDocumentLivenessActive(value)
            } ?: run {
                builder.isDocumentLivenessActive(false)
            }
            
            config["reviewScreenEnabled"]?.let {
                val value = it as? Boolean ?: true
                builder.reviewScreenEnabled(value)
            } ?: run {
                builder.reviewScreenEnabled(true)
            }
            
            config["footerViewHidden"]?.let {
                val value = it as? Boolean ?: false
                builder.footerViewHidden(value)
            } ?: run {
                builder.footerViewHidden(false)
            }
            
            config["placeholderTemplate"]?.let { templateString ->
                val template = when ((templateString as? String)?.lowercase()) {
                    "hidden" -> PlaceholderTemplate.hidden
                    "defaultstyle", "default" -> PlaceholderTemplate.defaultStyle
                    "countryspecificstyle", "countryspecific" -> PlaceholderTemplate.countrySpecificStyle
                    else -> PlaceholderTemplate.defaultStyle
                }
                builder.placeholderTemplate(template)
            } ?: run {
                builder.placeholderTemplate(PlaceholderTemplate.defaultStyle)
            }
            
            // Check for both iqaEnabled and isIQAServiceEnabled (iOS naming)
            val iqaEnabledValue = config["iqaEnabled"] as? Boolean 
                ?: config["isIQAServiceEnabled"] as? Boolean 
                ?: true
            builder.iqaEnabled(iqaEnabledValue)
            Log.d(TAG, "OCRCardRecognizer - Applied iqaEnabled: $iqaEnabledValue")
            
            config["iqaSuccessAutoDismissDelay"]?.let {
                val value = it as? Int ?: -1
                builder.iqaSuccessAutoDismissDelay(value)
            } ?: run {
                builder.iqaSuccessAutoDismissDelay(-1)
            }
            
            config["requestTimeout"]?.let {
                val value = (it as? Double ?: 30.0).toInt()
                builder.requestTimeout(value)
            } ?: run {
                builder.requestTimeout(30)
            }
            
            builder.successDelay(0.2f)
            
        } ?: run {
            builder.successDelay(0.2f)
                .hardwareSupport(7)
                .faceDetection(false)
                .blurCoefficient(0.0f)
                .manualCapture(false)
                .isDocumentLivenessActive(false)
                .reviewScreenEnabled(true)
                .footerViewHidden(false)
                .placeholderTemplate(PlaceholderTemplate.defaultStyle)
                .iqaEnabled(true)
                .iqaSuccessAutoDismissDelay(-1)
                .requestTimeout(30)
        }
        
        return builder.build()
    }

    override fun frontSideImage(frontSideImage: String?) {
        Log.d(TAG, "OCRCardRecognizer - Front side image captured")
        storedFrontSideImage = frontSideImage
        ocrModule?.storeDocumentScanImages(frontSideImage ?: "", "")
        
        if (originalDocumentSide.uppercase() in listOf("BOTH", "BOTHSIDES")) {
            activity.runOnUiThread {
                try {
                    val backSideCardRecognizer = OCRCardRecognizer(
                        activity = activity,
                        serverURL = serverURL,
                        transactionID = transactionID,
                        documentType = documentType,
                        country = country,
                        originalDocumentSide = "BACK",
                        ocrModule = ocrModule,
                        uiConfiguration = uiConfiguration,
                        promise = promise
                    )
                    
                    backSideCardRecognizer.storedFrontSideImage = frontSideImage
                    
                    // Apply orientation from UI configuration
                    val cardOrientation = if (uiConfiguration?.get("orientation") == "vertical") true else false
                    
                    val backSideCardFragment = CardFragment.newInstance(
                        Process.backSide,
                        cardOrientation,
                        backSideCardRecognizer
                    )
                    
                    val fragmentManager = activity.supportFragmentManager
                    val transaction = fragmentManager.beginTransaction()
                    transaction.replace(android.R.id.content, backSideCardFragment)
                    transaction.addToBackStack(null)
                    transaction.commit()
                } catch (e: Exception) {
                    Log.e(TAG, "OCRCardRecognizer - Error starting back side scanning: ${e.message}", e)
                    promise?.reject("OCR_ERROR", "Failed to start back side scanning: ${e.message}", e)
                }
            }
        } else {
            dismissCameraFragment()
            promise?.resolve(true)
        }
    }

    override fun backSideImage(backSideImage: String?) {
        Log.d(TAG, "OCRCardRecognizer - Back side image captured")
        ocrModule?.storeDocumentScanImages(storedFrontSideImage ?: "", backSideImage ?: "")
        dismissCameraFragment()
        promise?.resolve(true)
    }

    override fun cardScanFinished() {
        Log.d(TAG, "OCRCardRecognizer - Card scan finished")
    }
    
    private fun dismissCameraFragment() {
        try {
            activity.runOnUiThread {
                val fragmentManager = activity.supportFragmentManager
                
                while (fragmentManager.backStackEntryCount > 0) {
                    fragmentManager.popBackStackImmediate()
                }
                
                val fragmentsToRemove = fragmentManager.fragments.filter { fragment ->
                    fragment.javaClass.simpleName.contains("CardFragment") || 
                    fragment.javaClass.name.contains("CardFragment")
                }
                
                if (fragmentsToRemove.isNotEmpty()) {
                    val transaction = fragmentManager.beginTransaction()
                    fragmentsToRemove.forEach { fragment ->
                        transaction.remove(fragment)
                    }
                    transaction.commitAllowingStateLoss()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "OCRCardRecognizer - Error dismissing camera fragment: ${e.message}", e)
        }
    }

    override fun onResult(cardOCRMessage: CardOCRMessage?) {
        if (originalDocumentSide == "API_ONLY") {
            if (cardOCRMessage == null) {
                promise?.reject("OCR_ERROR", "No OCR result received", null)
                return
            }
            
            try {
                val result = convertCardOCRMessageToMap(cardOCRMessage)
                promise?.resolve(result)
            } catch (e: Exception) {
                Log.e(TAG, "OCRCardRecognizer - Error converting OCR result: ${e.message}", e)
                promise?.reject("OCR_ERROR", "Error processing OCR result: ${e.message}", e)
            }
        }
    }

    override fun onFailure(error: String?) {
        if (originalDocumentSide == "API_ONLY") {
            Log.e(TAG, "OCRCardRecognizer - OCR API Error: $error")
            promise?.reject("OCR_ERROR", error ?: "OCR processing failed", null)
        } else {
            dismissCameraFragment()
        }
    }

    override fun onPhotoTaken() {
        Log.d(TAG, "OCRCardRecognizer - Photo taken")
    }

    override fun didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse?) {
        if (response == null) {
            promise?.reject("OCR_AND_LIVENESS_ERROR", "No document liveness response received", null)
            return
        }
        
        try {
            val result = convertOCRAndDocumentLivenessResponseToMap(response)
            promise?.resolve(result)
        } catch (e: Exception) {
            Log.e(TAG, "OCRCardRecognizer - Error converting liveness result: ${e.message}", e)
            promise?.reject("OCR_AND_LIVENESS_ERROR", "Error processing liveness result: ${e.message}", e)
        }
    }

    override fun onIqaResult(iqaFeedback: IQAFeedback?, process: Process?) {
        Log.d(TAG, "OCRCardRecognizer - IQA Result: feedback=${iqaFeedback?.name}, process=${process?.name}")
        // IQA result callback - can be used to send events back to JS if needed
    }

    private fun convertCardOCRMessageToMap(cardOCRMessage: CardOCRMessage): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        result["success"] = cardOCRMessage.getFailed() != true
        result["transactionID"] = transactionID
        result["timestamp"] = System.currentTimeMillis().toDouble()
        result["documentType"] = documentType
        
        result["faceImage"] = cardOCRMessage.getFcaseImg() ?: ""
        result["name"] = cardOCRMessage.getName() ?: ""
        result["surname"] = cardOCRMessage.getSurname() ?: ""
        result["identityNo"] = cardOCRMessage.getIdentityNo() ?: ""
        result["birthDate"] = cardOCRMessage.getBirthDate() ?: ""
        result["gender"] = cardOCRMessage.getGender() ?: ""
        result["nationality"] = cardOCRMessage.getNationality() ?: ""
        result["expireDate"] = cardOCRMessage.getExpireDate() ?: ""
        result["documentID"] = cardOCRMessage.getDocumentId() ?: ""
        result["documentType"] = cardOCRMessage.getDocumentType() ?: ""
        result["documentCountry"] = cardOCRMessage.getDocumentCountry() ?: ""
        result["documentIssuer"] = cardOCRMessage.getDocumentIssuer() ?: ""
        result["motherName"] = cardOCRMessage.getMotherName() ?: ""
        result["fatherName"] = cardOCRMessage.getFatherName() ?: ""
        result["dateOfIssue"] = cardOCRMessage.getDateOfIssue() ?: ""
        result["mrzString"] = cardOCRMessage.getMrzString() ?: ""
        
        result["ocrPhotoExists"] = cardOCRMessage.getOcrPhotoExists() ?: "false"
        result["ocrSignatureExists"] = cardOCRMessage.getOcrSignatureExists() ?: "false"
        result["ocrDocumentExpired"] = cardOCRMessage.getOcrDocumentExpired() ?: "false"
        result["ocrIdValid"] = cardOCRMessage.getOcrIdValid() ?: "false"
        
        val extractedData = mutableMapOf<String, Any>()
        extractedData["firstName"] = cardOCRMessage.getName() ?: ""
        extractedData["lastName"] = cardOCRMessage.getSurname() ?: ""
        extractedData["documentNumber"] = cardOCRMessage.getDocumentId() ?: ""
        extractedData["identityNo"] = cardOCRMessage.getIdentityNo() ?: ""
        extractedData["expiryDate"] = cardOCRMessage.getExpireDate() ?: ""
        extractedData["birthDate"] = cardOCRMessage.getBirthDate() ?: ""
        extractedData["nationality"] = cardOCRMessage.getNationality() ?: ""
        extractedData["gender"] = cardOCRMessage.getGender() ?: ""
        extractedData["documentIssuer"] = cardOCRMessage.getDocumentIssuer() ?: ""
        extractedData["motherName"] = cardOCRMessage.getMotherName() ?: ""
        extractedData["fatherName"] = cardOCRMessage.getFatherName() ?: ""
        extractedData["isDocumentExpired"] = cardOCRMessage.getOcrDocumentExpired() == "true"
        extractedData["isIDValid"] = cardOCRMessage.getOcrIdValid() == "true"
        extractedData["hasPhoto"] = cardOCRMessage.getOcrPhotoExists() == "true"
        extractedData["hasSignature"] = cardOCRMessage.getOcrSignatureExists() == "true"
        
        result["extractedData"] = extractedData
        
        return result
    }

    private fun convertOCRAndDocumentLivenessResponseToMap(response: OCRAndDocumentLivenessResponse): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        result["success"] = !response.isFailed()
        result["transactionID"] = transactionID
        result["timestamp"] = System.currentTimeMillis().toDouble()
        
        if (response.getErrorCode() != null) {
            result["error"] = response.getErrorCode()
        }
        
        if (response.getOcrData() != null) {
            val ocrData = convertCardOCRMessageToMap(response.getOcrData())
            result["ocrData"] = ocrData
        }
        
        if (response.getDocumentLivenessDataFront() != null) {
            result["frontSideProbability"] = 0.85
        }
        
        if (response.getDocumentLivenessDataBack() != null) {
            result["backSideProbability"] = 0.85
        }
        
        return result
    }
}
