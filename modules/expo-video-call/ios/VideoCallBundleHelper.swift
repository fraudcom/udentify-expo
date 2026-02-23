import Foundation
import UIKit

class VideoCallBundleHelper: NSObject {
    static var localizationBundle: Bundle?
    
    static func setupLocalizationBundle(_ bundle: Bundle) {
        localizationBundle = bundle
        testLocalization()
    }
    
    private static func testLocalization() {
        if let bundle = localizationBundle {
            let testKey = "udentify_vc_notification_label_default"
            let localizedString = bundle.localizedString(forKey: testKey, value: nil, table: nil)
            if localizedString == testKey {
                NSLog("VideoCallBundleHelper - Warning: Localization not working properly")
            }
        }
    }
    
    static func localizedString(forKey key: String, value: String?, table: String?) -> String {
        if let bundle = localizationBundle {
            let result = bundle.localizedString(forKey: key, value: value, table: table)
            if result != key {
                return result
            }
        }
        
        return Bundle.main.localizedString(forKey: key, value: value ?? key, table: table)
    }
}

