package expo.modules.ocr

import android.graphics.Bitmap
import android.os.Parcel
import android.os.Parcelable
import android.util.Base64
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import expo.modules.kotlin.Promise
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardRecognizer
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.HologramStages
import io.udentify.android.ocr.activities.PlaceholderTemplate
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.model.CardOCRMessage
import io.udentify.android.ocr.model.HologramResponse
import io.udentify.android.ocr.model.IQAFeedback
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse
import java.io.ByteArrayOutputStream
import java.util.*

class HologramRecognizer(
    private val activity: AppCompatActivity,
    private val serverURL: String,
    private val transactionID: String,
    private val ocrModule: ExpoOCRModule? = null,
    private val promise: Promise? = null
) : CardRecognizer, HologramStages {

    companion object {
        private const val TAG = "HologramRecognizer"
        
        @JvmField
        val CREATOR = object : Parcelable.Creator<HologramRecognizer> {
            override fun createFromParcel(parcel: Parcel): HologramRecognizer {
                return HologramRecognizer(parcel)
            }

            override fun newArray(size: Int): Array<HologramRecognizer?> {
                return arrayOfNulls(size)
            }
        }
    }
    
    constructor(parcel: Parcel) : this(
        activity = AppCompatActivity(),
        serverURL = parcel.readString() ?: "",
        transactionID = parcel.readString() ?: "",
        ocrModule = null,
        promise = null
    )

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeString(serverURL)
        parcel.writeString(transactionID)
    }

    override fun describeContents(): Int {
        return 0
    }

    override fun getCredentials(): CardRecognizerCredentials {
        return CardRecognizerCredentials.Builder()
            .serverURL(serverURL)
            .transactionID(transactionID)
            .userID(Date().time.toString())
            .docType(DocumentType.OCR_ID_UPLOAD)
            .countryCode("TUR")
            .successDelay(0.2f)
            .hardwareSupport(7)
            .faceDetection(false)
            .blurCoefficient(0.0f)
            .manualCapture(false)
            .isDocumentLivenessActive(false)
            .reviewScreenEnabled(true)
            .footerViewHidden(false)
            .placeholderTemplate(PlaceholderTemplate.defaultStyle)
            .build()
    }

    override fun frontSideImage(frontSideImage: String?) {
    }

    override fun backSideImage(backSideImage: String?) {
    }

    override fun cardScanFinished() {
    }

    override fun onResult(cardOCRMessage: CardOCRMessage?) {
    }

    override fun onFailure(error: String?) {
        Log.e(TAG, "HologramRecognizer - Hologram failed: $error")
        dismissCameraFragment()
        ocrModule?.emitHologramError(error ?: "Hologram scanning failed")
        promise?.reject("HOLOGRAM_ERROR", error ?: "Hologram scanning failed", null)
    }

    override fun onPhotoTaken() {
    }

    override fun didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse?) {
    }

    override fun onIqaResult(feedback: IQAFeedback?, process: Process?) {
    }

    override fun hologramStarted() {
    }

    override fun hologramFinished() {
        ocrModule?.emitHologramVideoRecorded(listOf("hologram_video_recorded"))
    }

    override fun hologramResult(hologramResponse: HologramResponse?) {
        if (hologramResponse == null) {
            Log.e(TAG, "HologramRecognizer - No hologram result received")
            ocrModule?.emitHologramError("No hologram result received")
            dismissCameraFragment()
            promise?.reject("HOLOGRAM_ERROR", "No hologram result received", null)
            return
        }
        
        try {
            val result = convertHologramResponseToMap(hologramResponse)
            ocrModule?.emitHologramComplete(result)
            dismissCameraFragment()
            promise?.resolve(true)
        } catch (e: Exception) {
            Log.e(TAG, "HologramRecognizer - Error converting hologram result: ${e.message}", e)
            ocrModule?.emitHologramError("Error processing hologram result: ${e.message}")
            dismissCameraFragment()
            promise?.reject("HOLOGRAM_ERROR", "Error processing hologram result: ${e.message}", e)
        }
    }

    override fun hologramFail(hologramResponse: HologramResponse?) {
        Log.e(TAG, "HologramRecognizer - Hologram failed")
        val errorMessage = hologramResponse?.getMessage() ?: "Hologram verification failed"
        ocrModule?.emitHologramError(errorMessage)
        dismissCameraFragment()
        promise?.reject("HOLOGRAM_ERROR", errorMessage, null)
    }
    
    private fun dismissCameraFragment() {
        try {
            activity.runOnUiThread {
                val fragmentManager = activity.supportFragmentManager
                
                while (fragmentManager.backStackEntryCount > 0) {
                    fragmentManager.popBackStackImmediate()
                }
                
                val fragmentsToRemove = fragmentManager.fragments.filter { fragment ->
                    fragment.javaClass.simpleName.contains("HologramFragment") || 
                    fragment.javaClass.name.contains("HologramFragment")
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
            Log.e(TAG, "HologramRecognizer - Error dismissing camera fragment: ${e.message}", e)
        }
    }

    private fun convertHologramResponseToMap(response: HologramResponse): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        result["success"] = response.getMessage() == null || !response.getMessage().contains("error", true)
        result["transactionID"] = transactionID
        result["timestamp"] = System.currentTimeMillis().toDouble()
        
        result["idNumber"] = response.getHologramDocumentId() ?: ""
        result["hologramExists"] = response.getOcrHologramCheck() ?: false
        result["ocrIdAndHologramIdMatch"] = response.getOcrHoloIdMatch() ?: false
        result["ocrFaceAndHologramFaceMatch"] = response.getOcrHoloFaceMatch() ?: false
        
        if (response.getHologramFace() != null) {
            try {
                val base64String = convertBitmapToBase64(response.getHologramFace())
                result["hologramFaceImageBase64"] = base64String
            } catch (e: Exception) {
                Log.e(TAG, "Error converting hologram face image to base64: ${e.message}", e)
            }
        }
        
        if (response.getMessage() != null) {
            result["error"] = response.getMessage()
        }
        
        return result
    }

    private fun convertBitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
        val byteArray = outputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }
}
