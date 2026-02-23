package expo.modules.udentifycore

import android.util.Base64
import android.util.Log
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import io.udentify.android.commons.model.UdentifySettingsProvider
import io.udentify.android.commons.model.LocalizationLanguage
import io.udentify.android.commons.interfaces.LocalizationInstantiationListener
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.Locale
import expo.modules.kotlin.Promise

class UdentifyCoreModule : Module() {
  companion object {
    private const val TAG = "UdentifyCoreModule"
  }
  
  override fun definition() = ModuleDefinition {
    Name("UdentifyCore")

    Function("getVersion") {
      return@Function "1.0.0"
    }
    
    Function("getFrameworkInfo") {
      return@Function mapOf(
        "ios" to listOf("UdentifyCommons.xcframework"),
        "android" to listOf("commons-25.2.1.aar")
      )
    }
    
    // MARK: - SSL Pinning Functions
    
    AsyncFunction("loadCertificateFromAssets") { certificateName: String, extension: String ->
      try {
        Log.d(TAG, "loadCertificateFromAssets called: $certificateName.$extension")
        
        val context = appContext.reactContext ?: throw Exception("React context is null")
        
        // Use UdentifySettingsProvider to load the certificate
        val certificate = UdentifySettingsProvider.loadDERCertificateData(
          context,
          certificateName,
          extension
        )
        
        if (certificate == null) {
          val errorMessage = "Failed to load certificate '$certificateName.$extension' from assets. Ensure the certificate file exists in the assets folder and is in DER format."
          Log.e(TAG, "Error: $errorMessage")
          throw Exception(errorMessage)
        }
        
        Log.d(TAG, "Certificate loaded, subject: ${certificate.subjectDN}")
        
        // Set the certificate using UdentifySettingsProvider
        UdentifySettingsProvider.setSSLCertificate(certificate)
        
        Log.d(TAG, "Certificate set successfully")
        return@AsyncFunction true
        
      } catch (e: Exception) {
        Log.e(TAG, "Exception: ${e.message}", e)
        throw e
      }
    }
    
    AsyncFunction("setSSLCertificateBase64") { certificateBase64: String ->
      try {
        Log.d(TAG, "setSSLCertificateBase64 called")
        
        // Decode base64 string
        val certificateBytes = Base64.decode(certificateBase64, Base64.DEFAULT)
        
        Log.d(TAG, "Certificate data decoded, size: ${certificateBytes.size} bytes")
        
        // Convert bytes to X509Certificate
        val certificateFactory = CertificateFactory.getInstance("X.509")
        val certificate = certificateFactory.generateCertificate(
          certificateBytes.inputStream()
        ) as X509Certificate
        
        Log.d(TAG, "Certificate parsed, subject: ${certificate.subjectDN}")
        
        // Set the certificate using UdentifySettingsProvider
        UdentifySettingsProvider.setSSLCertificate(certificate)
        
        Log.d(TAG, "Certificate set successfully")
        return@AsyncFunction true
        
      } catch (e: Exception) {
        Log.e(TAG, "Exception: ${e.message}", e)
        throw e
      }
    }
    
    AsyncFunction("removeSSLCertificate") {
      try {
        Log.d(TAG, "removeSSLCertificate called")
        
        // Remove certificate using UdentifySettingsProvider
        UdentifySettingsProvider.removeSSLCertificate()
        
        Log.d(TAG, "Certificate removed successfully")
        return@AsyncFunction true
        
      } catch (e: Exception) {
        Log.e(TAG, "Exception: ${e.message}", e)
        throw e
      }
    }
    
    AsyncFunction("getSSLCertificateBase64") {
      try {
        Log.d(TAG, "getSSLCertificateBase64 called")
        
        // Get certificate using UdentifySettingsProvider
        val certificate = UdentifySettingsProvider.getSSLCertificate()
        
        if (certificate == null) {
          Log.d(TAG, "No certificate is currently set")
          return@AsyncFunction null
        }
        
        // Convert certificate to base64
        val certificateBytes = certificate.encoded
        val base64String = Base64.encodeToString(certificateBytes, Base64.NO_WRAP)
        
        Log.d(TAG, "Certificate retrieved, size: ${certificateBytes.size} bytes")
        return@AsyncFunction base64String
        
      } catch (e: Exception) {
        Log.e(TAG, "Exception: ${e.message}", e)
        throw e
      }
    }
    
    AsyncFunction("isSSLPinningEnabled") {
      try {
        Log.d(TAG, "isSSLPinningEnabled called")
        
        // Check SSL pinning status using UdentifySettingsProvider
        val isEnabled = UdentifySettingsProvider.isSSLPinningEnabled()
        
        Log.d(TAG, "SSL pinning enabled: $isEnabled")
        return@AsyncFunction isEnabled
        
      } catch (e: Exception) {
        Log.e(TAG, "Exception: ${e.message}", e)
        throw e
      }
    }
    
    // MARK: - Remote Language Pack Functions
    
    AsyncFunction("instantiateServerBasedLocalization") { language: String, serverUrl: String, transactionId: String, requestTimeout: Double, promise: Promise ->
      try {
        Log.d(TAG, "UdentifyCoreModule - instantiateServerBasedLocalization called for language: $language")
        
        val languageEnum = mapStringToLocalizationLanguage(language)
        if (languageEnum == null) {
          val errorMessage = "Invalid language code: $language"
          Log.e(TAG, "UdentifyCoreModule - Error: $errorMessage")
          promise.reject("INVALID_LANGUAGE", errorMessage, null)
          return@AsyncFunction
        }
        
        Log.d(TAG, "UdentifyCoreModule - Mapped language to enum: $languageEnum")
        
        val context = appContext.reactContext
        if (context == null) {
          promise.reject("NO_CONTEXT", "React context is null", null)
          return@AsyncFunction
        }
        
        UdentifySettingsProvider.instantiateServerBasedLocalization(
          context,
          languageEnum,
          serverUrl,
          transactionId,
          LocalizationInstantiationListener { error ->
            if (error == null) {
              Log.d(TAG, "UdentifyCoreModule - Server-based localization instantiated successfully")
              promise.resolve(null)
            } else {
              Log.e(TAG, "UdentifyCoreModule - Error instantiating localization: ${error.message}")
              promise.reject("LOCALIZATION_ERROR", error.message ?: "Unknown error", error)
            }
          }
        )
        
      } catch (e: Exception) {
        Log.e(TAG, "UdentifyCoreModule - Exception: ${e.message}", e)
        promise.reject("EXCEPTION", e.message ?: "Unknown exception", e)
      }
    }
    
    AsyncFunction("getLocalizationMap") {
      try {
        Log.d(TAG, "UdentifyCoreModule - getLocalizationMap called")
        
        val localizationMap = UdentifySettingsProvider.getLocalizationMap()
        
        if (localizationMap == null || localizationMap.isEmpty()) {
          Log.d(TAG, "UdentifyCoreModule - No localization map available")
          return@AsyncFunction null
        }
        
        Log.d(TAG, "UdentifyCoreModule - Localization map retrieved with ${localizationMap.size} entries")
        return@AsyncFunction localizationMap
        
      } catch (e: Exception) {
        Log.e(TAG, "UdentifyCoreModule - Exception: ${e.message}", e)
        throw e
      }
    }
    
    AsyncFunction("clearLocalizationCache") { language: String, promise: Promise ->
      try {
        Log.d(TAG, "UdentifyCoreModule - clearLocalizationCache called for language: $language")
        
        val languageEnum = mapStringToLocalizationLanguage(language)
        if (languageEnum == null) {
          val errorMessage = "Invalid language code: $language"
          Log.e(TAG, "UdentifyCoreModule - Error: $errorMessage")
          promise.reject("INVALID_LANGUAGE", errorMessage, null)
          return@AsyncFunction
        }
        
        val context = appContext.reactContext
        if (context == null) {
          promise.reject("NO_CONTEXT", "React context is null", null)
          return@AsyncFunction
        }
        
        UdentifySettingsProvider.clearLocalizationCache(context, languageEnum)
        
        Log.d(TAG, "UdentifyCoreModule - Localization cache cleared successfully")
        promise.resolve(null)
        
      } catch (e: Exception) {
        Log.e(TAG, "UdentifyCoreModule - Exception: ${e.message}", e)
        promise.reject("EXCEPTION", e.message ?: "Unknown exception", e)
      }
    }
    
    AsyncFunction("mapSystemLanguageToEnum") { promise: Promise ->
      try {
        Log.d(TAG, "UdentifyCoreModule - mapSystemLanguageToEnum called")
        
        val systemLanguage = Locale.getDefault().language.uppercase()
        Log.d(TAG, "UdentifyCoreModule - System language code: $systemLanguage")
        
        val languageEnum = mapStringToLocalizationLanguage(systemLanguage)
        
        if (languageEnum == null) {
          Log.d(TAG, "UdentifyCoreModule - System language not supported, defaulting to null")
          promise.resolve(null)
          return@AsyncFunction
        }
        
        val languageString = mapLocalizationLanguageToString(languageEnum)
        Log.d(TAG, "UdentifyCoreModule - System language mapped to: $languageString")
        promise.resolve(languageString)
        
      } catch (e: Exception) {
        Log.e(TAG, "UdentifyCoreModule - Exception: ${e.message}", e)
        promise.reject("EXCEPTION", e.message ?: "Unknown exception", e)
      }
    }
  }
  
