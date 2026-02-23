import ExpoModulesCore
import Foundation
import UIKit
import AVFoundation
import UdentifyCommons

public class ExpoVideoCallModule: ExpoModulesCore.Module {
    
    private var videoCallViewController: UIViewController?
    private var videoCallOperator: VideoCallOperatorImpl?
    private var currentStatus = "idle"
    private var uiConfiguration: [String: Any]?
    
    public func definition() -> ModuleDefinition {
        Name("ExpoVideoCall")
        
        Events(
            "VideoCall_onStatusChanged",
            "VideoCall_onError",
            "VideoCall_onUserStateChanged",
            "VideoCall_onParticipantStateChanged",
            "VideoCall_onVideoCallEnded",
            "VideoCall_onVideoCallDismissed"
        )
        
        OnCreate {
            NSLog("ExpoVideoCallModule - OnCreate")
            self.setupLocalizationBundle()
        }
        
        OnDestroy {
            NSLog("ExpoVideoCallModule - OnDestroy")
        }
        
        AsyncFunction("checkPermissions") { () -> [String: Any] in
            NSLog("ExpoVideoCallModule - checkPermissions")
            
            let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            let hasCameraPermission = cameraStatus == .authorized
            
            let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            let hasRecordAudioPermission = microphoneStatus == .authorized
            
            let hasPhoneStatePermission = true
            let hasInternetPermission = true
            
            return [
                "hasCameraPermission": hasCameraPermission,
                "hasPhoneStatePermission": hasPhoneStatePermission,
                "hasInternetPermission": hasInternetPermission,
                "hasRecordAudioPermission": hasRecordAudioPermission
            ]
        }
        
        AsyncFunction("requestPermissions") { () -> String in
            NSLog("ExpoVideoCallModule - requestPermissions")
            
            return await withCheckedContinuation { continuation in
                let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
                let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                
                let needsCameraPermission = cameraStatus == .notDetermined
                let needsMicrophonePermission = microphoneStatus == .notDetermined
                
                if !needsCameraPermission && !needsMicrophonePermission {
                    let cameraGranted = cameraStatus == .authorized
                    let microphoneGranted = microphoneStatus == .authorized
                    continuation.resume(returning: (cameraGranted && microphoneGranted) ? "granted" : "denied")
                    return
                }
                
                if needsCameraPermission {
                    AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
                        if needsMicrophonePermission {
                            AVCaptureDevice.requestAccess(for: .audio) { microphoneGranted in
                                DispatchQueue.main.async(execute: {
                                    continuation.resume(returning: (cameraGranted && microphoneGranted) ? "granted" : "denied")
                                })
                            }
                        } else {
                            DispatchQueue.main.async(execute: {
                                let microphoneGranted = microphoneStatus == .authorized
                                continuation.resume(returning: (cameraGranted && microphoneGranted) ? "granted" : "denied")
                            })
                        }
                    }
                } else if needsMicrophonePermission {
                    AVCaptureDevice.requestAccess(for: .audio) { microphoneGranted in
                        DispatchQueue.main.async(execute: {
                            let cameraGranted = cameraStatus == .authorized
                            continuation.resume(returning: (cameraGranted && microphoneGranted) ? "granted" : "denied")
                        })
                    }
                }
            }
        }
        
        AsyncFunction("startVideoCall") { [weak self] (credentials: [String: Any]) -> [String: Any] in
            guard let self = self else {
                throw NSError(domain: "ExpoVideoCall", code: -1, userInfo: [NSLocalizedDescriptionKey: "Module deallocated"])
            }
            
            NSLog("ExpoVideoCallModule - Starting video call...")
            
            guard let serverURL = credentials["serverURL"] as? String,
                  let wssURL = credentials["wssURL"] as? String,
                  let userID = credentials["userID"] as? String,
                  let transactionID = credentials["transactionID"] as? String,
                  let clientName = credentials["clientName"] as? String else {
                throw NSError(domain: "ExpoVideoCall", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing required parameters"])
            }
            
            let idleTimeout = credentials["idleTimeout"] as? String ?? "30"
            
            return try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.main.async(execute: {
                    self.videoCallOperator = VideoCallOperatorImpl(
                        serverURL: serverURL,
                        wssURL: wssURL,
                        userID: userID,
                        transactionID: transactionID,
                        clientName: clientName,
                        idleTimeout: idleTimeout,
                        eventSender: { eventName, body in
                            self.sendEvent(eventName, body ?? [:])
                        }
                    )
                    
                    let settings: VCSettings
                    
                    if let bundle = VideoCallBundleHelper.localizationBundle {
                        let customSettings = CustomVideoCallSettings(
                            localizationBundle: bundle,
                            uiConfig: self.uiConfiguration
                        )
                        settings = customSettings.createVCSettings()
                    } else {
                        settings = VCSettings(
                            backgroundColor: .black,
                            backgroundStyle: nil,
                            overlayImageStyle: nil,
                            muteButtonStyle: VCMuteButtonStyle(),
                            cameraSwitchButtonStyle: VCCameraSwitchButtonStyle(),
                            pipViewStyle: UdentifyViewStyle(
                                backgroundColor: .clear,
                                borderColor: .white,
                                cornerRadius: 10,
                                borderWidth: 2,
                                horizontalSizing: .fixed(width: 120, horizontalPosition: .right(offset: 16)),
                                verticalSizing: .fixed(height: 135, verticalPosition: .bottom(offset: 0))
                            ),
                            instructionLabelStyle: UdentifyTextStyle(
                                font: UIFont.systemFont(ofSize: 20, weight: .medium),
                                textColor: .white,
                                numberOfLines: 0,
                                leading: 35,
                                trailing: 35
                            ),
                            requestTimeout: 30
                        )
                    }
                    
                    let videoCallViewController = VCCameraController(
                        delegate: self.videoCallOperator!,
                        serverURL: serverURL,
                        wsURL: wssURL,
                        transactionID: transactionID,
                        username: clientName,
                        idleTimeout: Int(idleTimeout) ?? 100,
                        settings: settings,
                        logLevel: .info
                    )
                    self.videoCallViewController = videoCallViewController
                    
                    if let viewController = UIApplication.shared.windows.first?.rootViewController {
                        viewController.present(videoCallViewController, animated: true) {
                            let resultMap: [String: Any] = [
                                "success": true,
                                "status": "connecting",
                                "transactionID": transactionID
                            ]
                            continuation.resume(returning: resultMap)
                        }
                    } else {
                        continuation.resume(throwing: NSError(domain: "ExpoVideoCall", code: -3, userInfo: [NSLocalizedDescriptionKey: "No view controller available"]))
                    }
                })
            }
        }
        
