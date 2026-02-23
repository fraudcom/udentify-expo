Pod::Spec.new do |s|
  s.name           = 'ExpoVideoCall'
  s.version        = '1.0.0'
  s.summary        = 'Expo Video Call module with UdentifyVC framework'
  s.description    = 'Expo module that integrates UdentifyVC framework for video call functionality'
  s.author         = 'Fraud.com'
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.source         = { git: '' }
  s.static_framework = true
  s.swift_version  = '5.0'
  
  s.resource_bundles = {
    'VideoCallLibraryResources' => ['Localizable.strings']
  }
  
  s.resources = [
    'Resources/**/*'
  ]
  
  s.exclude_files = [
    'Resources/PrivacyInfo.xcprivacy'
  ]
  
  s.dependency 'ExpoModulesCore'
  s.dependency 'UdentifyCore'
  s.dependency 'LiveKitClient', '~> 2.3.0'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Frameworks/UdentifyVC/**',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }

  s.source_files = "*.{h,m,mm,swift,hpp,cpp}", "Frameworks/UdentifyVC/**/*.swift"
  
  s.preserve_paths = 'Frameworks/UdentifyVC/**/*'
end

