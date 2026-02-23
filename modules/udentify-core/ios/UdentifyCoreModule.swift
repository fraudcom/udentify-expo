import ExpoModulesCore

public class UdentifyCoreModule: Module {
  // Singleton instance of SSLPinningManager
  private let sslPinningManager = SSLPinningManager()
  
  // Singleton instance of LocalizationManager
  private let localizationManager = LocalizationManager()
  
  public func definition() -> ModuleDefinition {
    Name("UdentifyCore")

    Function("getVersion") { () -> String in
      return "1.0.0"
    }
    
    Function("getFrameworkInfo") { () -> [String: [String]] in
      return [
        "ios": ["UdentifyCommons.xcframework"],
        "android": ["commons-25.3.0.aar"]
      ]
    }
    
    // MARK: - SSL Pinning Functions
    
    AsyncFunction("loadCertificateFromAssets") { (certificateName: String, extension: String, promise: Promise) in
      self.sslPinningManager.loadCertificateFromAssets(
        certificateName,
        extension: `extension`,
        completion: { success, error in
          if let error = error {
            promise.reject("LOAD_CERT_ERROR", error.localizedDescription)
          } else {
            promise.resolve(success)
          }
        }
      )
    }
    
    AsyncFunction("setSSLCertificateBase64") { (certificateBase64: String, promise: Promise) in
      self.sslPinningManager.setSSLCertificateBase64(
        certificateBase64,
        completion: { success, error in
          if let error = error {
            promise.reject("SET_CERT_ERROR", error.localizedDescription)
          } else {
            promise.resolve(success)
          }
        }
      )
    }
    
    AsyncFunction("removeSSLCertificate") { (promise: Promise) in
      self.sslPinningManager.removeSSLCertificate { success, error in
        if let error = error {
          promise.reject("REMOVE_CERT_ERROR", error.localizedDescription)
        } else {
          promise.resolve(success)
        }
      }
    }
    
    AsyncFunction("getSSLCertificateBase64") { (promise: Promise) in
      self.sslPinningManager.getSSLCertificateBase64 { certificateBase64, error in
        if let error = error {
          promise.reject("GET_CERT_ERROR", error.localizedDescription)
        } else {
          promise.resolve(certificateBase64)
        }
      }
    }
    
    AsyncFunction("isSSLPinningEnabled") { (promise: Promise) in
      self.sslPinningManager.isSSLPinningEnabled { enabled, error in
        if let error = error {
          promise.reject("CHECK_STATUS_ERROR", error.localizedDescription)
        } else {
          promise.resolve(enabled)
        }
      }
    }
    
    // MARK: - Remote Language Pack Functions
    
    AsyncFunction("instantiateServerBasedLocalization") { (language: String, serverUrl: String, transactionId: String, requestTimeout: Double, promise: Promise) in
      self.localizationManager.instantiateServerBasedLocalization(
        language: language,
        serverUrl: serverUrl,
        transactionId: transactionId,
        requestTimeout: requestTimeout
      ) { error in
        if let error = error {
          promise.reject("LOCALIZATION_ERROR", error.localizedDescription)
        } else {
          promise.resolve(nil)
        }
      }
    }
    
    AsyncFunction("getLocalizationMap") { (promise: Promise) in
      self.localizationManager.getLocalizationMap { localizationMap, error in
        if let error = error {
          promise.reject("GET_MAP_ERROR", error.localizedDescription)
        } else if let localizationMap = localizationMap {
          promise.resolve(localizationMap)
        } else {
          promise.resolve(nil)
        }
      }
    }
    
    AsyncFunction("clearLocalizationCache") { (language: String, promise: Promise) in
      self.localizationManager.clearLocalizationCache(language: language) { error in
        if let error = error {
          promise.reject("CLEAR_CACHE_ERROR", error.localizedDescription)
        } else {
          promise.resolve(nil)
        }
      }
    }
    
    AsyncFunction("mapSystemLanguageToEnum") { (promise: Promise) in
      self.localizationManager.mapSystemLanguageToEnum { language, error in
        if let error = error {
          promise.reject("MAP_LANGUAGE_ERROR", error.localizedDescription)
        } else if let language = language {
          promise.resolve(language)
        } else {
          promise.resolve(nil)
        }
      }
    }
  }
}
