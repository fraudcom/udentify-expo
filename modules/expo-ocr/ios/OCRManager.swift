//
//  OCRManager.swift
//  OCRLibrary
//
//  Created by Fraud.com on 04/02/25.
//

import Foundation
import UIKit
import ExpoModulesCore

// OCR Framework imports
import UdentifyCommons
import UdentifyOCR

@objc(OCRManager)
class OCRManager: NSObject {
  
  // MARK: - Notifications
  enum Notifications {
    static let ocrResult = Notification.Name("OCRManagerOCRResult")
    static let documentLivenessResult = Notification.Name("OCRManagerDocumentLivenessResult")
    static let hologramResult = Notification.Name("OCRManagerHologramResult")
    static let documentScanResult = Notification.Name("OCRManagerDocumentScanResult")
  }
  
  // OCR Camera Controller
  private var ocrCameraController: OCRCameraViewController?
  // Hologram Camera Controller
  private var hologramCameraController: HologramCameraViewController?
  
  // OCR completion handlers
  private var ocrScanCompletion: ((Bool, Error?) -> Void)?
  private var documentScanCompletion: (([String: Any]) -> Void)?
  // Hologram completion handlers
  private var hologramScanCompletion: ((Bool, Error?) -> Void)?
  private var hologramUploadCompletion: (([String: Any]?, Error?) -> Void)?
  
  private var currentServerURL: String?
  private var currentTransactionID: String?
  private var currentDocumentType: OCRDocumentType?
  private var currentCountry: UdentifyCommons.Country = .TUR
  
  // Store captured images for performOCR
  private var lastCapturedFrontImage: UIImage?
  private var lastCapturedBackImage: UIImage?
  
  // Store captured image paths (server paths from SDK)
  private var lastCapturedFrontImagePath: String?
  private var lastCapturedBackImagePath: String?
  
  // Store UI configuration
  private var uiConfiguration: [String: Any]?
  
  @objc override init() {
    super.init()
    setupLocalizationBundle()
    
    // Also try direct OCRSettingsProvider import approach
    setupOCRSettingsDirectly()
  }
  
  private func setupOCRSettingsDirectly() {
    if let expoOCRBundle = getBundleForExpoModule(),
       let resourceBundlePath = expoOCRBundle.path(forResource: "OCRLibraryResources", ofType: "bundle"),
       let resourceBundle = Bundle(path: resourceBundlePath) {
      
      // Create custom settings with UI configuration
      let customSettings = CustomOCRSettings(localizationBundle: resourceBundle, uiConfig: uiConfiguration)
      
      // Apply OCR settings
      OCRSettingsProvider.getInstance().currentSettings = customSettings
      debugPrint("OCRManager - setupOCRSettingsDirectly completed")
    }
  }
  
  private func setupLocalizationBundle() {
    // Setup custom bundle for localization
    setupCustomLocalizationBundle()
  }
  
  private func setupCustomLocalizationBundle() {
    if let expoOCRBundle = getBundleForExpoModule(),
       let resourceBundlePath = expoOCRBundle.path(forResource: "OCRLibraryResources", ofType: "bundle"),
       let resourceBundle = Bundle(path: resourceBundlePath) {
      
      // Set Udentify SDK localization bundle programmatically
      setUdentifyLocalizationBundle(resourceBundle)
    }
  }
  
  private func setUdentifyLocalizationBundle(_ bundle: Bundle) {
    // Create custom OCR settings with our localization bundle
    let customSettings = CustomOCRSettings(localizationBundle: bundle)
    
    // Apply the settings globally using reflection
    if let settingsProviderClass = NSClassFromString("OCRSettingsProvider") as? NSObject.Type {
      let getInstanceSelector = NSSelectorFromString("getInstance")
      
      if settingsProviderClass.responds(to: getInstanceSelector) {
        let getInstanceMethod = class_getClassMethod(settingsProviderClass, getInstanceSelector)
        
        if let method = getInstanceMethod {
          let implementation = method_getImplementation(method)
          typealias GetInstanceFunction = @convention(c) (AnyClass, Selector) -> AnyObject
          let function = unsafeBitCast(implementation, to: GetInstanceFunction.self)
          
          let providerInstance = function(settingsProviderClass, getInstanceSelector)
          
          // Set currentSettings using setValue
          providerInstance.setValue(customSettings, forKey: "currentSettings")
        }
      }
    }
    debugPrint("OCRManager - setUdentifyLocalizationBundle completed")
  }
  
