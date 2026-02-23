import ExpoModulesCore
import Foundation
import UdentifyCommons
import UdentifyMRZ

public class ExpoMRZModule: ExpoModulesCore.Module {
  
  private static var sharedMRZManager: MRZManager?
  
  private static func getSharedMRZManager() -> MRZManager {
    if sharedMRZManager == nil {
      sharedMRZManager = MRZManager()
    }
    return sharedMRZManager!
  }
  
  public func definition() -> ModuleDefinition {
    Name("ExpoMRZ")
    
    Events("onMrzProgress")
    
    OnCreate {
      MRZBundleHelper.setupResourceBundle()
    }
    
    OnDestroy {
      NotificationCenter.default.removeObserver(self)
    }
    
    AsyncFunction("checkPermissions") { () -> Bool in
      return await withCheckedContinuation { continuation in
        let mrzManager = ExpoMRZModule.getSharedMRZManager()
        mrzManager.checkPermissions { hasPermission in
          continuation.resume(returning: hasPermission)
        }
      }
    }
    
    AsyncFunction("requestPermissions") { () -> String in
      return await withCheckedContinuation { continuation in
        let mrzManager = ExpoMRZModule.getSharedMRZManager()
        mrzManager.requestPermissions { status in
          continuation.resume(returning: status)
        }
      }
    }
    
    AsyncFunction("startMrzCamera") { (customization: [String: Any]?) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let mrzManager = ExpoMRZModule.getSharedMRZManager()
        mrzManager.startMrzCamera(customization as NSDictionary?) { result in
          continuation.resume(returning: result as? [String: Any] ?? [:])
        }
      }
    }
    
    AsyncFunction("processMrzImage") { (imageBase64: String) -> [String: Any] in
      return await withCheckedContinuation { continuation in
        let mrzManager = ExpoMRZModule.getSharedMRZManager()
        mrzManager.processMrzImage(imageBase64) { result in
          continuation.resume(returning: result as? [String: Any] ?? [:])
        }
      }
    }
    
    AsyncFunction("cancelMrzScanning") { () -> Bool in
      return await withCheckedContinuation { continuation in
        let mrzManager = ExpoMRZModule.getSharedMRZManager()
        mrzManager.cancelMrzScanning {
          continuation.resume(returning: true)
        }
      }
    }
  }
}

