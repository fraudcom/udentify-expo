import Foundation
import ObjectiveC

@objc
class MRZBundleHelper: NSObject {
  static var resourceBundle: Bundle?
  
  @objc static func setupResourceBundle() {
    if let bundle = findResourceBundle() {
      resourceBundle = bundle
      print("MRZBundleHelper - Resource bundle set: \(bundle.bundlePath)")
      testLocalization()
    } else {
      print("MRZBundleHelper - WARNING: Could not find MRZ resource bundle, using main bundle as fallback")
      resourceBundle = Bundle.main
    }
  }
  
  private static func findResourceBundle() -> Bundle? {
    let mainBundle = Bundle.main
    let podBundle = Bundle(for: MRZBundleHelper.self)
    
    let candidateBundles = [
      Bundle(for: MRZBundleHelper.self),
      mainBundle
    ]
    
    for candidateBundle in candidateBundles {
      if let bundlePath = candidateBundle.path(forResource: "MRZLibraryResources", ofType: "bundle"),
         let bundle = Bundle(path: bundlePath) {
        return bundle
      }
      
      if let bundlePath = candidateBundle.path(forResource: "expo-mrz", ofType: "bundle"),
         let bundle = Bundle(path: bundlePath) {
        return bundle
      }
      
      if candidateBundle.path(forResource: "Localizable", ofType: "strings") != nil {
        return candidateBundle
      }
    }
    
    return podBundle
  }
  
  private static func testLocalization() {
    if let bundle = resourceBundle {
      let testKey = "mrz_scan_instruction"
      let localizedString = bundle.localizedString(forKey: testKey, value: nil, table: nil)
      
      if localizedString == testKey {
        print("MRZBundleHelper - WARNING: Localization not working, key returned as-is")
      } else {
        print("MRZBundleHelper - SUCCESS: Localization working - '\(testKey)' = '\(localizedString)'")
      }
    }
  }
  
  @objc static func localizedString(forKey key: String, value: String?, table: String?) -> String {
    if let bundle = resourceBundle {
      let result = bundle.localizedString(forKey: key, value: value, table: table)
      if result != key {
        return result
      }
    }
    
    return value ?? key
  }
}