  // MARK: - Bundle Finding Helper Methods
  
  /// Try to find the ExpoOCR module bundle
  private func getBundleForExpoModule() -> Bundle? {
    // In Expo modules, we can try to get the bundle that contains the ExpoOCRModule class
    let expoModules = [
      "ExpoOCR.ExpoOCRModule",
      "ExpoOCRModule"
    ]
    
    for moduleName in expoModules {
      if let moduleClass = NSClassFromString(moduleName) {
        let moduleBundle = Bundle(for: moduleClass)
        return moduleBundle
      }
    }
    
    // Alternative approach: Try using the current module's bundle
    let currentBundle = Bundle(for: type(of: self))
    return currentBundle
  }
  
  // MARK: - UI Configuration Methods
  
  @objc(configureUISettings:completion:)
  func configureUISettings(
    _ uiConfig: [String: Any],
    completion: @escaping (Bool, Error?) -> Void
  ) {
    debugPrint("OCRManager - configureUISettings called")
    
    // Store the UI configuration
    self.uiConfiguration = uiConfig
    
    // Re-apply OCR settings with the new UI configuration
    setupOCRSettingsDirectly()
    
    completion(true, nil)
  }
  
  // MARK: - OCR Methods
  
  @objc(startOCRScanning:transactionID:documentType:documentSide:country:completion:)
  func startOCRScanning(
    serverURL: String,
    transactionID: String,
    documentType: String,
    documentSide: String,
    country: String,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    DispatchQueue.main.async {
      debugPrint("OCRManager - startOCRScanning called for \(documentType), side: \(documentSide), country: \(country)")
      
      // Convert string parameters to appropriate enum types
      let ocrDocumentType: OCRDocumentType
      switch documentType.uppercased() {
      case "ID_CARD":
        ocrDocumentType = .ID_CARD
      case "PASSPORT":
        ocrDocumentType = .PASSPORT
      case "DRIVE_LICENCE", "DRIVER_LICENSE":
        ocrDocumentType = .DRIVE_LICENCE
      default:
        ocrDocumentType = .ID_CARD
      }
      
      let ocrDocumentSide: OCRDocumentSide
      switch documentSide.uppercased() {
      case "FRONT", "FRONTSIDE":
        ocrDocumentSide = .frontSide
      case "BACK", "BACKSIDE":
        ocrDocumentSide = .backSide
      case "BOTH", "BOTHSIDES":
        ocrDocumentSide = .bothSides
      default:
        ocrDocumentSide = .bothSides
      }
      
      // Convert country string to Country enum using CountryCodeMapper
      let ocrCountry = CountryCodeMapper.toCountry(country)
      
      // Get the current view controller to present OCR camera
      guard let topViewController = self.topViewController() else {
        completion(false, NSError(domain: "OCRManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find view controller to present OCR camera"]))
        return
      }
      
      // Instantiate OCR Camera with API disabled to get images first
      guard let vc = OCRCameraViewController.instantiate(
        withApiCallDisabled: self,
        serverURL: serverURL,
        transactionID: transactionID,
        documentType: ocrDocumentType,
        country: ocrCountry,
        documentSide: ocrDocumentSide,
        manualCapture: false
      ) else {
        completion(false, NSError(domain: "OCRManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to instantiate OCR camera controller"]))
        return
      }
      
      self.ocrCameraController = vc
      vc.modalPresentationStyle = .fullScreen
      
      // Store completion and parameters for later use
      self.ocrScanCompletion = completion
      self.currentServerURL = serverURL
      self.currentTransactionID = transactionID
      self.currentDocumentType = ocrDocumentType
      self.currentCountry = ocrCountry
      