  private fun mapStringToLocalizationLanguage(language: String): LocalizationLanguage? {
    return when (language.uppercase()) {
      "EN" -> LocalizationLanguage.EN
      "ES" -> LocalizationLanguage.ES
      "FR" -> LocalizationLanguage.FR
      "DE" -> LocalizationLanguage.DE
      "IT" -> LocalizationLanguage.IT
      "PT" -> LocalizationLanguage.PT
      "RU" -> LocalizationLanguage.RU
      "ZH" -> LocalizationLanguage.ZH
      "JA" -> LocalizationLanguage.JA
      "KO" -> LocalizationLanguage.KO
      "AR" -> LocalizationLanguage.AR
      "HI" -> LocalizationLanguage.HI
      "BN" -> LocalizationLanguage.BN
      "PA" -> LocalizationLanguage.PA
      "UR" -> LocalizationLanguage.UR
      "ID" -> LocalizationLanguage.ID
      "MS" -> LocalizationLanguage.MS
      "SW" -> LocalizationLanguage.SW
      "TA" -> LocalizationLanguage.TA
      "TR" -> LocalizationLanguage.TR
      else -> null
    }
  }
  
  private fun mapLocalizationLanguageToString(language: LocalizationLanguage): String {
    return when (language) {
      LocalizationLanguage.EN -> "EN"
      LocalizationLanguage.ES -> "ES"
      LocalizationLanguage.FR -> "FR"
      LocalizationLanguage.DE -> "DE"
      LocalizationLanguage.IT -> "IT"
      LocalizationLanguage.PT -> "PT"
      LocalizationLanguage.RU -> "RU"
      LocalizationLanguage.ZH -> "ZH"
      LocalizationLanguage.JA -> "JA"
      LocalizationLanguage.KO -> "KO"
      LocalizationLanguage.AR -> "AR"
      LocalizationLanguage.HI -> "HI"
      LocalizationLanguage.BN -> "BN"
      LocalizationLanguage.PA -> "PA"
      LocalizationLanguage.UR -> "UR"
      LocalizationLanguage.ID -> "ID"
      LocalizationLanguage.MS -> "MS"
      LocalizationLanguage.SW -> "SW"
      LocalizationLanguage.TA -> "TA"
      LocalizationLanguage.TR -> "TR"
    }
  }
}
