Pod::Spec.new do |s|
  s.name           = 'ExpoOCR'
  s.version        = '1.0.0'
  s.summary        = 'Expo OCR module with UdentifyOCR framework'
  s.description    = 'Expo module that integrates UdentifyOCR framework for document scanning'
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
    'OCRLibraryResources' => ['Localizable.strings']
  }
  
  s.dependency 'ExpoModulesCore'
  s.dependency 'UdentifyCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "*.{h,m,mm,swift,hpp,cpp}"
  
  # Include only the UdentifyOCR.xcframework - UdentifyCommons comes from UdentifyCore
  s.vendored_frameworks = ['UdentifyOCR.xcframework']
end