      // Present the camera
      topViewController.present(vc, animated: true)
    }
  }
  
  @objc(performOCR:transactionID:frontSideImage:backSideImage:documentType:country:completion:)
  func performOCR(
    serverURL: String,
    transactionID: String,
    frontSideImage: String,
    backSideImage: String,
    documentType: String,
    country: String,
    completion: @escaping ([String: Any]?, Error?) -> Void
  ) {
    debugPrint("OCRManager - performOCR called for transaction: \(transactionID)")
    
    // Convert string parameters to appropriate enum types
    let ocrDocumentType: OCRDocumentType
    switch documentType.uppercased() {
    case "ID_CARD":
      ocrDocumentType = .ID_CARD
    case "PASSPORT":
      ocrDocumentType = .PASSPORT
    case "DRIVE_LICENCE", "DRIVER_LICENSE":
      ocrDocumentType = .DRIVE_LICENCE
    default:
      ocrDocumentType = .ID_CARD
    }
    
    // Convert country string to Country enum
    let ocrCountry = CountryCodeMapper.toCountry(country)
    
    // Create payload from stored images or paths
    let payload: DocumentScanPayload
    if self.lastCapturedFrontImagePath != nil || self.lastCapturedBackImagePath != nil {
      payload = .imagePaths(front: self.lastCapturedFrontImagePath, back: self.lastCapturedBackImagePath)
    } else {
      payload = .images(front: self.lastCapturedFrontImage, back: self.lastCapturedBackImage)
    }
    
    // Perform actual OCR API call
    OCRCameraViewController.performOCR(
      serverURL: serverURL,
      transactionID: transactionID,
      documentPayload: payload,
      country: ocrCountry,
      documentType: ocrDocumentType
    ) { (response, error) in
      DispatchQueue.main.async {
        self.clearStoredData()
        
        if let error = error {
          completion(nil, error)
        } else if let ocrResponse = response {
          let resultDict = self.convertOCRResponseToDict(ocrResponse, transactionID: transactionID)
          completion(resultDict, nil)
        } else {
          let error = NSError(domain: "OCRManager", code: -5, userInfo: [NSLocalizedDescriptionKey: "No OCR response received"])
          completion(nil, error)
        }
      }
    }
  }
  
  @objc(performDocumentLiveness:transactionID:frontSideImage:backSideImage:completion:)
  func performDocumentLiveness(
    serverURL: String,
    transactionID: String,
    frontSideImage: String,
    backSideImage: String,
    completion: @escaping ([String: Any]?, Error?) -> Void
  ) {
    debugPrint("OCRManager - performDocumentLiveness called for transaction: \(transactionID)")
    
    // Create payload from stored images or paths
    let payload: DocumentScanPayload
    if self.lastCapturedFrontImagePath != nil || self.lastCapturedBackImagePath != nil {
      payload = .imagePaths(front: self.lastCapturedFrontImagePath, back: self.lastCapturedBackImagePath)
    } else {
      payload = .images(front: self.lastCapturedFrontImage, back: self.lastCapturedBackImage)
    }
    
    // Perform actual Document Liveness API call
    OCRCameraViewController.performDocumentLiveness(
      serverURL: serverURL,
      transactionID: transactionID,
      documentPayload: payload
    ) { (response) in
      DispatchQueue.main.async {
        self.clearStoredData()
        
        if response.isFailed {
          let error = NSError(domain: "OCRManager", code: -6, userInfo: [NSLocalizedDescriptionKey: "Document liveness check failed"])
          completion(nil, error)
        } else {
          let resultDict = self.convertDocumentLivenessResponseToDict(response, transactionID: transactionID)
          completion(resultDict, nil)
        }
      }
    }
  }
  
  @objc(performOCRAndDocumentLiveness:transactionID:frontSideImage:backSideImage:documentType:country:completion:)
  func performOCRAndDocumentLiveness(
    serverURL: String,
    transactionID: String,
    frontSideImage: String,
    backSideImage: String,
    documentType: String,
    country: String,
    completion: @escaping ([String: Any]?, Error?) -> Void
  ) {
    debugPrint("OCRManager - performOCRAndDocumentLiveness called for transaction: \(transactionID)")
    
    // Convert string parameters to appropriate enum types
    let ocrDocumentType: OCRDocumentType
    switch documentType.uppercased() {
    case "ID_CARD":
      ocrDocumentType = .ID_CARD
    case "PASSPORT":
      ocrDocumentType = .PASSPORT
    case "DRIVE_LICENCE", "DRIVER_LICENSE":
      ocrDocumentType = .DRIVE_LICENCE
    default:
      ocrDocumentType = .ID_CARD
    }
    
    // Convert country string to Country enum
    let ocrCountry = CountryCodeMapper.toCountry(country)
    
    // Create payload from stored images or paths
    let payload: DocumentScanPayload
    if self.lastCapturedFrontImagePath != nil || self.lastCapturedBackImagePath != nil {
      payload = .imagePaths(front: self.lastCapturedFrontImagePath, back: self.lastCapturedBackImagePath)
    } else {
      payload = .images(front: self.lastCapturedFrontImage, back: self.lastCapturedBackImage)
    }
    
    // Perform actual OCR and Document Liveness API call
    OCRCameraViewController.performOCRAndDocumentLiveness(
      serverURL: serverURL,
      transactionID: transactionID,
      documentPayload: payload,
      country: ocrCountry,
      documentType: ocrDocumentType
    ) { (response) in
      DispatchQueue.main.async {
        self.clearStoredData()
        
        if response.isFailed {
          let error = NSError(domain: "OCRManager", code: -11, userInfo: [NSLocalizedDescriptionKey: "OCR and document liveness check failed"])
          completion(nil, error)
        } else {
          let resultDict = self.convertDocumentLivenessResponseToDict(response, transactionID: transactionID)
          completion(resultDict, nil)
        }
      }
    }
  }
  
  // MARK: - Hologram Methods
  
  @objc(startHologramCamera:transactionID:completion:)
  func startHologramCamera(
    serverURL: String,
    transactionID: String,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    DispatchQueue.main.async {
      debugPrint("OCRManager - startHologramCamera called for transaction: \(transactionID)")
      
      // Get the current view controller to present Hologram camera
      guard let topViewController = self.topViewController() else {
        completion(false, NSError(domain: "OCRManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find view controller to present Hologram camera"]))
        return
      }
      
      // Instantiate Hologram Camera
      guard let vc = HologramCameraViewController.instantiate(
        delegate: self,
        serverURL: serverURL,
        transactionID: transactionID
      ) else {
        completion(false, NSError(domain: "OCRManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to instantiate Hologram camera controller"]))
        return
      }
      
      self.hologramCameraController = vc
      vc.modalPresentationStyle = .fullScreen
      
      // Store completion and parameters for later use
      self.hologramScanCompletion = completion
      self.currentServerURL = serverURL
      self.currentTransactionID = transactionID
      
      // Present the camera
      topViewController.present(vc, animated: true)
    }
  }
  
  @objc(performHologramCheck:transactionID:videoUrls:completion:)
  func performHologramCheck(
    serverURL: String,
    transactionID: String,
    videoUrls: [String],
    completion: @escaping ([String: Any]?, Error?) -> Void
  ) {
    debugPrint("OCRManager - performHologramCheck called for transaction: \(transactionID)")
    
    // Convert string URLs to URL objects
    let urlObjects = videoUrls.compactMap { URL(string: $0) }
    
    if urlObjects.isEmpty {
      let error = NSError(domain: "OCRManager", code: -9, userInfo: [NSLocalizedDescriptionKey: "No valid video URLs provided for hologram check"])
      completion(nil, error)
      return
    }
    
    // Perform actual Hologram API call
    HologramCameraViewController.uploadHologramVideo(
      serverURL: serverURL,
      transactionID: transactionID,
      paths: urlObjects
    ) { (response) in
      DispatchQueue.main.async {
        if let error = response.error {
          completion(nil, error)
        } else {
          let resultDict = self.convertHologramResponseToDict(response, transactionID: transactionID)
          completion(resultDict, nil)
        }
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func clearStoredData() {
    self.lastCapturedFrontImage = nil
    self.lastCapturedBackImage = nil
    self.lastCapturedFrontImagePath = nil
    self.lastCapturedBackImagePath = nil
  }
  
  private func topViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
      return nil
    }
    
    var topController = window.rootViewController
    while let presentedViewController = topController?.presentedViewController {
      topController = presentedViewController
    }
    return topController
  }
  
  private func convertOCRResponseToDict(_ response: OCRResponse, transactionID: String) -> [String: Any] {
    var resultDict: [String: Any] = [:]
    resultDict["success"] = true
    resultDict["transactionID"] = transactionID
    resultDict["timestamp"] = Date().timeIntervalSince1970
    
    switch response {
    case .idCard(let idCardResponse):
      resultDict["documentType"] = "ID_CARD"
      
      // Build extracted data dictionary step by step for ID Card
      var extractedData: [String: Any] = [:]
      extractedData["firstName"] = idCardResponse.firstName ?? ""
      extractedData["lastName"] = idCardResponse.lastName ?? ""
      extractedData["documentNumber"] = idCardResponse.documentID ?? ""
      extractedData["identityNo"] = idCardResponse.identityNo ?? ""
      extractedData["expiryDate"] = idCardResponse.expiryDate ?? ""
      extractedData["birthDate"] = idCardResponse.birthDate ?? ""
      extractedData["nationality"] = idCardResponse.nationality ?? ""
      extractedData["gender"] = idCardResponse.gender ?? ""
      extractedData["countryCode"] = idCardResponse.countryCode ?? ""
      extractedData["documentIssuer"] = idCardResponse.documentIssuer ?? ""
      extractedData["motherName"] = idCardResponse.motherName ?? ""
      extractedData["fatherName"] = idCardResponse.fatherName ?? ""
      extractedData["isDocumentExpired"] = idCardResponse.isOCRDocumentExpired ?? false
      extractedData["isIDValid"] = idCardResponse.isOCRIDValid ?? false
      extractedData["hasPhoto"] = idCardResponse.hasOCRPhoto ?? false
      extractedData["hasSignature"] = idCardResponse.hasOCRSignature ?? false
      
      resultDict["extractedData"] = extractedData
      
    case .driverLicense(let driverLicenseResponse):
      resultDict["documentType"] = "DRIVER_LICENSE"
      
      // Build extracted data dictionary step by step for Driver License
      var extractedData: [String: Any] = [:]
      extractedData["firstName"] = driverLicenseResponse.firstName ?? ""
      extractedData["lastName"] = driverLicenseResponse.lastName ?? ""
      extractedData["documentNumber"] = driverLicenseResponse.documentID ?? ""
      extractedData["identityNo"] = driverLicenseResponse.identityNo ?? ""
      extractedData["expiryDate"] = driverLicenseResponse.expiryDate ?? ""
      extractedData["birthDate"] = driverLicenseResponse.birthDate ?? ""
      extractedData["countryCode"] = driverLicenseResponse.countryCode ?? ""
      extractedData["issueDate"] = driverLicenseResponse.issueDate ?? ""
      extractedData["licenseType"] = driverLicenseResponse.ocrLicenceType ?? ""
      extractedData["city"] = driverLicenseResponse.city ?? ""
      extractedData["district"] = driverLicenseResponse.district ?? ""
      extractedData["isDocumentExpired"] = driverLicenseResponse.isOCRDocumentExpired ?? false
      extractedData["isIDValid"] = driverLicenseResponse.isOCRIDValid ?? false
      
      resultDict["extractedData"] = extractedData
    case .passport(_): break
    }
    
    return resultDict
  }
  
  private func convertDocumentLivenessResponseToDict(_ response: OCRAndDocumentLivenessResponse, transactionID: String) -> [String: Any] {
    var resultDict: [String: Any] = [:]
    resultDict["success"] = !response.isFailed
    resultDict["transactionID"] = transactionID
    resultDict["timestamp"] = Date().timeIntervalSince1970
    
    // Add front side liveness data
    if let frontData = response.documentLivenessDataFront?.documentLivenessResponse {
      let frontProbabilityString = frontData.aggregateDocumentLivenessProbability ?? "0"
      resultDict["frontSideProbability"] = Double(frontProbabilityString) ?? 0.0
      
      // Build front side results array step by step
      var frontSideResults: [[String: Any]] = []
      if let pipelineResults = frontData.pipelineResults {
        for result in pipelineResults {
          var resultDict: [String: Any] = [:]
          resultDict["name"] = result.name ?? ""
          
          let probabilityString = result.documentLivenessProbability ?? "0"
          resultDict["probability"] = Double(probabilityString) ?? 0.0
          resultDict["calibration"] = result.calibration ?? ""
          
          frontSideResults.append(resultDict)
        }
      }
      resultDict["frontSideResults"] = frontSideResults
    }
    
    // Add back side liveness data
    if let backData = response.documentLivenessDataBack?.documentLivenessResponse {
      let backProbabilityString = backData.aggregateDocumentLivenessProbability ?? "0"
      resultDict["backSideProbability"] = Double(backProbabilityString) ?? 0.0
      
      // Build back side results array step by step
      var backSideResults: [[String: Any]] = []
      if let pipelineResults = backData.pipelineResults {
        for result in pipelineResults {
          var resultDict: [String: Any] = [:]
          resultDict["name"] = result.name ?? ""
          
          let probabilityString = result.documentLivenessProbability ?? "0"
          resultDict["probability"] = Double(probabilityString) ?? 0.0
          resultDict["calibration"] = result.calibration ?? ""
          
          backSideResults.append(resultDict)
        }
      }
      resultDict["backSideResults"] = backSideResults
    }
    
    // Add OCR data if available
    if let ocrData = response.ocrData {
      if let ocrResponse = ocrData.ocrResponse {
        resultDict["ocrData"] = convertOCRResponseToDict(ocrResponse, transactionID: transactionID)
      }
    }
    
    return resultDict
  }
  
  private func convertHologramResponseToDict(_ response: HologramResponse, transactionID: String) -> [String: Any] {
    var resultDict: [String: Any] = [:]
    resultDict["success"] = response.error == nil
    resultDict["transactionID"] = transactionID
    resultDict["timestamp"] = Date().timeIntervalSince1970
    
    // Add hologram specific data
    resultDict["idNumber"] = response.idNumber ?? ""
    resultDict["hologramExists"] = response.hologramExists ?? false
    resultDict["ocrIdAndHologramIdMatch"] = response.ocrIdAndHologramIdMatch ?? false
    resultDict["ocrFaceAndHologramFaceMatch"] = response.ocrFaceAndHologramFaceMatch ?? false
    
    // Convert hologram face image to base64 if available
    if let hologramImage = response.hologramFaceImage,
       let imageData = hologramImage.jpegData(compressionQuality: 0.8) {
      resultDict["hologramFaceImageBase64"] = imageData.base64EncodedString()
    }
    
    // Add error information if available
    if let error = response.error {
      resultDict["error"] = error.localizedDescription
    }
    
    return resultDict
  }
}

