//
//  CustomLivenessSettings.swift
//  LivenessLibrary
//
//  Created for custom bundle configuration and UI customization
//

import Foundation
import UdentifyFACE
import UdentifyCommons

class CustomLivenessSettings: NSObject, ApiSettings {
  private let localizationBundle: Bundle
  private let uiConfig: [String: Any]?
  
  init(localizationBundle: Bundle, uiConfig: [String: Any]? = nil) {
    self.localizationBundle = localizationBundle
    self.uiConfig = uiConfig
    super.init()
  }
  
  var colors: ApiColors {
    return ApiColors()
  }
  
  var fonts: ApiFonts {
    return ApiFonts()
  }
  
  var configs: ApiConfigs {
    return ApiConfigs(
      cameraPosition: .front,
      requestTimeout: 15,
      autoTake: true,
      errorDelay: 0.25,
      successDelay: 0.75,
      bundle: localizationBundle,
      tableName: uiConfig?["tableName"] as? String,
      maskDetection: false,
      maskConfidence: 0.95,
      invertedAnimation: false,
      backButtonEnabled: true,
      multipleFacesRejected: true,
      buttonHeight: 48,
      buttonMarginLeft: 20,
      buttonMarginRight: 20,
      buttonCornerRadius: 8,
      progressBarStyle: UdentifyProgressBarStyle(
        backgroundColor: .lightGray.withAlphaComponent(0.5),
        progressColor: .gray,
        completionColor: .green,
        textStyle: UdentifyTextStyle(
          font: .boldSystemFont(ofSize: 19),
          textColor: .white,
          textAlignment: .center
        ),
        cornerRadius: 8
      )
    )
  }
}

