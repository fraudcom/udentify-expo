import Foundation
import UIKit
import AVFoundation
import UdentifyMRZ
import UdentifyCommons

private struct UICustomization {
    let focusViewBorderColor: UIColor
    let focusViewStrokeWidth: CGFloat
    let instructionText: String
    let instructionTextColor: UIColor
    let showCancelButton: Bool
    let cancelButtonText: String
    let cancelButtonColor: UIColor
    
    init(from customization: NSDictionary?) {
        if let colorHex = customization?["focusViewBorderColor"] as? String {
            self.focusViewBorderColor = UIColor(hex: colorHex) ?? .systemBlue
        } else {
            self.focusViewBorderColor = .systemBlue
        }
        
        if let width = customization?["focusViewStrokeWidth"] as? NSNumber {
            self.focusViewStrokeWidth = CGFloat(width.floatValue)
        } else {
            self.focusViewStrokeWidth = 3.0
        }
        
        if let text = customization?["instructionText"] as? String {
            self.instructionText = text
        } else {
            self.instructionText = MRZBundleHelper.localizedString(forKey: "mrz_scan_instruction", value: "Place document MRZ within the frame", table: nil)
        }
        
        if let colorHex = customization?["instructionTextColor"] as? String {
            self.instructionTextColor = UIColor(hex: colorHex) ?? .white
        } else {
            self.instructionTextColor = .white
        }
        
        if let show = customization?["showCancelButton"] as? Bool {
            self.showCancelButton = show
        } else {
            self.showCancelButton = true
        }
        
        if let text = customization?["cancelButtonText"] as? String {
            self.cancelButtonText = text
        } else {
            self.cancelButtonText = MRZBundleHelper.localizedString(forKey: "cancel", value: "Cancel", table: nil)
        }
        
        if let colorHex = customization?["cancelButtonColor"] as? String {
            self.cancelButtonColor = UIColor(hex: colorHex) ?? .red
        } else {
            self.cancelButtonColor = .red
        }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        switch hexSanitized.count {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

@objc
public class MRZManager: NSObject {
    
    private var currentCompletion: ((NSDictionary) -> Void)?
    private var previewView: UIView?
    private var mrzPreviewView: UIView?
    private var mrzCameraController: MRZCameraController?
    private var mrzReader: MRZReader?
    
    @objc func checkPermissions(_ completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let hasPermission = status == .authorized
        completion(hasPermission)
    }
    
    @objc func requestPermissions(_ completion: @escaping (String) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion("granted")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted ? "granted" : "denied")
                }
            }
        case .denied, .restricted:
            completion("denied")
        @unknown default:
            completion("denied")
        }
    }
    
    @objc func startMrzCamera(_ customization: NSDictionary?, completion: @escaping (NSDictionary) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            let errorResult: [String: Any] = [
                "success": false,
                "errorMessage": "PERMISSION_DENIED - Camera permission is required for MRZ scanning"
            ]
            completion(errorResult as NSDictionary)
            return
        }
        
        print("MRZManager - Starting MRZ camera")
        
        currentCompletion = completion
        
        DispatchQueue.main.async { [weak self] in
            var viewController: UIViewController?
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                viewController = window.rootViewController
            } else if let window = UIApplication.shared.windows.first {
                viewController = window.rootViewController
            }
            
            guard let viewController = viewController else {
                let errorResult: [String: Any] = [
                    "success": false,
                    "errorMessage": "NO_VIEW_CONTROLLER - Could not find root view controller"
                ]
                completion(errorResult as NSDictionary)
                return
            }
            
            let uiCustomization = UICustomization(from: customization)
            self?.setupPreviewViews(in: viewController.view, customization: uiCustomization)
            self?.startRealMrzCamera(customization: uiCustomization)
        }
    }
    
    @objc func processMrzImage(_ imageBase64: String, completion: @escaping (NSDictionary) -> Void) {
        print("MRZManager - Processing MRZ image")
        
        guard let imageData = Data(base64Encoded: imageBase64),
              let image = UIImage(data: imageData) else {
            let errorResult: [String: Any] = [
                "success": false,
                "errorMessage": "INVALID_IMAGE - Failed to decode Base64 image"
            ]
            completion(errorResult as NSDictionary)
            return
        }
        
        currentCompletion = completion
        processRealMrzImage(image: image)
    }
    
    @objc func cancelMrzScanning(_ completion: @escaping () -> Void) {
        print("MRZManager - Cancelling MRZ scanning and cleaning up resources")
        
        DispatchQueue.main.async { [weak self] in
            self?.mrzCameraController?.pauseMRZ()
            self?.mrzCameraController = nil
            self?.mrzReader = nil
            
            self?.cleanupPreviewViews()
            
            if let currentCompletion = self?.currentCompletion {
                let cancelResult: [String: Any] = [
                    "success": false,
                    "errorMessage": "USER_CANCELLED",
                    "cancelled": true
                ]
                currentCompletion(cancelResult as NSDictionary)
            }
            self?.currentCompletion = nil
            
            completion()
        }
    }
    
    private func setupPreviewViews(in parentView: UIView, customization: UICustomization) {
        previewView = UIView(frame: parentView.bounds)
        previewView?.backgroundColor = UIColor.black
        parentView.addSubview(previewView!)
        
        let mrzFrame = CGRect(
            x: 20,
            y: parentView.bounds.height * 0.6,
            width: parentView.bounds.width - 40,
            height: 100
        )
        mrzPreviewView = UIView(frame: mrzFrame)
        mrzPreviewView?.backgroundColor = UIColor.clear
        parentView.addSubview(mrzPreviewView!)
        
        let instructionLabel = UILabel(frame: CGRect(
            x: 20,
            y: mrzFrame.origin.y - 60,
            width: parentView.bounds.width - 40,
            height: 50
        ))
        instructionLabel.text = customization.instructionText
        instructionLabel.textColor = customization.instructionTextColor
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        parentView.addSubview(instructionLabel)
        
        if customization.showCancelButton {
            let cancelButton = UIButton(frame: CGRect(
                x: parentView.bounds.width - 80,
                y: 50,
                width: 60,
                height: 40
            ))
            cancelButton.setTitle(customization.cancelButtonText, for: .normal)
            cancelButton.setTitleColor(UIColor.white, for: .normal)
            cancelButton.backgroundColor = customization.cancelButtonColor.withAlphaComponent(0.7)
            cancelButton.layer.cornerRadius = 8
            cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
            parentView.addSubview(cancelButton)
        }
    }
    
    @objc private func cancelButtonTapped() {
        print("MRZManager - Cancel button tapped - dismissing MRZ screen")
        
        if let completion = currentCompletion {
            let cancelResult: [String: Any] = [
                "success": false,
                "errorMessage": "USER_CANCELLED",
                "cancelled": true
            ]
            completion(cancelResult as NSDictionary)
            currentCompletion = nil
        }
        
        let dummyCompletion: () -> Void = {}
        cancelMrzScanning(dummyCompletion)
    }
    
    private func startRealMrzCamera(customization: UICustomization) {
        print("MRZManager - Starting real MRZ camera with Udentify SDK")
        
        mrzCameraController = MRZCameraController(
            on: previewView!,
            mrzPreviewView: mrzPreviewView!,
            focusViewBorderColor: customization.focusViewBorderColor,
            focusViewStrokeWidth: customization.focusViewStrokeWidth,
            delegate: self
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.mrzCameraController?.resumeMRZ()
            print("MRZManager - MRZ camera initialized successfully")
        }
    }
    
    private func processRealMrzImage(image: UIImage) {
        print("MRZManager - Processing image with real Udentify MRZ SDK")
        
        mrzReader = MRZReader()
        
        var sourceImage = image
        mrzReader?.processImage(sourceImage: &sourceImage) { [weak self] (parser, progress) in
            DispatchQueue.main.async {
                if let parser = parser {
                    let mrzData = self?.extractMrzData(from: parser) ?? [:]
                    
                    let mrzResult: [String: Any] = [
                        "success": true,
                        "mrzData": mrzData,
                        "documentNumber": mrzData["documentNumber"] ?? "",
                        "dateOfBirth": mrzData["dateOfBirth"] ?? "",
                        "dateOfExpiration": mrzData["dateOfExpiration"] ?? ""
                    ]
                    
                    self?.currentCompletion?(mrzResult as NSDictionary)
                    self?.currentCompletion = nil
                } else {
                    print("MRZManager - Image processing progress: \(Int(progress))%")
                }
            }
        }
    }
    
    private func extractMrzData(from parser: Any) -> [String: Any] {
        guard let mrzParser = parser as? MRZParser else {
            return [:]
        }
        
        let data = mrzParser.data()
        
        let documentNumber = data[MRZField.DocumentNumber] as? String ?? ""
        let dateOfBirth = data[MRZField.DateOfBirth] as? String ?? ""
        let dateOfExpiration = data[MRZField.ExpirationDate] as? String ?? ""
        
        let documentType = ""
        let issuingCountry = ""
        let gender = ""
        let nationality = ""
        let surname = ""
        let givenNames = ""
        let optionalData1: String? = nil
        let optionalData2: String? = nil
        
        return [
            "documentType": documentType,
            "issuingCountry": issuingCountry,
            "documentNumber": documentNumber,
            "optionalData1": optionalData1 ?? "",
            "dateOfBirth": dateOfBirth,
            "gender": gender,
            "dateOfExpiration": dateOfExpiration,
            "nationality": nationality,
            "optionalData2": optionalData2 ?? "",
            "surname": surname,
            "givenNames": givenNames
        ]
    }
    
    private func cleanupPreviewViews() {
        print("MRZManager - Cleaning up MRZ preview views and UI elements")
        
        DispatchQueue.main.async { [weak self] in
            self?.mrzCameraController?.pauseMRZ()
            
            self?.previewView?.removeFromSuperview()
            self?.mrzPreviewView?.removeFromSuperview()
            self?.previewView = nil
            self?.mrzPreviewView = nil
            
            if let window = UIApplication.shared.windows.first {
                let rootView = window.rootViewController?.view
                rootView?.subviews.forEach { subview in
                    if subview.backgroundColor == UIColor.black ||
                       subview.layer.borderColor == UIColor.white.cgColor ||
                       subview.layer.borderColor == UIColor.systemBlue.cgColor ||
                       (subview as? UILabel)?.text?.contains("MRZ") == true ||
                       (subview as? UILabel)?.text?.contains("document") == true ||
                       (subview as? UIButton)?.titleLabel?.text?.contains("Cancel") == true {
                        print("MRZManager - Removing MRZ UI element: \(type(of: subview))")
                        subview.removeFromSuperview()
                    }
                }
            }
            
            print("MRZManager - MRZ cleanup completed - screen should be dismissed")
        }
    }
}