// MARK: - Camera Controller Delegates
@available(iOS 11.0, *)
extension OCRManager: OCRCameraControllerDelegate, HologramCameraControllerDelegate {
  
  func willDismiss(controllerType: UdentifyOCR.ControllerType) {
  }
  
  func didDismiss(controllerType: UdentifyOCR.ControllerType) {
    if controllerType == .OcrViewController {
      self.ocrCameraController = nil
    } else if controllerType == .HologramViewController {
      self.hologramCameraController = nil
    }
  }
  
  public func onSuccess(response: OCRResponse) {
    debugPrint("OCRManager - onSuccess called")
    self.ocrScanCompletion?(true, nil)
    self.ocrScanCompletion = nil
  }
  
  public func onFailure(error: Error) {
    debugPrint("OCRManager - onFailure called: \(error.localizedDescription)")
    // Try to determine if this is OCR or Hologram failure based on which completion handler is active
    if self.ocrScanCompletion != nil {
      // Emit OCR error event
      NotificationCenter.default.post(
        name: NSNotification.Name("OCROCRError"), 
        object: nil, 
        userInfo: ["message": error.localizedDescription]
      )
      self.ocrScanCompletion?(false, error)
      self.ocrScanCompletion = nil
    } else if self.hologramScanCompletion != nil {
      // Emit hologram error event
      NotificationCenter.default.post(
        name: NSNotification.Name("OCRHologramError"), 
        object: nil, 
        userInfo: ["message": error.localizedDescription]
      )
      self.hologramScanCompletion?(false, error)
      self.hologramScanCompletion = nil
    }
  }
  
