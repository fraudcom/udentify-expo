Pod::Spec.new do |s|
  s.name           = 'ExpoNFC'
  s.version        = '1.0.0'
  s.summary        = 'Expo NFC module with UdentifyNFC framework'
  s.description    = 'Expo module that integrates UdentifyNFC framework for NFC passport reading'
  s.author         = ''
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.source         = { git: '' }
  s.static_framework = true
  
  # Resource bundle configuration (matching React Native approach)
  s.resource_bundles = {
    'NFCLibraryResources' => ['Resources/**/*']
  }
  
  s.dependency 'ExpoModulesCore'
  s.dependency 'UdentifyCore'
  
  # Add CoreNFC system framework
  s.weak_frameworks = 'CoreNFC'
  
  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "*.{h,m,mm,swift,hpp,cpp}"
  
  # Include the UdentifyNFC.xcframework and UdentifyCommons.xcframework
  s.vendored_frameworks = ['UdentifyNFC.xcframework']
end