extension MRZManager: MRZCameraControllerDelegate {
    
    public func onStart() {
        print("MRZManager - MRZ process started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mrzCameraController?.resumeMRZ()
        }
    }
    
    public func onStop() {
        print("MRZManager - MRZ process stopped")
    }
    
    public func onPause() {
        print("MRZManager - MRZ process paused")
    }
    
    public func onResume() {
        print("MRZManager - MRZ process resumed")
    }
    
    public func onDestroy() {
        print("MRZManager - MRZ controller destroyed")
        DispatchQueue.main.async { [weak self] in
            self?.currentCompletion = nil
            self?.cleanupPreviewViews()
        }
    }
    
    public func onSuccess(documentNumber: String?, dateOfBirth: String?, dateOfExpiration: String?) {
        DispatchQueue.main.async { [weak self] in
            let mrzData: [String: Any] = [
                "documentType": "",
                "issuingCountry": "",
                "documentNumber": documentNumber ?? "",
                "optionalData1": "",
                "dateOfBirth": dateOfBirth ?? "",
                "gender": "",
                "dateOfExpiration": dateOfExpiration ?? "",
                "nationality": "",
                "optionalData2": "",
                "surname": "",
                "givenNames": ""
            ]
            
            let mrzResult: [String: Any] = [
                "success": true,
                "mrzData": mrzData,
                "documentNumber": documentNumber ?? "",
                "dateOfBirth": dateOfBirth ?? "",
                "dateOfExpiration": dateOfExpiration ?? ""
            ]
            
            self?.currentCompletion?(mrzResult as NSDictionary)
            self?.currentCompletion = nil
            
            self?.mrzCameraController = nil
            self?.cleanupPreviewViews()
        }
    }
    
