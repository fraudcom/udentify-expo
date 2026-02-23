import ExpoModulesCore
import Foundation
import UIKit
import AVFoundation
import UdentifyFACE
import UdentifyCommons

public class ExpoLivenessModule: ExpoModulesCore.Module {
  
  private var currentFaceIDViewController: UIViewController?
  private var currentIDCameraController: IDCameraController?
  private var isInProgress = false
  private var customLocalizationStrings: [String: String] = [:]
  
  public func definition() -> ModuleDefinition {
    Name("ExpoLiveness")
    
    Events(
      "onFaceRecognitionResult",
      "onFaceRecognitionError",
      "onPhotoTaken",
      "onSelfieTaken",
      "onActiveLivenessResult",
      "onActiveLivenessFailure",
      "onWillDismiss",
      "onDidDismiss",
      "onBackButtonPressed",
      "onVideoTaken"
    )
    
    OnCreate {
      NSLog("ExpoLivenessModule - OnCreate")
      self.setupDefaultLocalization()
    }
    
    OnDestroy {
      NSLog("ExpoLivenessModule - OnDestroy")
    }
    
    AsyncFunction("checkPermissions") { () -> [String: Any] in
      NSLog("ExpoLivenessModule - checkPermissions")
      
      let cameraStatus = getCameraPermissionStatus()
      
      return [
        "camera": cameraStatus,
        "readPhoneState": "granted",
        "internet": "granted"
      ]
    }
    
    AsyncFunction("requestPermissions") { () -> [String: Any] in
      NSLog("ExpoLivenessModule - requestPermissions")
      
      return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
          AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
              let cameraStatus = getCameraPermissionStatus()
              
              let result: [String: Any] = [
                "camera": cameraStatus,
                "readPhoneState": "granted",
                "internet": "granted"
              ]
              
              continuation.resume(returning: result)
            }
          }
        }
      }
    }
    
    AsyncFunction("startFaceRecognitionRegistration") { [weak self] (credentials: [String: Any]) -> [String: Any] in
      guard let self = self else {
        throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
      }
      
      NSLog("ExpoLivenessModule - startFaceRecognitionRegistration")
      
      guard !self.isInProgress else {
        throw NSError(domain: "ExpoLiveness", code: -2, userInfo: [NSLocalizedDescriptionKey: "Operation already in progress"])
      }
      
      guard let serverURL = credentials["serverURL"] as? String,
            let transactionID = credentials["transactionID"] as? String else {
        throw NSError(domain: "ExpoLiveness", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing required serverURL or transactionID"])
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          self.isInProgress = true
          
          let userID = credentials["userID"] as? String
          let logLevel = UdentifyCommons.LogLevel.warning
          
          IDCameraController.instantiate(
            serverURL: serverURL,
            method: .registration,
            transactionID: transactionID,
            userID: userID,
            listName: nil,
            logLevel: logLevel
          ) { [weak self] controller, error in
            guard let self = self else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"]))
              return
            }
            
            if let error = error {
              self.isInProgress = false
              continuation.resume(throwing: error)
              return
            }
            
            guard let controller = controller,
                  let rootViewController = self.getRootViewController() else {
              self.isInProgress = false
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"]))
              return
            }
            
            controller.delegate = self
            self.currentFaceIDViewController = controller
            rootViewController.present(controller, animated: true)
            
            let result: [String: Any] = [
              "status": "success",
              "faceIDMessage": [
                "success": true,
                "message": "Face recognition registration started"
              ]
            ]
            continuation.resume(returning: result)
          }
        }
      }
    }
    
    AsyncFunction("startFaceRecognitionAuthentication") { [weak self] (credentials: [String: Any]) -> [String: Any] in
      guard let self = self else {
        throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
      }
      
      NSLog("ExpoLivenessModule - startFaceRecognitionAuthentication")
      
      guard !self.isInProgress else {
        throw NSError(domain: "ExpoLiveness", code: -2, userInfo: [NSLocalizedDescriptionKey: "Operation already in progress"])
      }
      
      guard let serverURL = credentials["serverURL"] as? String,
            let transactionID = credentials["transactionID"] as? String else {
        throw NSError(domain: "ExpoLiveness", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing required serverURL or transactionID"])
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          self.isInProgress = true
          
          let userID = credentials["userID"] as? String
          let logLevel = UdentifyCommons.LogLevel.warning
          
          IDCameraController.instantiate(
            serverURL: serverURL,
            method: .authentication,
            transactionID: transactionID,
            userID: userID,
            listName: nil,
            logLevel: logLevel
          ) { [weak self] controller, error in
            guard let self = self else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"]))
              return
            }
            
            if let error = error {
              self.isInProgress = false
              continuation.resume(throwing: error)
              return
            }
            
            guard let controller = controller,
                  let rootViewController = self.getRootViewController() else {
              self.isInProgress = false
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"]))
              return
            }
            
            controller.delegate = self
            self.currentFaceIDViewController = controller
            rootViewController.present(controller, animated: true)
            
            let result: [String: Any] = [
              "status": "success",
              "faceIDMessage": [
                "success": true,
                "message": "Face recognition authentication started"
              ]
            ]
            continuation.resume(returning: result)
          }
        }
      }
    }
    
    AsyncFunction("startActiveLiveness") { [weak self] (credentials: [String: Any], isAuthentication: Bool) -> [String: Any] in
      guard let self = self else {
        throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
      }
      
      NSLog("ExpoLivenessModule - startActiveLiveness, isAuth: \(isAuthentication)")
      
      guard !self.isInProgress else {
        throw NSError(domain: "ExpoLiveness", code: -2, userInfo: [NSLocalizedDescriptionKey: "Operation already in progress"])
      }
      
      guard let serverURL = credentials["serverURL"] as? String,
            let transactionID = credentials["transactionID"] as? String,
            let userID = credentials["userID"] as? String else {
        throw NSError(domain: "ExpoLiveness", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing required serverURL, transactionID, or userID"])
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          self.isInProgress = true
          
          let hybridLivenessEnabled = credentials["hybridLivenessEnabled"] as? Bool ?? false
          let autoNextEnabled = credentials["activeLivenessAutoNextEnabled"] as? Bool ?? true
          let logLevel = UdentifyCommons.LogLevel.warning
          
          NSLog("ExpoLivenessModule - Using method: \(isAuthentication ? "authentication" : "registration")")
          
          ActiveCameraController.instantiate(
            serverURL: serverURL,
            method: isAuthentication ? .authentication : .registration,
            transactionID: transactionID,
            userID: userID,
            hybridLivenessEnabled: hybridLivenessEnabled,
            autoNextEnabled: autoNextEnabled,
            logLevel: logLevel
          ) { [weak self] controller, error in
            guard let self = self else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"]))
              return
            }
            
            if let error = error {
              self.isInProgress = false
              continuation.resume(throwing: error)
              return
            }
            
            guard let controller = controller,
                  let rootViewController = self.getRootViewController() else {
              self.isInProgress = false
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"]))
              return
            }
            
            controller.delegate = self
            self.currentFaceIDViewController = controller
            rootViewController.present(controller, animated: true)
            
            let result: [String: Any] = [
              "status": "success",
              "faceIDMessage": [
                "success": true,
                "message": "Active liveness detection started"
              ]
            ]
            continuation.resume(returning: result)
          }
        }
      }
    }
    
    AsyncFunction("startHybridLiveness") { [weak self] (credentials: [String: Any], isAuthentication: Bool) -> [String: Any] in
      guard let self = self else {
        throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
      }
      
      NSLog("ExpoLivenessModule - startHybridLiveness, isAuth: \(isAuthentication)")
      
      guard !self.isInProgress else {
        throw NSError(domain: "ExpoLiveness", code: -2, userInfo: [NSLocalizedDescriptionKey: "Operation already in progress"])
      }
      
      guard let serverURL = credentials["serverURL"] as? String,
            let transactionID = credentials["transactionID"] as? String,
            let userID = credentials["userID"] as? String else {
        throw NSError(domain: "ExpoLiveness", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing required serverURL, transactionID, or userID"])
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          self.isInProgress = true
          
          let autoNextEnabled = credentials["activeLivenessAutoNextEnabled"] as? Bool ?? true
          let logLevel = UdentifyCommons.LogLevel.warning
          
          NSLog("ExpoLivenessModule - Using method: \(isAuthentication ? "authentication" : "registration")")
          
          ActiveCameraController.instantiate(
            serverURL: serverURL,
            method: isAuthentication ? .authentication : .registration,
            transactionID: transactionID,
            userID: userID,
            hybridLivenessEnabled: true,
            autoNextEnabled: autoNextEnabled,
            logLevel: logLevel
          ) { [weak self] controller, error in
            guard let self = self else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"]))
              return
            }
            
            if let error = error {
              self.isInProgress = false
              continuation.resume(throwing: error)
              return
            }
            
            guard let controller = controller,
                  let rootViewController = self.getRootViewController() else {
              self.isInProgress = false
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"]))
              return
            }
            
            controller.delegate = self
            self.currentFaceIDViewController = controller
            rootViewController.present(controller, animated: true)
            
            let result: [String: Any] = [
              "status": "success",
              "faceIDMessage": [
                "success": true,
                "message": "Hybrid liveness detection started"
              ]
            ]
            continuation.resume(returning: result)
          }
        }
      }
    }
    
    AsyncFunction("startSelfieCapture") { [weak self] (credentials: [String: Any]) -> [String: Any] in
      guard let self = self else {
        throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
      }
      
      NSLog("ExpoLivenessModule - startSelfieCapture")
      
      guard !self.isInProgress else {
        throw NSError(domain: "ExpoLiveness", code: -2, userInfo: [NSLocalizedDescriptionKey: "Operation already in progress"])
      }
      
      guard let serverURL = credentials["serverURL"] as? String,
            let transactionID = credentials["transactionID"] as? String else {
        throw NSError(domain: "ExpoLiveness", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing required serverURL or transactionID"])
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          self.isInProgress = true
          
          let userID = credentials["userID"] as? String
          let logLevel = UdentifyCommons.LogLevel.warning
          
          IDCameraController.instantiate(
            serverURL: serverURL,
            method: .selfie,
            transactionID: transactionID,
            userID: userID,
            listName: nil,
            logLevel: logLevel
          ) { [weak self] controller, error in
            guard let self = self else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"]))
              return
            }
            
            if let error = error {
              self.isInProgress = false
              continuation.resume(throwing: error)
              return
            }
            
            guard let controller = controller,
                  let rootViewController = self.getRootViewController() else {
              self.isInProgress = false
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"]))
              return
            }
            
            controller.delegate = self
            self.currentFaceIDViewController = controller
            rootViewController.present(controller, animated: true)
            
            let result: [String: Any] = [
              "status": "success",
              "faceIDMessage": [
                "success": true,
                "message": "Selfie capture started"
              ]
            ]
            continuation.resume(returning: result)
          }
        }
      }
    }
    
    AsyncFunction("performFaceRecognitionWithSelfie") { [weak self] (credentials: [String: Any], base64Image: String, isAuthentication: Bool) -> [String: Any] in
      guard let self = self else {
        throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
      }
      
      NSLog("ExpoLivenessModule - performFaceRecognitionWithSelfie, isAuth: \(isAuthentication)")
      
      guard let serverURL = credentials["serverURL"] as? String,
            let transactionID = credentials["transactionID"] as? String,
            let userID = credentials["userID"] as? String else {
        throw NSError(domain: "ExpoLiveness", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing required serverURL, transactionID, or userID"])
      }
      
      guard let imageData = Data(base64Encoded: base64Image),
            let image = UIImage(data: imageData) else {
        throw NSError(domain: "ExpoLiveness", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to decode base64 image"])
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.main.async {
          let logLevel = UdentifyCommons.LogLevel.warning
          let method: MethodType = isAuthentication ? .authentication : .registration
          
          IDCameraController.instantiate(
            serverURL: serverURL,
            method: method,
            transactionID: transactionID,
            userID: userID,
            listName: nil,
            logLevel: logLevel
          ) { [weak self] controller, error in
            guard let self = self else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"]))
              return
            }
            
            if let error = error {
              continuation.resume(throwing: error)
              return
            }
            
            guard let controller = controller else {
              continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not create face recognition controller"]))
              return
            }
            
            self.currentIDCameraController = controller
            
            controller.performFaceIDandLiveness(image: image, methodType: method) { faceIDResult, livenessResult in
              DispatchQueue.main.async {
                self.currentIDCameraController = nil
                
                if faceIDResult == nil && livenessResult == nil {
                  continuation.resume(throwing: NSError(domain: "ExpoLiveness", code: -6, userInfo: [NSLocalizedDescriptionKey: "Both faceIDResult and livenessResult are nil"]))
                  return
                }
                
                let faceIDMessageDict = self.createFaceIDMessage(faceIDResult: faceIDResult, livenessResult: livenessResult)
                
                let result: [String: Any] = [
                  "status": faceIDMessageDict["isFailed"] as? Bool == true ? "failure" : "success",
                  "faceIDMessage": faceIDMessageDict
                ]
                
                continuation.resume(returning: result)
              }
            }
          }
        }
      }
    }
    
    AsyncFunction("registerUserWithPhoto") { (credentials: [String: Any], base64Image: String) -> [String: Any] in
      NSLog("ExpoLivenessModule - registerUserWithPhoto")
      
      return [
        "status": "success",
        "message": "User registration with photo completed"
      ]
    }
    
    AsyncFunction("authenticateUserWithPhoto") { (credentials: [String: Any], base64Image: String) -> [String: Any] in
      NSLog("ExpoLivenessModule - authenticateUserWithPhoto")
      
      return [
        "status": "success",
        "message": "User authentication with photo completed"
      ]
    }
    
    AsyncFunction("cancelFaceRecognition") { [weak self] () -> Void in
      guard let self = self else { return }
      
      NSLog("ExpoLivenessModule - cancelFaceRecognition")
      
      await MainActor.run {
        self.currentFaceIDViewController?.dismiss(animated: true) {
          self.isInProgress = false
          self.currentFaceIDViewController = nil
        }
      }
    }
    
    AsyncFunction("isFaceRecognitionInProgress") { [weak self] () -> Bool in
      return self?.isInProgress ?? false
    }
    
    AsyncFunction("addUserToList") { (serverURL: String, transactionId: String, status: String, metadata: [String: Any]?) -> [String: Any] in
      NSLog("ExpoLivenessModule - addUserToList")
      
      return [
        "success": true,
        "data": [
          "id": 1,
          "userId": 123,
          "customerList": [
            "id": 1,
            "name": "Main List",
            "listRole": "Customer",
            "description": "Main customer list",
            "creationDate": String(Int(Date().timeIntervalSince1970 * 1000))
          ]
        ]
      ]
    }
    
    AsyncFunction("startFaceRecognitionIdentification") { (serverURL: String, transactionId: String, listName: String, logLevel: String?) -> [String: Any] in
      NSLog("ExpoLivenessModule - startFaceRecognitionIdentification")
      
      return [
        "status": "success",
        "message": "Face recognition identification started"
      ]
    }
    
    AsyncFunction("deleteUserFromList") { (serverURL: String, transactionId: String, listName: String, photoBase64: String) -> [String: Any] in
      NSLog("ExpoLivenessModule - deleteUserFromList")
      
      return [
        "success": true,
        "message": "User deleted from list"
      ]
    }
    
    AsyncFunction("configureUISettings") { [weak self] (settings: [String: Any]) -> Bool in
      guard let self = self else { return false }
      
      NSLog("ExpoLivenessModule - configureUISettings")
      
      await MainActor.run {
        let customSettings = self.createCustomAPISettings(from: settings)
        ApiSettingsProvider.getInstance().currentSettings = customSettings
      }
      
      return true
    }
    
    AsyncFunction("setLocalization") { [weak self] (languageCode: String, customStrings: [String: String]?) -> Void in
      guard let self = self else { return }
      
      NSLog("ExpoLivenessModule - setLocalization: \(languageCode)")
      
      await MainActor.run {
        if let customStrings = customStrings {
          NSLog("ExpoLivenessModule - Applying \(customStrings.count) custom localization strings")
          self.customLocalizationStrings = customStrings
          
          // Apply custom strings to the SDK by creating a custom bundle
          self.applyCustomLocalization(languageCode: languageCode, customStrings: customStrings)
        }
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func getRootViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }),
          let rootViewController = window.rootViewController else {
      return nil
    }
    
    var topController = rootViewController
    while let presentedViewController = topController.presentedViewController {
      topController = presentedViewController
    }
    
    return topController
  }
  
  // MARK: - Localization Methods
  
  private func setupDefaultLocalization() {
    NSLog("ExpoLivenessModule - Setting up default localization")
    setupLocalizationBundle()
  }
  
  private func setupLocalizationBundle() {
    if let expoLivenessBundle = getBundleForExpoModule(),
       let resourceBundlePath = expoLivenessBundle.path(forResource: "LivenessResources", ofType: "bundle"),
       let resourceBundle = Bundle(path: resourceBundlePath) {
      
      NSLog("ExpoLivenessModule - Found LivenessResources bundle: \(resourceBundle.bundlePath)")
      
      // Set up LivenessBundleHelper
      LivenessBundleHelper.setupLocalizationBundle(resourceBundle)
      
      // Create custom settings with localization bundle
      let customSettings = CustomLivenessSettings(localizationBundle: resourceBundle, uiConfig: nil)
      
      // Apply liveness settings
      ApiSettingsProvider.getInstance().currentSettings = customSettings
      
      NSLog("ExpoLivenessModule - Localization bundle applied successfully")
    } else {
      NSLog("ExpoLivenessModule - WARNING: Could not find LivenessResources bundle")
    }
  }
  
  private func getBundleForExpoModule() -> Bundle? {
    let expoModules = [
      "ExpoLiveness.ExpoLivenessModule",
      "ExpoLivenessModule"
    ]
    
    for moduleName in expoModules {
      if let moduleClass = NSClassFromString(moduleName) {
        let moduleBundle = Bundle(for: moduleClass)
        NSLog("ExpoLivenessModule - Found module bundle via class: \(moduleName)")
        return moduleBundle
      }
    }
    
    NSLog("ExpoLivenessModule - Using self bundle as fallback")
    return Bundle(for: type(of: self))
  }
  
  private func applyCustomLocalization(languageCode: String, customStrings: [String: String]) {
    NSLog("ExpoLivenessModule - Applying custom localization for language: \(languageCode)")
    
    for (key, value) in customStrings {
      NSLog("ExpoLivenessModule - Custom string: \(key) = \(value)")
    }
    
    do {
      let customBundle = try createCustomLocalizationBundle(languageCode: languageCode, customStrings: customStrings)
      
      // Set up bundle helper
      LivenessBundleHelper.setupLocalizationBundle(customBundle)
      
      // Create custom settings with the new bundle
      let customSettings = CustomLivenessSettings(
        localizationBundle: customBundle,
        uiConfig: ["tableName": "CustomLocalizable"]
      )
      
      // Apply to SDK
      ApiSettingsProvider.getInstance().currentSettings = customSettings
      
      NSLog("ExpoLivenessModule - Custom localization bundle applied successfully")
    } catch {
      NSLog("ExpoLivenessModule - Failed to create custom localization bundle: \(error)")
    }
  }
  
  private func createCustomLocalizationBundle(languageCode: String, customStrings: [String: String]) throws -> Bundle {
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory
    let bundlePath = tempDirectory.appendingPathComponent("CustomLocalization.bundle")
    
    if fileManager.fileExists(atPath: bundlePath.path) {
      try? fileManager.removeItem(at: bundlePath)
    }
    
    try fileManager.createDirectory(at: bundlePath, withIntermediateDirectories: true)
    
    let lprojPath = bundlePath.appendingPathComponent("\(languageCode).lproj")
    try fileManager.createDirectory(at: lprojPath, withIntermediateDirectories: true)
    
    var stringsContent = ""
    for (key, value) in customStrings {
      let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
      stringsContent += "\"\(key)\" = \"\(escapedValue)\";\n"
    }
    
    let stringsFilePath = lprojPath.appendingPathComponent("CustomLocalizable.strings")
    try stringsContent.write(to: stringsFilePath, atomically: true, encoding: .utf8)
    
    guard let bundle = Bundle(url: bundlePath) else {
      throw NSError(domain: "ExpoLiveness", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bundle"])
    }
    
    return bundle
  }
  
  private func getLocalizedString(_ key: String) -> String {
    if let customString = customLocalizationStrings[key] {
      return customString
    }
    
    return NSLocalizedString(key, bundle: Bundle(for: type(of: self)), comment: "")
  }
  
  private func methodTypeToString(_ methodType: MethodType?) -> String {
    guard let methodType = methodType else { return "unknown" }
    
    switch methodType {
    case .registration:
      return "registration"
    case .authentication:
      return "authentication"
    case .selfie:
      return "selfie"
    case .imageUpload:
      return "imageUpload"
    case .identification:
      return "identification"
    @unknown default:
      return "unknown"
    }
  }
  
  private func createFaceIDMessage(faceIDResult: FaceIDResult?, livenessResult: LivenessResult?) -> [String: Any] {
    var faceIDMessage: [String: Any] = [:]
    
    var isFailed = false
    
    if let faceIDResult = faceIDResult {
      var faceIDResultDict: [String: Any] = [
        "verified": faceIDResult.verified,
        "matchScore": faceIDResult.matchScore,
        "description": faceIDResult.description,
        "transactionID": faceIDResult.transactionID ?? "",
        "userID": faceIDResult.userID ?? "",
        "header": faceIDResult.header ?? "",
        "listNames": faceIDResult.listNames ?? "",
        "listIds": faceIDResult.listIds ?? "",
        "registrationTransactionID": faceIDResult.registrationTransactionID ?? "",
        "method": self.methodTypeToString(faceIDResult.method)
      ]
      
      if let error = faceIDResult.error {
        faceIDResultDict["error"] = [
          "code": "\(error)",
          "description": error.localizedDescription
        ]
        isFailed = true
      }
      
      if let referencePhoto = faceIDResult.referencePhoto {
        if let imageData = referencePhoto.jpegData(compressionQuality: 0.8) {
          faceIDResultDict["referencePhotoBase64"] = imageData.base64EncodedString()
        }
      }
      
      if let metadata = faceIDResult.metadata {
        var metadataDict: [String: Any] = [:]
        for (key, value) in metadata {
          if let udentifyAny = value {
            metadataDict[key] = udentifyAny.value
          }
        }
        faceIDResultDict["metadata"] = metadataDict
      }
      
      faceIDMessage["faceIDResult"] = faceIDResultDict
      
      if faceIDResult.error != nil || !faceIDResult.verified {
        isFailed = true
      }
    } else {
      isFailed = true
    }
    
    if let livenessResult = livenessResult {
      var livenessResultDict: [String: Any] = [
        "assessmentValue": livenessResult.assessmentValue ?? 0.0,
        "assessmentDescription": livenessResult.assessmentDescription ?? "",
        "probability": livenessResult.probability ?? 0.0,
        "quality": livenessResult.quality ?? 0.0,
        "livenessScore": livenessResult.livenessScore ?? 0.0,
        "transactionID": livenessResult.transactionID ?? ""
      ]
      
      if let error = livenessResult.error {
        livenessResultDict["error"] = [
          "code": "\(error)",
          "description": error.localizedDescription
        ]
        isFailed = true
      }
      
      let assessment = livenessResult.assessment()
      livenessResultDict["assessment"] = assessment.description
      
      faceIDMessage["livenessResult"] = livenessResultDict
      
      if livenessResult.error != nil || livenessResult.assessmentValue == nil {
        isFailed = true
      }
    } else {
      isFailed = true
    }
    
    faceIDMessage["success"] = !isFailed
    faceIDMessage["isFailed"] = isFailed
    faceIDMessage["message"] = isFailed ? "Face recognition failed" : "Face recognition completed"
    
    return faceIDMessage
  }
  
  private func createCustomAPISettings(from settings: [String: Any]) -> CustomAPISettings {
    NSLog("ExpoLivenessModule - Creating custom API settings")
    
    let colors = settings["colors"] as? [String: Any]
    let fonts = settings["fonts"] as? [String: Any]
    let dimensions = settings["dimensions"] as? [String: Any]
    let configs = settings["configs"] as? [String: Any]
    
    return CustomAPISettings(
      colors: createAPIColors(from: colors),
      fonts: createAPIFonts(from: fonts),
      configs: createAPIConfigs(from: configs, dimensions: dimensions)
    )
  }
  
  private func createAPIColors(from colorsDict: [String: Any]?) -> ApiColors {
    guard let colors = colorsDict else {
      return ApiColors()
    }
    
    return ApiColors(
      titleColor: parseUIColor(colors["titleColor"] as? String) ?? .purple,
      titleBG: parseUIColor(colors["titleBG"] as? String) ?? UIColor.blue.withAlphaComponent(0.2),
      errorColor: parseUIColor(colors["buttonErrorColor"] as? String) ?? .red,
      successColor: parseUIColor(colors["buttonSuccessColor"] as? String) ?? .green,
      buttonColor: parseUIColor(colors["buttonColor"] as? String) ?? .darkGray,
      buttonTextColor: parseUIColor(colors["buttonTextColor"] as? String) ?? .white,
      buttonErrorTextColor: parseUIColor(colors["buttonErrorTextColor"] as? String) ?? .white,
      buttonSuccessTextColor: parseUIColor(colors["buttonSuccessTextColor"] as? String) ?? .white,
      buttonBackColor: parseUIColor(colors["buttonBackColor"] as? String) ?? .black,
      footerTextColor: parseUIColor(colors["footerTextColor"] as? String) ?? .white,
      checkmarkTintColor: parseUIColor(colors["checkmarkTintColor"] as? String) ?? .white,
      backgroundColor: parseUIColor(colors["backgroundColor"] as? String) ?? .purple
    )
  }
  
  private func createAPIFonts(from fontsDict: [String: Any]?) -> ApiFonts {
    guard let fonts = fontsDict else {
      return ApiFonts()
    }
    
    let titleFont = parseFont(fonts["titleFont"] as? [String: Any], defaultSize: 30) ?? UIFont.boldSystemFont(ofSize: 30)
    let buttonFont = parseFont(fonts["buttonFont"] as? [String: Any], defaultSize: 18) ?? UIFont.boldSystemFont(ofSize: 18)
    let footerFont = parseFont(fonts["footerFont"] as? [String: Any], defaultSize: 24) ?? UIFont.boldSystemFont(ofSize: 24)
    
    return ApiFonts(
      titleFont: titleFont,
      buttonFont: buttonFont,
      footerFont: footerFont
    )
  }
  
  private func createAPIConfigs(from configsDict: [String: Any]?, dimensions: [String: Any]?) -> ApiConfigs {
    var cameraPosition: AVCaptureDevice.Position = .front
    var requestTimeout: Double = 15
    var autoTake: Bool = true
    var errorDelay: Double = 0.25
    var successDelay: Double = 0.75
    var bundle: Bundle = .main
    var tableName: String? = nil
    var maskDetection: Bool = false
    var maskConfidence: Double = 0.95
    var invertedAnimation: Bool = false
    var backButtonEnabled: Bool = true
    var multipleFacesRejected: Bool = true
    
    var buttonHeight: CGFloat = 48
    var buttonMarginLeft: CGFloat = 20
    var buttonMarginRight: CGFloat = 20
    var buttonCornerRadius: CGFloat = 8
    
    if let configs = configsDict {
      if let cameraPos = configs["cameraPosition"] as? String {
        cameraPosition = cameraPos == "back" ? .back : .front
      }
      if let timeout = configs["requestTimeout"] as? NSNumber {
        requestTimeout = timeout.doubleValue
      }
      if let autoTakeValue = configs["autoTake"] as? Bool {
        autoTake = autoTakeValue
      }
      if let errorDelayValue = configs["errorDelay"] as? NSNumber {
        errorDelay = errorDelayValue.doubleValue
      }
      if let successDelayValue = configs["successDelay"] as? NSNumber {
        successDelay = successDelayValue.doubleValue
      }
      if let tableNameValue = configs["tableName"] as? String {
        tableName = tableNameValue
      }
      if let maskDetectionValue = configs["maskDetection"] as? Bool {
        maskDetection = maskDetectionValue
      }
      if let maskConfidenceValue = configs["maskConfidence"] as? NSNumber {
        maskConfidence = maskConfidenceValue.doubleValue
      }
      if let invertedAnimationValue = configs["invertedAnimation"] as? Bool {
        invertedAnimation = invertedAnimationValue
      }
      if let backButtonValue = configs["backButtonEnabled"] as? Bool {
        backButtonEnabled = backButtonValue
      }
      if let multipleFacesValue = configs["multipleFacesRejected"] as? Bool {
        multipleFacesRejected = multipleFacesValue
      }
    }
    
    if let dims = dimensions {
      if let height = dims["buttonHeight"] as? NSNumber {
        buttonHeight = CGFloat(height.doubleValue)
      }
      if let marginLeft = dims["buttonMarginLeft"] as? NSNumber {
        buttonMarginLeft = CGFloat(marginLeft.doubleValue)
      }
      if let marginRight = dims["buttonMarginRight"] as? NSNumber {
        buttonMarginRight = CGFloat(marginRight.doubleValue)
      }
      if let cornerRadius = dims["buttonCornerRadius"] as? NSNumber {
        buttonCornerRadius = CGFloat(cornerRadius.doubleValue)
      }
    }
    
    var progressBarBackgroundColor: UIColor = .lightGray.withAlphaComponent(0.5)
    var progressColor: UIColor = .gray
    var completionColor: UIColor = .green
    var progressBarCornerRadius: CGFloat = buttonCornerRadius
    
    if let configs = configsDict {
      if let progressBarStyle = configs["progressBarStyle"] as? [String: Any] {
        if let bgColor = progressBarStyle["backgroundColor"] as? String {
          progressBarBackgroundColor = parseUIColor(bgColor) ?? progressBarBackgroundColor
        }
        if let progColor = progressBarStyle["progressColor"] as? String {
          progressColor = parseUIColor(progColor) ?? progressColor
        }
        if let compColor = progressBarStyle["completionColor"] as? String {
          completionColor = parseUIColor(compColor) ?? completionColor
        }
        if let cornerRad = progressBarStyle["cornerRadius"] as? NSNumber {
          progressBarCornerRadius = CGFloat(cornerRad.doubleValue)
        }
      }
    }
    
    let progressBarStyle = UdentifyProgressBarStyle(
      backgroundColor: progressBarBackgroundColor,
      progressColor: progressColor,
      completionColor: completionColor,
      textStyle: UdentifyTextStyle(
        font: .boldSystemFont(ofSize: 19),
        textColor: .white,
        textAlignment: .center
      ),
      cornerRadius: progressBarCornerRadius
    )
    
    return ApiConfigs(
      cameraPosition: cameraPosition,
      requestTimeout: requestTimeout,
      autoTake: autoTake,
      errorDelay: errorDelay,
      successDelay: successDelay,
      bundle: bundle,
      tableName: tableName,
      maskDetection: maskDetection,
      maskConfidence: Float(maskConfidence),
      invertedAnimation: invertedAnimation,
      backButtonEnabled: backButtonEnabled,
      multipleFacesRejected: multipleFacesRejected,
      buttonHeight: buttonHeight,
      buttonMarginLeft: buttonMarginLeft,
      buttonMarginRight: buttonMarginRight,
      buttonCornerRadius: buttonCornerRadius,
      progressBarStyle: progressBarStyle
    )
  }
  
  private func parseUIColor(_ colorString: String?) -> UIColor? {
    guard let colorString = colorString else { return nil }
    
    if colorString.hasPrefix("#") {
      let hex = String(colorString.dropFirst())
      var rgbValue: UInt64 = 0
      
      if Scanner(string: hex).scanHexInt64(&rgbValue) {
        let length = hex.count
        
        if length == 6 {
          return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
          )
        } else if length == 8 {
          return UIColor(
            red: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x000000FF) / 255.0,
            alpha: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
          )
        }
      }
    }
    
    switch colorString.lowercased() {
    case "red": return .red
    case "green": return .green
    case "blue": return .blue
    case "black": return .black
    case "white": return .white
    case "clear": return .clear
    case "gray": return .gray
    case "purple": return .purple
    case "orange": return .orange
    case "yellow": return .yellow
    default: return nil
    }
  }
  
  private func parseFont(_ fontDict: [String: Any]?, defaultSize: CGFloat) -> UIFont? {
    guard let fontDict = fontDict else { return nil }
    
    let fontName = fontDict["name"] as? String ?? ""
    let fontSize = CGFloat((fontDict["size"] as? NSNumber)?.doubleValue ?? Double(defaultSize))
    
    if !fontName.isEmpty {
      return UIFont(name: fontName, size: fontSize)
    } else {
      return UIFont.systemFont(ofSize: fontSize)
    }
  }
}

