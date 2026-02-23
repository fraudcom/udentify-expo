Pod::Spec.new do |s|
  s.name           = 'ExpoMRZ'
  s.version        = '1.0.0'
  s.summary        = 'Expo MRZ module with UdentifyMRZ framework'
  s.description    = 'Expo module that integrates UdentifyMRZ framework for MRZ scanning'
  s.author         = ''
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.source         = { git: '' }
  s.static_framework = true
  
  s.resource_bundles = {
    'MRZLibraryResources' => ['Resources/**/*']
  }
  
  s.dependency 'ExpoModulesCore'
  s.dependency 'UdentifyCore'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS' => '-ObjC -lc++',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }

  s.source_files = "*.{h,m,mm,swift,hpp,cpp}"
  
  s.vendored_frameworks = [
    'Frameworks/UdentifyMRZ.xcframework',
    'Frameworks/GPUImage.xcframework',
    'Frameworks/TesseractOCRSDKiOS.xcframework'
  ]
  
  s.exclude_files = [
    'Frameworks/TesseractOCRSDKiOS.xcframework/**/PrivateHeaders/**',
    'Frameworks/TesseractOCRSDKiOS.xcframework/**/*{.hpp,.cpp,.cc,.cxx}'
  ]
  
  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => [
      '"$(PODS_ROOT)/ExpoMRZ/Frameworks"',
      '"$(BUILT_PRODUCTS_DIR)/ExpoMRZ"',
      '"$(PODS_TARGET_SRCROOT)/Frameworks"'
    ].join(' '),
    'USER_HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/ExpoMRZ"',
    'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/ExpoMRZ"',
    'VALID_ARCHS' => 'arm64 x86_64'
  }
end