    public func onProgress(progress: Float) {
        if progress > 50 {
            print("MRZManager - MRZ scan progress: \(Int(progress))%")
        }
    }
    
    public func onFailure(error: Error) {
        DispatchQueue.main.async { [weak self] in
            let errorMessage: String
            
            if let cameraError = error as? CameraError {
                switch cameraError {
                case .CameraNotFound:
                    errorMessage = "CAMERA_NOT_FOUND - Couldn't find the camera"
                case .CameraPermissionRequired:
                    errorMessage = "CAMERA_PERMISSION_REQUIRED - Camera permission is required"
                case .FocusViewInvalidSize(let message):
                    errorMessage = "FOCUS_VIEW_INVALID_SIZE - MrzPreviewView's size is invalid: \(message)"
                case .SessionPresetNotAvailable:
                    errorMessage = "SESSION_PRESET_NOT_AVAILABLE - Min. 720p rear camera is required"
                case .Unknown:
                    errorMessage = "UNKNOWN_ERROR - Unknown camera error occurred"
                case .MinIOSRequirementNotSatisfied:
                    errorMessage = "MIN_IOS_REQUIREMENT_NOT_SATISFIED - Required iOS version is not supported"
                default:
                    errorMessage = "UNKNOWN_CAMERA_ERROR - An unknown camera error occurred"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            print("MRZManager - MRZ error: \(errorMessage)")
            
            if let completion = self?.currentCompletion {
                let mrzResult: [String: Any] = [
                    "success": false,
                    "errorMessage": errorMessage
                ]
                completion(mrzResult as NSDictionary)
            }
            self?.currentCompletion = nil
            self?.cleanupPreviewViews()
        }
    }
}