        AsyncFunction("endVideoCall") { [weak self] () -> [String: Any] in
            guard let self = self else {
                return ["success": true, "status": "disconnected"]
            }
            
            return await withCheckedContinuation { continuation in
                DispatchQueue.main.async(execute: {
                    if let viewController = self.videoCallViewController as? VCCameraController {
                        viewController.dismissController()
                        self.videoCallViewController = nil
                        self.videoCallOperator = nil
                        
                        let resultMap: [String: Any] = [
                            "success": true,
                            "status": "disconnected"
                        ]
                        continuation.resume(returning: resultMap)
                    } else {
                        let resultMap: [String: Any] = [
                            "success": true,
                            "status": "disconnected"
                        ]
                        continuation.resume(returning: resultMap)
                    }
                })
            }
        }
        
        AsyncFunction("getVideoCallStatus") { [weak self] () -> String in
            guard let self = self else {
                return "idle"
            }
            return self.videoCallOperator?.getStatus() ?? "idle"
        }
        
        AsyncFunction("setVideoCallConfig") { [weak self] (config: [String: Any]) in
            guard let self = self else { return }
            
            NSLog("ExpoVideoCallModule - setVideoCallConfig")
            
            let backgroundColor = config["backgroundColor"] as? String
            let textColor = config["textColor"] as? String
            let pipViewBorderColor = config["pipViewBorderColor"] as? String
            let notificationLabelDefault = config["notificationLabelDefault"] as? String
            let notificationLabelCountdown = config["notificationLabelCountdown"] as? String
            let notificationLabelTokenFetch = config["notificationLabelTokenFetch"] as? String
            
            self.videoCallOperator?.setConfig(
                backgroundColor: backgroundColor,
                textColor: textColor,
                pipViewBorderColor: pipViewBorderColor,
                notificationLabelDefault: notificationLabelDefault,
                notificationLabelCountdown: notificationLabelCountdown,
                notificationLabelTokenFetch: notificationLabelTokenFetch
            )
        }
        
        AsyncFunction("toggleCamera") { [weak self] () -> Bool in
            guard let self = self else { return false }
            return self.videoCallOperator?.toggleCamera() ?? false
        }
        
        AsyncFunction("switchCamera") { [weak self] () -> Bool in
            guard let self = self else { return false }
            return self.videoCallOperator?.switchCamera() ?? false
        }
        
        AsyncFunction("toggleMicrophone") { [weak self] () -> Bool in
            guard let self = self else { return false }
            return self.videoCallOperator?.toggleMicrophone() ?? false
        }
        
        AsyncFunction("dismissVideoCall") { [weak self] () in
            guard let self = self else { return }
            
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async(execute: {
                    if let viewController = self.videoCallViewController as? VCCameraController {
                        viewController.dismissController()
                        self.videoCallViewController = nil
                        self.videoCallOperator = nil
                    }
                    continuation.resume()
                })
            }
        }
    }
    
    private func setupLocalizationBundle() {
        setupCustomLocalizationBundle()
    }
    
    private func setupCustomLocalizationBundle() {
        let libraryBundle = Bundle(for: ExpoVideoCallModule.self)
        
        var resourceBundle: Bundle?
        
        if let resourceBundlePath = libraryBundle.path(forResource: "VideoCallLibraryResources", ofType: "bundle") {
            resourceBundle = Bundle(path: resourceBundlePath)
        }
        
        if resourceBundle == nil {
            if let mainBundlePath = Bundle.main.path(forResource: "VideoCallLibraryResources", ofType: "bundle") {
                resourceBundle = Bundle(path: mainBundlePath)
            }
        }
        
        if resourceBundle == nil {
            if libraryBundle.path(forResource: "Localizable", ofType: "strings") != nil {
                resourceBundle = libraryBundle
            }
        }
        
        if resourceBundle == nil {
            if Bundle.main.path(forResource: "Localizable", ofType: "strings") != nil {
                resourceBundle = Bundle.main
            }
        }
        
        if let bundle = resourceBundle {
            setVideoCallLocalizationBundle(bundle)
        } else {
            NSLog("ExpoVideoCallModule - Warning: Could not find localization bundle")
        }
    }
    
    private func setVideoCallLocalizationBundle(_ bundle: Bundle) {
        VideoCallBundleHelper.setupLocalizationBundle(bundle)
        
        LocalizationConfiguration.bundle = bundle
        
        if let tableName = uiConfiguration?["tableName"] as? String {
            LocalizationConfiguration.tableName = tableName
        } else {
            LocalizationConfiguration.tableName = nil
        }
    }
}

