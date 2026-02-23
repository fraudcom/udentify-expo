//
//  LivenessBundleHelper.swift
//  LivenessLibrary
//
//  Created for Udentify SDK localization
//

import Foundation
import ObjectiveC

@objc
class LivenessBundleHelper: NSObject {
  static var localizationBundle: Bundle?
  
  @objc static func setupLocalizationBundle(_ bundle: Bundle) {
    localizationBundle = bundle
    print("LivenessBundleHelper - Localization bundle set: \(bundle.bundlePath)")
    
    // Test localization
    testLocalization()
  }
  
  private static func testLocalization() {
    if let bundle = localizationBundle {
      let testKey = "udentifyface_header_text"
      let localizedString = bundle.localizedString(forKey: testKey, value: nil, table: nil)
      print("LivenessBundleHelper - Test localization for '\(testKey)': '\(localizedString)'")
      
      if localizedString == testKey {
        print("LivenessBundleHelper - WARNING: Localization not working, key returned as-is")
      } else {
        print("LivenessBundleHelper - SUCCESS: Localization working")
      }
    }
  }
  
  @objc static func localizedString(forKey key: String, value: String?, table: String?) -> String {
    if let bundle = localizationBundle {
      let result = bundle.localizedString(forKey: key, value: value, table: table)
      if result != key {
        return result
      }
    }
    
    // Fallback to main bundle
    return Bundle.main.localizedString(forKey: key, value: value, table: table)
  }
}

