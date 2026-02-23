Pod::Spec.new do |s|
  s.name           = 'UdentifyCore'
  s.version        = '1.0.0'
  s.summary        = 'Core shared components for Udentify Expo modules'
  s.description    = 'Shared UdentifyCommons framework used across all Udentify Expo modules'
  s.author         = 'Udentify'
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.source         = { git: '' }
  s.static_framework = true
  
  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "*.{h,m,mm,swift,hpp,cpp}"
  
  # Include the shared UdentifyCommons.xcframework
  s.vendored_frameworks = ['Frameworks/UdentifyCommons.xcframework']
  
  # Framework search paths
  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/UdentifyCore/Frameworks"',
    'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/UdentifyCore/Frameworks/UdentifyCommons.xcframework/ios-arm64/UdentifyCommons.framework/Headers"',
    'SWIFT_INCLUDE_PATHS' => '"$(PODS_ROOT)/UdentifyCore/Frameworks/UdentifyCommons.xcframework/ios-arm64/UdentifyCommons.framework/Modules"'
  }
end