class VideoCallOperatorImpl: VCCameraControllerDelegate {
    private let serverURL: String
    private let wssURL: String
    private let userID: String
    private let transactionID: String
    private let clientName: String
    private let idleTimeout: String
    private let eventSender: (String, [String: Any]?) -> Void
    
    private var currentStatus = "idle"
    
    private var backgroundColor: String?
    private var textColor: String?
    private var pipViewBorderColor: String?
    private var notificationLabelDefault: String?
    private var notificationLabelCountdown: String?
    private var notificationLabelTokenFetch: String?
    
    init(serverURL: String, wssURL: String, userID: String, transactionID: String,
         clientName: String, idleTimeout: String, eventSender: @escaping (String, [String: Any]?) -> Void) {
        self.serverURL = serverURL
        self.wssURL = wssURL
        self.userID = userID
        self.transactionID = transactionID
        self.clientName = clientName
        self.idleTimeout = idleTimeout
        self.eventSender = eventSender
    }
    
    func getStatus() -> String {
        return currentStatus
    }
    
    func setConfig(backgroundColor: String?, textColor: String?, pipViewBorderColor: String?,
                   notificationLabelDefault: String?, notificationLabelCountdown: String?,
                   notificationLabelTokenFetch: String?) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.pipViewBorderColor = pipViewBorderColor
        self.notificationLabelDefault = notificationLabelDefault
        self.notificationLabelCountdown = notificationLabelCountdown
        self.notificationLabelTokenFetch = notificationLabelTokenFetch
    }
    
    func toggleCamera() -> Bool {
        return true
    }
    
    func switchCamera() -> Bool {
        return true
    }
    
    func toggleMicrophone() -> Bool {
        return true
    }
    
    public func cameraController(_ controller: VCCameraController, didChangeUserState state: UserState) {
        let stateString: String
        switch state {
        case .initiating:
            stateString = "initiating"
        case .tokenFetching:
            stateString = "tokenFetching"
        case .tokenFetched:
            stateString = "tokenFetched"
        case .connecting:
            stateString = "connecting"
        case .connected:
            stateString = "connected"
        case .disconnected:
            stateString = "disconnected"
        case .reconnecting:
            stateString = "reconnecting"
        @unknown default:
            stateString = "unknown"
        }
        
        currentStatus = stateString
        NSLog("VideoCallOperatorImpl - User state changed: \(stateString)")
        eventSender("VideoCall_onUserStateChanged", ["state": stateString])
    }
    
    public func cameraController(_ controller: VCCameraController, participantType: ParticipantType, didChangeState state: ParticipantState) {
        let participantTypeString = participantType == .agent ? "agent" : "supervisor"
        let stateString: String
        
        switch state {
        case .connected:
            stateString = "connected"
        case .videoTrackActivated:
            stateString = "videoTrackActivated"
        case .videoTrackPaused:
            stateString = "videoTrackPaused"
        case .disconnected:
            stateString = "disconnected"
        @unknown default:
            stateString = "unknown"
        }
        
        NSLog("VideoCallOperatorImpl - Participant \(participantTypeString) state changed: \(stateString)")
        eventSender("VideoCall_onParticipantStateChanged", [
            "participantType": participantTypeString,
            "state": stateString
        ])
    }
    
    public func cameraController(_ controller: VCCameraController, didFailWithError error: Error) {
        currentStatus = "error"
        NSLog("VideoCallOperatorImpl - Error occurred: \(error.localizedDescription)")
        eventSender("VideoCall_onError", [
            "type": "ERR_SDK",
            "message": error.localizedDescription
        ])
    }
    
    public func cameraControllerDidDismiss(_ controller: VCCameraController) {
        currentStatus = "dismissed"
        NSLog("VideoCallOperatorImpl - Camera controller dismissed")
        eventSender("VideoCall_onVideoCallDismissed", nil)
    }
    
    public func cameraControllerDidEndSessionSuccessfully(_ controller: VCCameraController) {
        currentStatus = "ended"
        NSLog("VideoCallOperatorImpl - Session ended successfully")
        eventSender("VideoCall_onVideoCallEnded", ["success": true])
    }
}