  func onDocumentScan(for side: UdentifyOCR.OCRDocumentSide, payload: UdentifyOCR.DocumentScanPayload) {
      debugPrint("OCRManager - onDocumentScan called for side: \(side)")
      var scanResult: [String: Any] = [:]
      
      switch side {
      case .frontSide:
        scanResult["documentSide"] = "frontSide"
      case .backSide:
        scanResult["documentSide"] = "backSide"
      case .bothSides:
        scanResult["documentSide"] = "bothSide"
      @unknown default:
        scanResult["documentSide"] = "unknown"
      }
      
      switch payload {
      case .imagePaths(front: let frontPath, back: let backPath):
        switch side {
        case .bothSides:
          self.lastCapturedFrontImagePath = frontPath
          self.lastCapturedBackImagePath = backPath
          if let fp = frontPath { scanResult["frontSidePhotoPath"] = fp }
          if let bp = backPath { scanResult["backSidePhotoPath"] = bp }
        case .frontSide:
          self.lastCapturedFrontImagePath = frontPath
          if let fp = frontPath { scanResult["frontSidePhotoPath"] = fp }
        case .backSide:
          self.lastCapturedBackImagePath = backPath
          if let bp = backPath { scanResult["backSidePhotoPath"] = bp }
        @unknown default:
          break
        }
        
      case .images(front: let frontImage, back: let backImage):
        switch side {
        case .bothSides:
          self.lastCapturedFrontImage = frontImage
          self.lastCapturedBackImage = backImage
          if let frontImage = frontImage, let frontData = frontImage.jpegData(compressionQuality: 0.8) {
            scanResult["frontSidePhoto"] = frontData.base64EncodedString()
          }
          if let backImage = backImage, let backData = backImage.jpegData(compressionQuality: 0.8) {
            scanResult["backSidePhoto"] = backData.base64EncodedString()
          }
        case .frontSide:
          self.lastCapturedFrontImage = frontImage
          if let frontImage = frontImage, let frontData = frontImage.jpegData(compressionQuality: 0.8) {
            scanResult["frontSidePhoto"] = frontData.base64EncodedString()
          }
        case .backSide:
          self.lastCapturedBackImage = backImage
          if let backImage = backImage, let backData = backImage.jpegData(compressionQuality: 0.8) {
            scanResult["backSidePhoto"] = backData.base64EncodedString()
          }
        @unknown default:
          break
        }
        
      @unknown default:
        break
      }
      
      if let transactionID = currentTransactionID {
        scanResult["transactionID"] = transactionID
      }
      
      if let serverURL = currentServerURL {
        scanResult["serverURL"] = serverURL
      }
      
      if let documentType = currentDocumentType {
        scanResult["documentType"] = documentType.rawValue
      }

      // Call the document scan completion callback
      if let callback = self.documentScanCompletion {
        callback(scanResult)
      }
      
      // Complete the scanning process successfully
      self.ocrScanCompletion?(true, nil)
      self.ocrScanCompletion = nil
      self.documentScanCompletion = nil
  }

