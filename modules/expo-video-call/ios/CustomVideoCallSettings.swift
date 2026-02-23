import Foundation
import UIKit
import UdentifyCommons

class CustomVideoCallSettings: NSObject {
    private let localizationBundle: Bundle
    private let uiConfig: [String: Any]?
    
    init(localizationBundle: Bundle, uiConfig: [String: Any]? = nil) {
        self.localizationBundle = localizationBundle
        self.uiConfig = uiConfig
        super.init()
    }
    
    func createVCSettings() -> VCSettings {
        func colorFromHex(_ hex: String?) -> UIColor? {
            guard let hex = hex, hex.hasPrefix("#"), hex.count == 7 else { return nil }
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                let b = CGFloat(hexNumber & 0x0000ff) / 255
                return UIColor(red: r, green: g, blue: b, alpha: 1.0)
            }
            return nil
        }
        
        let backgroundColor = colorFromHex(uiConfig?["backgroundColor"] as? String) ?? .black
        let textColor = colorFromHex(uiConfig?["textColor"] as? String) ?? .white
        let pipBorderColor = colorFromHex(uiConfig?["pipViewBorderColor"] as? String) ?? .white
        
        let settings = VCSettings(
            bundle: localizationBundle,
            tableName: getTableName(),
            backgroundColor: backgroundColor,
            backgroundStyle: nil,
            overlayImageStyle: nil,
            muteButtonStyle: VCMuteButtonStyle(),
            cameraSwitchButtonStyle: VCCameraSwitchButtonStyle(),
            pipViewStyle: UdentifyViewStyle(
                backgroundColor: .clear,
                borderColor: pipBorderColor,
                cornerRadius: 10,
                borderWidth: 2,
                horizontalSizing: .fixed(width: 120, horizontalPosition: .right(offset: 16)),
                verticalSizing: .fixed(height: 135, verticalPosition: .bottom(offset: 0))
            ),
            instructionLabelStyle: UdentifyTextStyle(
                font: UIFont.systemFont(ofSize: 20, weight: .medium),
                textColor: textColor,
                numberOfLines: 0,
                leading: 35,
                trailing: 35
            ),
            requestTimeout: getRequestTimeout()
        )
        
        return settings
    }
    
    func localizedString(forKey key: String, value: String? = nil, table: String? = nil) -> String {
        let result = localizationBundle.localizedString(forKey: key, value: value, table: table)
        if result != key {
            return result
        }
        
        return Bundle.main.localizedString(forKey: key, value: value, table: table)
    }
    
    func getTableName() -> String? {
        return uiConfig?["tableName"] as? String
    }
    
    func getRequestTimeout() -> Double {
        return uiConfig?["requestTimeout"] as? Double ?? 30.0
    }
}

