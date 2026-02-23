import ExpoModulesCore
import Foundation
import UdentifyCommons
import UdentifyNFC

public class ExpoNFCModule: ExpoModulesCore.Module {

  // Singleton instance of NFCManager
  private static var sharedNFCManager: NFCManagerSwift?
  
  private static func getSharedNFCManager() -> NFCManagerSwift {
    if sharedNFCManager == nil {
      sharedNFCManager = NFCManagerSwift()
    }
    return sharedNFCManager!
  }
  
  public func definition() -> ModuleDefinition {
    Name("ExpoNFC")
    
    // Events (could be used for progress updates if needed)
    Events("onNFCComplete", "onNFCError", "onNFCProgress")
    
    // Module lifecycle
    OnCreate {
      // Setup if needed
    }
    
    OnDestroy {
      // Cleanup if needed
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
        "frameworkName": "UdentifyNFC",
        "version": "Successfully imported",
        "status": "Framework loaded successfully"
      ]
    }
    
    // NFC Status Methods
    AsyncFunction("isNFCAvailable") { () -> Bool in
      return await withCheckedContinuation { continuation in
        let nfcManager = ExpoNFCModule.getSharedNFCManager()
        nfcManager.isNFCAvailable { available, error in
          continuation.resume(returning: available)
        }
      }
    }
    
    AsyncFunction("isNFCEnabled") { () -> Bool in
      return await withCheckedContinuation { continuation in
        let nfcManager = ExpoNFCModule.getSharedNFCManager()
        nfcManager.isNFCEnabled { enabled, error in
          continuation.resume(returning: enabled)
        }
      }
    }
    
    AsyncFunction("getNFCStatus") { () -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let nfcManager = ExpoNFCModule.getSharedNFCManager()
        
        nfcManager.isNFCAvailable { available, availableError in
          nfcManager.isNFCEnabled { enabled, enabledError in
            let result: [String: Any] = [
              "isAvailable": available,
              "isEnabled": enabled,
              "message": available 
                ? (enabled ? "NFC is available and enabled" : "NFC is available but disabled")
                : "NFC is not available on this device"
            ]
            continuation.resume(returning: result)
          }
        }
      }
    }
    
    // NFC Reading Methods
    AsyncFunction("startNFCReading") { (credentials: [String: Any]) -> [String: Any] in
      print("ExpoNFCModule - startNFCReading called with credentials: \(credentials)")
      return await withCheckedContinuation { continuation in
        print("ExpoNFCModule - About to call NFCManager startNFCReading")
        let nfcManager = ExpoNFCModule.getSharedNFCManager()
        nfcManager.startNFCReading(credentials: credentials) { result, error in
          print("ExpoNFCModule - NFCManager callback received - result: \(result != nil), error: \(error != nil)")
          if let error = error {
            print("ExpoNFCModule - Resuming continuation with error: \(error.localizedDescription)")
            continuation.resume(returning: [
              "success": false,
              "error": error.localizedDescription,
              "message": error.localizedDescription
            ])
          } else if let result = result {
            print("ExpoNFCModule - Resuming continuation with result: \(result)")
            continuation.resume(returning: result)
          } else {
            print("ExpoNFCModule - Resuming continuation with unknown error")
            continuation.resume(returning: [
              "success": false,
              "error": "Unknown error occurred",
              "message": "NFC reading failed with unknown error"
            ])
          }
        }
        print("ExpoNFCModule - startNFCReading call completed, waiting for callback")
      }
    }
    
    AsyncFunction("cancelNFCReading") { () -> Bool in
      return await withCheckedContinuation { continuation in
        let nfcManager = ExpoNFCModule.getSharedNFCManager()
        nfcManager.cancelNFCReading { success, error in
          continuation.resume(returning: success)
        }
      }
    }
    
    // NFC Location Methods
    AsyncFunction("getNFCLocation") { (serverURL: String) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let nfcManager = ExpoNFCModule.getSharedNFCManager()
        nfcManager.getNFCLocation(serverURL: serverURL) { result, error in
          if let error = error {
            continuation.resume(returning: [
              "success": false,
              "error": error.localizedDescription,
              "message": error.localizedDescription
            ])
          } else {
            continuation.resume(returning: result ?? [
              "success": false,
              "error": "Unknown error occurred",
              "message": "NFC location detection failed with unknown error"
            ])
          }
        }
      }
    }
  }
}