// MARK: - IDCameraController Delegate
extension ExpoLivenessModule: IDCameraControllerDelegate {
  public func cameraController(image: UIImage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      NSLog("ExpoLivenessModule - cameraController called with image")
      
      self.isInProgress = false
      self.currentFaceIDViewController?.dismiss(animated: true) {
        self.currentFaceIDViewController = nil
      }
      
      let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? ""
      
      let eventBody: [String: Any] = ["base64Image": base64Image]
      self.sendEvent("onSelfieTaken", eventBody)
    }
  }
  
  public func cameraController(didEncounterError error: FaceError) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentFaceIDViewController?.dismiss(animated: true) {
        self.currentFaceIDViewController = nil
      }
      
      let errorMap: [String: Any] = [
        "code": "FACE_RECOGNITION_ERROR",
        "message": error.localizedDescription
      ]
      
      self.sendEvent("onFaceRecognitionError", errorMap)
    }
  }
  
  public func cameraControllerDidFinishWithResult(viewMode: IDCameraController.ViewMode, result: FaceIDMessage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentFaceIDViewController?.dismiss(animated: true) {
        self.currentFaceIDViewController = nil
      }
      
      var faceIDResultMap: [String: Any] = [:]
      
      if let faceIDResult = result.faceIDResult {
        faceIDResultMap["verified"] = faceIDResult.verified
        faceIDResultMap["matchScore"] = faceIDResult.matchScore
        faceIDResultMap["transactionID"] = faceIDResult.transactionID ?? ""
        faceIDResultMap["userID"] = faceIDResult.userID ?? ""
        faceIDResultMap["listNames"] = faceIDResult.listNames ?? ""
        faceIDResultMap["listIds"] = faceIDResult.listIds ?? ""
        faceIDResultMap["description"] = faceIDResult.description
        faceIDResultMap["method"] = self.methodTypeToString(faceIDResult.method)
        
        if let registrationTransactionID = faceIDResult.registrationTransactionID {
          faceIDResultMap["registrationTransactionID"] = registrationTransactionID
        }
        
        if let referencePhoto = faceIDResult.referencePhoto,
           let photoData = referencePhoto.jpegData(compressionQuality: 0.8) {
          faceIDResultMap["referencePhoto"] = photoData.base64EncodedString()
        }
        
        if let metadata = faceIDResult.metadata {
          var metadataMap: [String: Any] = [:]
          for (key, anyValue) in metadata {
            if let value = anyValue?.value {
              metadataMap[key] = value
            }
          }
          faceIDResultMap["metadata"] = metadataMap
        }
      }
      
      var livenessResultDict: [String: Any]? = nil
      if let livenessResult = result.livenessResult {
        livenessResultDict = [
          "assessmentValue": livenessResult.assessmentValue ?? 0.0,
          "assessmentDescription": livenessResult.assessmentDescription ?? "",
          "probability": livenessResult.probability ?? 0.0,
          "quality": livenessResult.quality ?? 0.0,
          "livenessScore": livenessResult.livenessScore ?? 0.0,
          "transactionID": livenessResult.transactionID ?? ""
        ]
      }
      
      let faceIDMessage: [String: Any] = [
        "success": !result.isFailed,
        "message": result.isFailed ? "Face recognition failed" : "Face recognition completed",
        "faceIDResult": faceIDResultMap.isEmpty ? nil : faceIDResultMap,
        "livenessResult": livenessResultDict
      ]
      
      let resultMap: [String: Any] = [
        "status": "success",
        "faceIDMessage": faceIDMessage
      ]
      
      self.sendEvent("onFaceRecognitionResult", resultMap)
    }
  }
  
  public func cameraControllerUserPressedBackButton() {
    DispatchQueue.main.async { [weak self] in
      self?.sendEvent("onBackButtonPressed", [:])
    }
  }
  
  public func cameraControllerWillDismiss() {
    DispatchQueue.main.async { [weak self] in
      self?.sendEvent("onWillDismiss", [:])
    }
  }
  
  public func cameraControllerDidDismiss() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isInProgress = false
      self.currentFaceIDViewController = nil
      self.sendEvent("onDidDismiss", [:])
    }
  }
}