  func onIqaResult(for side: UdentifyOCR.OCRDocumentSide, iqaFeedback: UdentifyOCR.IQAFeedback) {
    debugPrint("OCRManager - onIqaResult called for side: \(side), feedback: \(iqaFeedback)")
    
    var iqaResult: [String: Any] = [:]
    
    switch side {
    case .frontSide:
      iqaResult["documentSide"] = "frontSide"
    case .backSide:
      iqaResult["documentSide"] = "backSide"
    case .bothSides:
      iqaResult["documentSide"] = "bothSides"
    @unknown default:
      iqaResult["documentSide"] = "unknown"
    }
    
    switch iqaFeedback {
    case .success:
      iqaResult["feedback"] = "success"
      iqaResult["message"] = "Image quality check passed"
    case .blurDetected:
      iqaResult["feedback"] = "blurDetected"
      iqaResult["message"] = "Image is blurry"
    case .glareDetected:
      iqaResult["feedback"] = "glareDetected"
      iqaResult["message"] = "Glare detected on document"
    case .hologramGlare:
      iqaResult["feedback"] = "hologramGlare"
      iqaResult["message"] = "Hologram glare detected which may occlude text"
    case .cardNotDetected:
      iqaResult["feedback"] = "cardNotDetected"
      iqaResult["message"] = "Document not detected in frame"
    case .cardClassificationMismatch:
      iqaResult["feedback"] = "cardClassificationMismatch"
      iqaResult["message"] = "Wrong document type or side"
    case .cardNotIntact:
      iqaResult["feedback"] = "cardNotIntact"
      iqaResult["message"] = "Forgery detected on document"
    case .other:
      iqaResult["feedback"] = "other"
      iqaResult["message"] = "Other image quality issues detected"
    @unknown default:
      iqaResult["feedback"] = "unknown"
      iqaResult["message"] = "Unknown IQA feedback"
    }
    
    iqaResult["timestamp"] = Date().timeIntervalSince1970
    
    // Emit IQA result event
    NotificationCenter.default.post(
      name: NSNotification.Name("OCRIQAResult"),
      object: nil,
      userInfo: iqaResult
    )
  }
  
