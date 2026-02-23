Pod::Spec.new do |s|
  s.name           = 'ExpoLiveness'
  s.version        = '1.0.0'
  s.summary        = 'Expo Liveness module with UdentifyFACE framework'
  s.description    = 'Expo module that integrates UdentifyFACE framework for face liveness detection and recognition'
  s.author         = 'Fraud.com'
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.source         = { git: '' }
  s.static_framework = true
  # Resource bundle configuration (matching React Native approach)
  s.resource_bundles = {
    'LivenessResources' => ['Localizable.strings']
  }
  
  s.dependency 'ExpoModulesCore'
  s.dependency 'UdentifyCore'
  
  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "*.{h,m,mm,swift,hpp,cpp}"
  
  s.vendored_frameworks = ['UdentifyFACE.xcframework', 'Lottie.xcframework']
end