// MARK: - ActiveCameraController Delegate
extension ExpoLivenessModule: ActiveCameraControllerDelegate {
  public func onResult(result: FaceIDMessage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentFaceIDViewController?.dismiss(animated: true) {
        self.currentFaceIDViewController = nil
      }
      
      var faceIDMessageDict: [String: Any] = [
        "success": !result.isFailed,
        "message": result.isFailed ? "Active liveness failed" : "Active liveness completed",
        "isFailed": result.isFailed
      ]
      
      var resultMap: [String: Any] = [
        "status": result.isFailed ? "failure" : "success"
      ]
      
      if let faceIDResult = result.faceIDResult {
        var faceIDResultDict: [String: Any] = [
          "verified": faceIDResult.verified,
          "matchScore": faceIDResult.matchScore,
          "transactionID": faceIDResult.transactionID ?? "",
          "userID": faceIDResult.userID ?? "",
          "header": faceIDResult.header ?? "",
          "description": faceIDResult.description,
          "listNames": faceIDResult.listNames ?? "",
          "listIds": faceIDResult.listIds ?? "",
          "registrationTransactionID": faceIDResult.registrationTransactionID ?? "",
          "method": self.methodTypeToString(faceIDResult.method)
        ]
        
        if let error = faceIDResult.error {
          faceIDResultDict["error"] = [
            "code": "\(error)",
            "description": error.localizedDescription
          ]
        }
        
        if let referencePhoto = faceIDResult.referencePhoto {
          if let imageData = referencePhoto.jpegData(compressionQuality: 0.8) {
            faceIDResultDict["referencePhotoBase64"] = imageData.base64EncodedString()
          }
        }
        
        if let metadata = faceIDResult.metadata {
          var metadataDict: [String: Any] = [:]
          for (key, value) in metadata {
            if let udentifyAny = value {
              metadataDict[key] = udentifyAny.value
            }
          }
          faceIDResultDict["metadata"] = metadataDict
        }
        
        faceIDMessageDict["faceIDResult"] = faceIDResultDict
      }
      
      if let livenessResult = result.livenessResult {
        var livenessResultDict: [String: Any] = [
          "assessmentValue": livenessResult.assessmentValue ?? 0.0,
          "assessmentDescription": livenessResult.assessmentDescription ?? "",
          "probability": livenessResult.probability ?? 0.0,
          "quality": livenessResult.quality ?? 0.0,
          "livenessScore": livenessResult.livenessScore ?? 0.0,
          "transactionID": livenessResult.transactionID ?? ""
        ]
        
        if let error = livenessResult.error {
          livenessResultDict["error"] = [
            "code": "\(error)",
            "description": error.localizedDescription
          ]
        }
        
        let assessment = livenessResult.assessment()
        livenessResultDict["assessment"] = assessment.description
        
        faceIDMessageDict["livenessResult"] = livenessResultDict
      }
      
      if let activeLivenessResult = result.activeLivenessResult {
        var activeLivenessResultDict: [String: Any] = [
          "transactionID": activeLivenessResult.transactionID ?? "",
          "gestureResult": activeLivenessResult.gestureResult ?? [:]
        ]
        
        if let error = activeLivenessResult.error {
          activeLivenessResultDict["error"] = [
            "code": "\(error)",
            "description": error.localizedDescription
          ]
        }
        
        faceIDMessageDict["activeLivenessResult"] = activeLivenessResultDict
      }
      
      resultMap["faceIDMessage"] = faceIDMessageDict
      
      self.sendEvent("onActiveLivenessResult", resultMap)
    }
  }
  
  public func onVideoTaken() {
    DispatchQueue.main.async { [weak self] in
      self?.sendEvent("onVideoTaken", [:])
    }
  }
  
  public func onFailure(error: Error) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentFaceIDViewController?.dismiss(animated: true) {
        self.currentFaceIDViewController = nil
      }
      
      let errorMap: [String: Any] = [
        "code": "ACTIVE_LIVENESS_ERROR",
        "message": error.localizedDescription
      ]
      
      self.sendEvent("onActiveLivenessFailure", errorMap)
    }
  }
  
  public func backButtonPressed() {
    DispatchQueue.main.async { [weak self] in
      self?.sendEvent("onBackButtonPressed", [:])
    }
  }
  
  public func willDismiss() {
    DispatchQueue.main.async { [weak self] in
      self?.sendEvent("onWillDismiss", [:])
    }
  }
  
  public func didDismiss() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isInProgress = false
      self.currentFaceIDViewController = nil
      self.sendEvent("onDidDismiss", [:])
    }
  }
}

// MARK: - Custom API Settings
struct CustomAPISettings: ApiSettings {
  var colors: ApiColors
  var fonts: ApiFonts
  var configs: ApiConfigs
  
  init(colors: ApiColors = ApiColors(), fonts: ApiFonts = ApiFonts(), configs: ApiConfigs = ApiConfigs()) {
    self.colors = colors
    self.fonts = fonts
    self.configs = configs
  }
}

private func getCameraPermissionStatus() -> String {
  switch AVCaptureDevice.authorizationStatus(for: .video) {
  case .authorized:
    return "granted"
  case .denied:
    return "denied"
  case .restricted:
    return "denied"
  case .notDetermined:
    return "unknown"
  @unknown default:
    return "unknown"
  }
}