  func onBackButtonPressed(at controllerType: UdentifyOCR.ControllerType) {
    debugPrint("OCRManager - onBackButtonPressed called for: \(controllerType)")
    if controllerType == .OcrViewController {
      self.ocrScanCompletion?(false, NSError(domain: "OCRManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "User cancelled OCR scanning"]))
      self.ocrScanCompletion = nil
    } else if controllerType == .HologramViewController {
      self.hologramScanCompletion?(false, NSError(domain: "OCRManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "User cancelled Hologram scanning"]))
      self.hologramScanCompletion = nil
    }
  }
  
  func onDestroy(controllerType: UdentifyOCR.ControllerType) {
    if controllerType == .OcrViewController {
      self.ocrCameraController = nil
    } else if controllerType == .HologramViewController {
      self.hologramCameraController = nil
    }
  }
  
  func didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse) {
    debugPrint("OCRManager - didFinishOcrAndDocumentLivenessCheck called")
    self.ocrScanCompletion?(true, nil)
    self.ocrScanCompletion = nil
  }
  
  // MARK: - Hologram-specific delegate methods
  
  public func onVideoRecordFinished(videoUrls: [URL]) {
    debugPrint("OCRManager - onVideoRecordFinished called with \(videoUrls.count) videos")
    
    // Convert URLs to string array and store for upload
    let urlStrings = videoUrls.map { $0.absoluteString }
    
    // Emit video recorded event immediately
    NotificationCenter.default.post(
      name: NSNotification.Name("OCRHologramVideoRecorded"), 
      object: nil, 
      userInfo: ["videoUrls": urlStrings]
    )
    
    // Call performHologramCheck API with the recorded video URLs
    guard let serverURL = currentServerURL,
          let transactionID = currentTransactionID else {
      self.hologramScanCompletion?(false, NSError(domain: "OCRManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing Hologram parameters"]))
      return
    }
    
    // Store the upload completion for later notification
    self.hologramUploadCompletion = { [weak self] (result, error) in
      if let error = error {
        // Emit error event to React Native
        NotificationCenter.default.post(
          name: NSNotification.Name("OCRHologramError"), 
          object: nil, 
          userInfo: ["message": error.localizedDescription]
        )
      } else if let result = result, let strongSelf = self, let _ = strongSelf.currentTransactionID {
        // Emit hologram result
        NotificationCenter.default.post(
          name: NSNotification.Name("OCRHologramComplete"), 
          object: nil, 
          userInfo: result
        )
        // Keep old notification for backward compatibility
        NotificationCenter.default.post(name: Notifications.hologramResult, object: nil, userInfo: result)
      }
    }
    
    // Perform Hologram upload
    performHologramCheck(
      serverURL: serverURL,
      transactionID: transactionID,
      videoUrls: urlStrings
    ) { [weak self] (result, error) in
      DispatchQueue.main.async {
        self?.hologramUploadCompletion?(result, error)
        self?.hologramScanCompletion?(error == nil, error)
        self?.hologramScanCompletion = nil
        self?.hologramUploadCompletion = nil
      }
    }
  }
}
