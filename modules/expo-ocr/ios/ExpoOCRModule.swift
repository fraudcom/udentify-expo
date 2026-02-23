import ExpoModulesCore
import Foundation
import UdentifyCommons
import UdentifyOCR

public class ExpoOCRModule: ExpoModulesCore.Module {
  
  // Singleton instance of OCRManager
  private static var sharedOCRManager: OCRManager?
  
  private static func getSharedOCRManager() -> OCRManager {
    if sharedOCRManager == nil {
      sharedOCRManager = OCRManager()
    }
    return sharedOCRManager!
  }
  
  public func definition() -> ModuleDefinition {
    Name("ExpoOCR")
    
    // Events
    Events("onOCRComplete", "onOCRError", "onHologramComplete", "onHologramVideoRecorded", "onHologramError", "onIQAResult")
    
    // Module lifecycle
    OnCreate {
      self.setupNotificationObservers()
    }
    
    OnDestroy {
      NotificationCenter.default.removeObserver(self)
    }

    // Framework availability and info
    AsyncFunction("checkAvailability") { () -> [String: Any] in
      return [
        "isAvailable": true,
        "deviceSupported": true,
        "osVersion": UIDevice.current.systemVersion,
        "frameworkImported": true
      ]
    }
    
    AsyncFunction("getFrameworkInfo") { () -> [String: Any] in
      return [
        "frameworkName": "UdentifyOCR",
        "version": "25.3.0",
        "status": "Framework loaded successfully"
      ]
    }
    
    // UI Configuration
    AsyncFunction("configureUISettings") { (uiConfig: [String: Any]) -> Bool in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.configureUISettings(uiConfig) { success, error in
          continuation.resume(returning: success)
        }
      }
    }
    
    // OCR Methods
    AsyncFunction("startOCRScanning") { (serverURL: String, transactionID: String, documentType: String, documentSide: String, country: String?) -> Bool in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.startOCRScanning(serverURL: serverURL, 
                                   transactionID: transactionID, 
                                   documentType: documentType, 
                                   documentSide: documentSide,
                                   country: country ?? "TUR") { success, error in
          continuation.resume(returning: success)
        }
      }
    }
    
    AsyncFunction("performOCR") { (serverURL: String, transactionID: String, frontSideImage: String, backSideImage: String, documentType: String, country: String?) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.performOCR(serverURL: serverURL, 
                             transactionID: transactionID, 
                             frontSideImage: frontSideImage, 
                             backSideImage: backSideImage, 
                             documentType: documentType,
                             country: country ?? "TUR") { result, error in
          if let error = error {
            continuation.resume(returning: [
              "success": false,
              "error": error.localizedDescription
            ])
          } else {
            continuation.resume(returning: result ?? [:])
          }
        }
      }
    }
    
    AsyncFunction("performDocumentLiveness") { (serverURL: String, transactionID: String, frontSideImage: String, backSideImage: String) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.performDocumentLiveness(serverURL: serverURL, 
                                          transactionID: transactionID, 
                                          frontSideImage: frontSideImage, 
                                          backSideImage: backSideImage) { result, error in
          if let error = error {
            continuation.resume(returning: [
              "success": false,
              "error": error.localizedDescription
            ])
          } else {
            continuation.resume(returning: result ?? [:])
          }
        }
      }
    }
    
    AsyncFunction("performOCRAndDocumentLiveness") { (serverURL: String, transactionID: String, frontSideImage: String, backSideImage: String, documentType: String, country: String?) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.performOCRAndDocumentLiveness(serverURL: serverURL, 
                                                transactionID: transactionID, 
                                                frontSideImage: frontSideImage, 
                                                backSideImage: backSideImage, 
                                                documentType: documentType,
                                                country: country ?? "TUR") { result, error in
          if let error = error {
            continuation.resume(returning: [
              "success": false,
              "error": error.localizedDescription
            ])
          } else {
            continuation.resume(returning: result ?? [:])
          }
        }
      }
    }
    
    // Hologram Methods
    AsyncFunction("startHologramCamera") { (serverURL: String, transactionID: String) -> Bool in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.startHologramCamera(serverURL: serverURL, 
                                      transactionID: transactionID) { success, error in
          continuation.resume(returning: success)
        }
      }
    }
    
    AsyncFunction("performHologramCheck") { (serverURL: String, transactionID: String, videoUrls: [String]) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let ocrManager = ExpoOCRModule.getSharedOCRManager()
        ocrManager.performHologramCheck(serverURL: serverURL, 
                                       transactionID: transactionID, 
                                       videoUrls: videoUrls) { result, error in
          if let error = error {
            continuation.resume(returning: [
              "success": false,
              "error": error.localizedDescription
            ])
          } else {
            continuation.resume(returning: result ?? [:])
          }
        }
      }
    }
  }
  
  private func setupNotificationObservers() {
    // OCR Events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleOCRError(_:)),
      name: NSNotification.Name("OCROCRError"),
      object: nil
    )
    
    // IQA Events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleIQAResult(_:)),
      name: NSNotification.Name("OCRIQAResult"),
      object: nil
    )
    
    // Hologram Events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleHologramComplete(_:)),
      name: NSNotification.Name("OCRHologramComplete"),
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleHologramVideoRecorded(_:)),
      name: NSNotification.Name("OCRHologramVideoRecorded"),
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleHologramError(_:)),
      name: NSNotification.Name("OCRHologramError"),
      object: nil
    )
  }
  
  @objc private func handleOCRError(_ notification: Notification) {
    debugPrint("ExpoOCRModule - Received OCR Error notification")
    if let userInfo = notification.userInfo {
      let eventData = convertNotificationUserInfo(userInfo)
      sendEvent("onOCRError", eventData)
    }
  }
  
  @objc private func handleIQAResult(_ notification: Notification) {
    debugPrint("ExpoOCRModule - Received IQA Result notification")
    if let userInfo = notification.userInfo {
      let eventData = convertNotificationUserInfo(userInfo)
      sendEvent("onIQAResult", eventData)
    }
  }
  
  @objc private func handleHologramComplete(_ notification: Notification) {
    debugPrint("ExpoOCRModule - Received Hologram Complete notification")
    if let userInfo = notification.userInfo {
      let eventData = convertNotificationUserInfo(userInfo)
      sendEvent("onHologramComplete", eventData)
    }
  }
  
  @objc private func handleHologramVideoRecorded(_ notification: Notification) {
    debugPrint("ExpoOCRModule - Received Hologram Video Recorded notification")
    if let userInfo = notification.userInfo {
      let eventData = convertNotificationUserInfo(userInfo)
      sendEvent("onHologramVideoRecorded", eventData)
    }
  }
  
  @objc private func handleHologramError(_ notification: Notification) {
    debugPrint("ExpoOCRModule - Received Hologram Error notification")
    if let userInfo = notification.userInfo {
      let eventData = convertNotificationUserInfo(userInfo)
      sendEvent("onHologramError", eventData)
    }
  }
  
  private func convertNotificationUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any?] {
    var result: [String: Any?] = [:]
    for (key, value) in userInfo {
      if let stringKey = key as? String {
        result[stringKey] = value
      }
    }
    return result
  }
}
